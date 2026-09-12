extends RefCounted
class_name Welt_WasserAutomat
## Wasser-Automat mit Dirty-Queue: Simuliert Wasserfluss pro Tick.
## Läuft bei Kern_Weltuhr.tick alle 3 Ticks.
## Jedes Wasser-Tile prüft 4 horizontale Nachbarn + Tile direkt darunter auf Z-1.
## Wenn Ziel leer: Wasser bewegt sich dort hin, neues Wasser-Tile zur Dirty-Queue.
## Cross-Z Trigger: Wenn Job_Graben Decke entfernt (Signal decken_entfernt),
## fügt Wasser-Automat Wasser-Tiles direkt über dem Loch zur Dirty-Queue hinzu.
## DIES IST DER EINZIGE Cross-Z Trigger — alles andere bleibt pro Ebene isoliert.

const TILE_WASSER := "wasser"
const TILE_UFER := "ufer"
const TICK_INTERVALL := 3  # Alle 3 Ticks

var _model: Welt_Model = null
var _registry: Welt_Registry = null
var _dirty_queue: Array[Dictionary] = []  # Einträge: {"x": int, "y": int, "z": int}
var _verarbeitete_ticks: int = 0
var _signal_verbunden: bool = false
var _weltuhr_verbunden: bool = false

func einrichten(model: Welt_Model, registry: Welt_Registry) -> void:
	_model = model
	_registry = registry
	_dirty_queue.clear()
	_verarbeitete_ticks = 0
	_signal_verbunden = false
	_weltuhr_verbunden = false
	# Initiale Wasser-Tiles zur Queue hinzufügen
	_initiale_wasser_sammeln()
	# Signal für Decke-entfernt verbinden
	_signal_verbinden()
	# An Weltuhr-Tick anschließen
	_weltuhr_anschliessen()

func _weltuhr_anschliessen() -> void:
	var weltuhr := Kern_Weltuhr.bus()
	if weltuhr != null and not _weltuhr_verbunden:
		weltenuhr.tick.connect(_auf_weltuhr_tick)
		_weltuhr_verbunden = true

func _auf_weltuhr_tick(_tick_nummer: int, _delta: float) -> void:
	tick(_delta)

func _signal_verbinden() -> void:
	var bus := Kern_SignalBus.bus()
	if bus != null and not _signal_verbunden:
		bus.decken_entfernt.connect(_auf_decke_entfernt)
		_signal_verbunden = true

func _initiale_wasser_sammeln() -> void:
	if _model == null:
		return
	for z in range(Welt_Model.MAX_Z_EBENEN):
		var z_ebene := -z
		for y in _model.raster_hoehe:
			for x in _model.raster_breite:
				if _model.fliese(x, y, z_ebene) == TILE_WASSER:
					_dirty_queue.append({"x": x, "y": y, "z": z_ebene})

func _auf_decke_entfernt(position: Vector2, z_ebene: int) -> void:
	# Job_Graben hat Fels-Tile auf z_ebene entfernt -> Prüfe Tile darüber (z_ebene + 1)
	var z_oben := z_ebene + 1
	if z_oben > 0:
		return  # Über Oberfläche gibt es keine Ebene
	var kachel_groesse := _model.kachel_groesse
	var x := int(position.x / kachel_groesse)
	var y := int(position.y / kachel_groesse)
	if _model.ist_in_raster(x, y, z_oben):
		var tile_oben := _model.fliese(x, y, z_oben)
		if tile_oben == TILE_WASSER:
			# Wasser über dem Loch zur Dirty-Queue hinzufügen
			_dirty_queue.append({"x": x, "y": y, "z": z_oben})

func tick(delta: float) -> void:
	_verarbeitete_ticks += 1
	if _verarbeitete_ticks % TICK_INTERVALL != 0:
		return
	_wasser_schritt()

func _wasser_schritt() -> void:
	if _model == null or _dirty_queue.is_empty():
		return
	
	var neue_queue: Array[Dictionary] = []
	var verarbeitet: Dictionary = {}  # Key "x:y:z" -> bool, um Doppelverarbeitung zu vermeiden
	
	while not _dirty_queue.is_empty():
		var eintrag := _dirty_queue.pop_front()
		var x := eintrag["x"]
		var y := eintrag["y"]
		var z := eintrag["z"]
		var key := "%d:%d:%d" % [x, y, z]
		
		if verarbeitet.has(key):
			continue
		verarbeitet[key] = true
		
		# Prüfen ob Tile noch Wasser ist (könnte sich geändert haben)
		if _model.fliese(x, y, z) != TILE_WASSER:
			continue
		
		# 4 horizontale Nachbarn prüfen
		var richtungen := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for richtung in richtungen:
			var nx := x + richtung.x
			var ny := y + richtung.y
			if _model.ist_in_raster(nx, ny, z):
				var ziel_tile := _model.fliese(nx, ny, z)
				if ziel_tile == "boden" or ziel_tile == "wiese" or ziel_tile == "sand" or ziel_tile == "geroell":
					# Leeres/begehbares Tile -> Wasser fließt hin
					_model.fliese_setzen(nx, ny, TILE_WASSER, z)
					# Altes Tile wird zu Ufer (oder bleibt Wasser bei Quelle)
					# Einfache Regel: Quelle bleibt Wasser, Ziel wird Wasser
					neue_queue.append({"x": nx, "y": ny, "z": z})
					# Ufer um neue Wasser-Kachel bilden
					_ufersaeume_bilden_fuer(nx, ny, z)
		
		# Tile direkt UNTERHALB auf Z-1 prüfen (Cross-Z nur nach unten)
		var z_unten := z - 1
		if z_unten >= -Welt_Model.MAX_Z_EBENEN + 1:
			if _model.ist_in_raster(x, y, z_unten):
				var ziel_tile_unten := _model.fliese(x, y, z_unten)
				if ziel_tile_unten == "boden" or ziel_tile_unten == "wiese" or ziel_tile_unten == "sand" or ziel_tile_unten == "geroell" or ziel_tile_unten == "":
					# Wasser fließt in die Tiefe
					_model.fliese_setzen(x, y, TILE_WASSER, z_unten)
					neue_queue.append({"x": x, "y": y, "z": z_unten})
					_ufersaeume_bilden_fuer(x, y, z_unten)
	
	# Neue Einträge zur Queue hinzufügen
	for e in neue_queue:
		_dirty_queue.append(e)

func _ufersaeume_bilden_fuer(x: int, y: int, z: int) -> void:
	# Bildet Ufer um das Wasser-Tile bei (x,y,z)
	var richtungen := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					   Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	for richtung in richtungen:
		var nx := x + richtung.x
		var ny := y + richtung.y
		if _model.ist_in_raster(nx, ny, z):
			var nachbar := _model.fliese(nx, ny, z)
			if nachbar != TILE_WASSER and nachbar != TILE_UFER and nachbar != "":
				# Land-Tile wird zu Ufer
				_model.fliese_setzen(nx, ny, TILE_UFER, z)