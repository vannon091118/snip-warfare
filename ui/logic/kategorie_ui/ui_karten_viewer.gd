extends Control
class_name Ui_KartenViewer
## UI-Karte: eigener Viewer über den autoritativen Weltzustand.
## Sie erzeugt keine Welt, keinen Zufall, keine zweite Objektliste: Sie liest
## das Welt_Model und die Registries und malt daraus eine Übersicht.
## Weltansicht = Detail, diese Karte = Übersicht. Beide teilen dieselbe Wahrheit.

## Kategorie daten: Quellen und Anzeige-Zustand.
const KEIN_ZEIGER := Vector2(-1, -1)

var _model: Welt_Model = null
var _registry: Welt_Registry = null
var _biome: Welt_BiomRegistry = null
var _spieler_position := Vector2.ZERO
var _kamera_position := Vector2.ZERO
var _kamera_groesse := Vector2.ZERO
var _fokus := KEIN_ZEIGER

## Kategorie logik: Quellen setzen und Übersicht zeichnen.

func einrichten(model: Welt_Model, registry: Welt_Registry, biome: Welt_BiomRegistry) -> void:
	_model = model
	_registry = registry
	_biome = biome
	queue_redraw()

func beobachten_setzen(spieler_position: Vector2, kamera_position: Vector2, kamera_groesse: Vector2) -> void:
	# Observer-Eingang: die Szene reicht Positionsstände durch, die Karte rechnet nichts.
	_spieler_position = spieler_position
	_kamera_position = kamera_position
	_kamera_groesse = kamera_groesse
	queue_redraw()

func fokus_auf_spieler() -> void:
	if _model == null:
		return
	var kanten: Vector2 = Vector2(_model.groesse()) * float(_model.kachel_groesse)
	if kanten.x <= 0.0 or kanten.y <= 0.0:
		return
	_fokus = Vector2(_spieler_position.x / kanten.x, _spieler_position.y / kanten.y)
	queue_redraw()

func fokus_zuruecksetzen() -> void:
	_fokus = KEIN_ZEIGER
	queue_redraw()

func _draw() -> void:
	if _model == null or _registry == null or _biome == null:
		return
	var kachel_px := _kachel_pixel()
	if kachel_px <= 0.0:
		return
	var kante := float(_model.kachel_groesse)
	_kacheln_malen(kachel_px)
	_regionen_malen(kachel_px, kante)
	_chunks_malen(kachel_px, kante)
	_objekte_malen(kachel_px, kante)
	_blickfeld_malen(kachel_px, kante)
	_spieler_malen(kachel_px, kante)

func _kachel_pixel() -> float:
	# Die Welt passt immer in den Viewer: Kantenlänge je Kachel aus der Control-Größe.
	var kanten: Vector2 = Vector2(_model.groesse())
	if kanten.x <= 0.0 or kanten.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return 0.0
	return minf(size.x / kanten.x, size.y / kanten.y)

func _kacheln_malen(kachel_px: float) -> void:
	for y in _model.raster_hoehe:
		for x in _model.raster_breite:
			var farbe := Color.WHITE
			var biom := _biome.biom_fuer(_model.biom_an_kachel(x, y))
			if biom != null:
				farbe = Color.from_string(biom.farbe, Color.WHITE).darkened(0.25)
			draw_rect(Rect2(Vector2(x, y) * kachel_px, Vector2(kachel_px, kachel_px)), farbe, true)

func _regionen_malen(kachel_px: float, _kante: int) -> void:
	# Region-Grenzen als dicke Linien: die Makrostruktur wird sichtbar.
	var kacheln: Vector2i = _model.groesse()
	var region_kante := maxi(_model.region_kante, 1)
	var farbe := Color(0.1, 0.1, 0.1, 0.8)
	for region_y in ceili(float(kacheln.y) / float(region_kante)) + 1:
		var py := region_y * region_kante * kachel_px
		draw_line(Vector2(0, py), Vector2(kacheln.x * kachel_px, py), farbe, 2.0)
	for region_x in ceili(float(kacheln.x) / float(region_kante)) + 1:
		var px := region_x * region_kante * kachel_px
		draw_line(Vector2(px, 0), Vector2(px, kacheln.y * kachel_px), farbe, 2.0)

func _chunks_malen(kachel_px: float, kante: int) -> void:
	# Chunk-Grenzen als dünne Linien: die technische Partition wird sichtbar.
	var kacheln: Vector2i = _model.groesse()
	var farbe := Color(0, 0, 0, 0.25)
	for chunk_y in ceili(float(kacheln.y) / float(kante)) + 1:
		var py := chunk_y * kante * kachel_px
		draw_line(Vector2(0, py), Vector2(kacheln.x * kachel_px, py), farbe, 1.0)
	for chunk_x in ceili(float(kacheln.x) / float(kante)) + 1:
		var px := chunk_x * kante * kachel_px
		draw_line(Vector2(px, 0), Vector2(px, kacheln.y * kachel_px), farbe, 1.0)

func _objekte_malen(kachel_px: float, kante: int) -> void:
	for index in _model.objekt_anzahl():
		var eintrag := _registry.finde_objekt(_model.objekt_element_id(index))
		if eintrag == null:
			continue
		var pos := _model.objekt_position(index)
		var farbe := Color(0.15, 0.1, 0.05)
		if eintrag.typ == &"bewegt":
			# Tiere erscheinen als kleine Kreise, damit sich Bewegtes von Statischem abhebt.
			draw_circle(pos / float(kante) * kachel_px, maxf(kachel_px * 0.4, 2.0), Color(0.8, 0.3, 0.2))
			continue
		if eintrag.kategorie == "Gebäude":
			farbe = Color(0.85, 0.75, 0.3)
		elif eintrag.kategorie == "Natur":
			farbe = Color(0.1, 0.35, 0.1)
		draw_rect(Rect2(pos / float(kante) * kachel_px - Vector2.ONE * kachel_px * 0.5, Vector2.ONE * kachel_px), farbe, true)

func _blickfeld_malen(kachel_px: float, kante: int) -> void:
	if _kamera_groesse.x <= 0.0:
		return
	var oben := (_kamera_position - _kamera_groesse * 0.5) / float(kante) * kachel_px
	var unten := (_kamera_position + _kamera_groesse * 0.5) / float(kante) * kachel_px
	draw_rect(Rect2(oben, unten - oben), Color(1, 1, 1, 0.15), false, 2.0)

func _spieler_malen(kachel_px: float, kante: int) -> void:
	var pos := _spieler_position / float(kante) * kachel_px
	draw_circle(pos, maxf(kachel_px * 0.5, 3.0), Color(0.2, 0.5, 1.0))
	draw_circle(pos, maxf(kachel_px * 0.25, 1.5), Color.WHITE)

func _gui_input(ereignis: InputEvent) -> void:
	# Klick in die Karte setzt den Fokuszeiger; Navigation bleibt Szene-Sache.
	if ereignis is InputEventMouseButton and ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		var kachel_px := _kachel_pixel()
		if kachel_px > 0.0 and _model != null:
			var _kanten: Vector2 = Vector2(_model.groesse()) * float(_model.kachel_groesse)
			_fokus = Vector2(ereignis.position.x / (kachel_px * _model.raster_breite), ereignis.position.y / (kachel_px * _model.raster_hoehe))
			_fokus = _fokus.clamp(Vector2.ZERO, Vector2.ONE)
			queue_redraw()
			accept_event()
