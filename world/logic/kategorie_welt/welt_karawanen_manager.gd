extends Node2D
class_name Welt_KarawanenManager
## Manager für Karawanen auf der Weltkarte: Erzeugt, tickt und zeichnet
## Karawanen als bewegte Punkte zwischen den Karten. Verbindet Lager über
## das Makro-Netzwerk (Welt_NetzwerkPlaner.wege). Handelsabwicklung läuft
## über direkte Mutationen auf dem Ziel-Modell (auch inaktiv). Die Reisedauer
## rechnet Welt_KarawanenReise, das Malen Welt_KarawanenZeichner und das
## Sichern Welt_KarawanenSpeicher; dieser Manager hält den Bestand und den
## Takt.

signal karawane_gestartet(karawane: Welt_Karawane)
signal karawane_angekommen(karawane: Welt_Karawane)
signal karawane_entladen(karawane: Welt_Karawane, erfolreich: bool)
signal handels_abgeschlossen(von_map_id: String, nach_map_id: String, ressourcen: Dictionary)

## Kategorie daten: Liste aller aktiven Karawanen.
var _karawanen: Array[Welt_Karawane] = []
var _naechste_karawanen_nummer: int = 1

## Kategorie logik: Verbindungen zu anderen Domänen.
var _welt_world: Welt_World = null
var _netzwerk_planer: Welt_NetzwerkPlaner = null
var _model: Welt_Model = null
var _reise := Welt_KarawanenReise.new()
var _zeichner := Welt_KarawanenZeichner.new()

## Sichtbarkeit: Karawanen als Punkte auf der Weltkarte.
var _karawanen_ebene: Node2D

func _ready() -> void:
	y_sort_enabled = true
	_karawanen_ebene = Node2D.new()
	_karawanen_ebene.name = "KarawanenEbene"
	_karawanen_ebene.y_sort_enabled = true
	add_child(_karawanen_ebene)
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func einrichten(welt_world: Welt_World, netzwerk_planer: Welt_NetzwerkPlaner, model: Welt_Model) -> void:
	_welt_world = welt_world
	_netzwerk_planer = netzwerk_planer
	_model = model

func modell_wechseln(neues_modell: Welt_Model) -> void:
	## Kartenwechsel-Handshake: Aktualisiert Modell-Referenz.
	_model = neues_modell

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	if not _darf_ticken():
		return
	var entfernte_indices: Array[int] = []
	for index in _karawanen.size():
		var karawane: Welt_Karawane = _karawanen[index]
		var entfernen := _karawane_ticken(karawane, index)
		if entfernen:
			entfernte_indices.append(index)
	# Entfernte Karawanen bereinigen (von hinten, damit die Indizes stimmen).
	entfernte_indices.sort_custom(func(a: int, b: int) -> bool: return a > b)
	for idx in entfernte_indices:
		_karawanen.remove_at(idx)
	_karawanen_ebene.queue_redraw()

func _darf_ticken() -> bool:
	## 1/6-Tick-Gate: Inaktive Karten ticken nur jedes sechste Frame.
	if _welt_world == null:
		return true
	var aktive_map_id := _welt_world.aktive_map_id()
	var eigene_map_id := _model.map_id if _model != null else ""
	if aktive_map_id != "" and aktive_map_id != eigene_map_id:
		return Engine.get_process_frames() % 6 == 0
	return true

func _karawane_ticken(karawane: Welt_Karawane, index: int) -> bool:
	## Gibt zurück, ob die Karawane aus dem Bestand entfernt gehört.
	if karawane == null:
		return true
	if not _ist_meine_karawane(karawane):
		return false
	if karawane.tick():
		_karawane_entladen(karawane, index)
		return false
	return karawane.ist_fertig()

func _ist_meine_karawane(karawane: Welt_Karawane) -> bool:
	if _model == null:
		return false
	return (karawane.von_map_id == _model.map_id) or (karawane.nach_map_id == _model.map_id)

func _karawane_entladen(karawane: Welt_Karawane, _index: int) -> void:
	## Lädt die Fracht in das Ziel-Lager ein (direkte Mutation über Welt_World,
	## funktioniert auch auf inaktiven Karten). Kein SubViewport, kein Threading.
	var erfolg := false
	if _welt_world != null:
		erfolg = _welt_world.karawane_ankunft_verarbeiten(karawane)
	karawane_angekommen.emit(karawane)
	if not erfolg:
		karawane_entladen.emit(karawane, false)
		return
	karawane.als_fertig_markieren()
	karawane_entladen.emit(karawane, true)
	handels_abgeschlossen.emit(karawane.von_map_id, karawane.nach_map_id, karawane.fracht())

func karawane_erstellen(von_map_id: String, nach_map_id: String, von_pos: Vector2, nach_pos: Vector2, fracht: Dictionary) -> Welt_Karawane:
	## Erstellt eine neue Karawane mit berechneter Reisedauer aus dem Netzwerk.
	var reise_ticks := _reise.dauer_ticks(_netzwerk_planer, von_map_id, nach_map_id, von_pos, nach_pos)
	var k_id := "karawane_%d" % _naechste_karawanen_nummer
	_naechste_karawanen_nummer += 1
	var karawane := Welt_Karawane.new(k_id, von_map_id, nach_map_id, von_pos, nach_pos, reise_ticks, fracht)
	_karawanen.append(karawane)
	karawane.reise_starten()
	karawane_gestartet.emit(karawane)
	return karawane

func karawanen_liste() -> Array[Welt_Karawane]:
	return _karawanen.duplicate()

func karawane_bei_index(index: int) -> Welt_Karawane:
	if index < 0 or index >= _karawanen.size():
		return null
	return _karawanen[index]

func _draw() -> void:
	## Zeichnet alle Karawanen als bewegte Punkte auf der Weltkarte.
	_zeichner.zeichnen(self, _karawanen, _model.map_id if _model != null else "")

func nach_woerterbuch() -> Dictionary:
	return Welt_KarawanenSpeicher.sichern(_karawanen, _naechste_karawanen_nummer)

func aus_woerterbuch(daten: Dictionary) -> void:
	_naechste_karawanen_nummer = Welt_KarawanenSpeicher.laden(daten, _karawanen, _naechste_karawanen_nummer)
