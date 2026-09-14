extends Node2D
class_name Gebaeude_Manager
## Manager der Gebäude: Er hält den Takt-Empfang, die Signale und die
## Verbindungen zu fremden Domänen. Die Prüfung des Bauplatzes wohnt im
## Gebaeude_BauplatzPruefer, die Buchung im Gebaeude_BauAuftrag, das
## Tick-Werk und die Zustandsübergänge in der Gebaeude_Laufzeit, die
## HUD-Zeilen im Gebaeude_StatusLeser und das Karten-Gate im
## Gebaeude_KartenGate. Der Manager entscheidet selbst nichts; er reicht
## nur durch und hält die Signale am Leben. Fremde Bestände berührt er nie
## direkt, das Modell beschreibt allein die Bauauftrags-Stelle.

signal gebaeude_meldung(text: String)
signal gebaeude_fertiggestellt(gebaeude_id: String)
## Renderer-Signal: Jeder neu platzierte Gebäude-Knoten wird sofort angehängt.
signal gebaeude_platziert(objekt_index: int)
## Statuszeilen für das HUD: gemeldet wird nur ein echter Wechsel, das HUD
## muss nicht mehr in jedem Frame nachfragen.
signal status_geaendert(zeilen: Array[String])

## Kategorie daten: Definitionen und die zwei Zustandsmaschinen.
var _definitionen := Gebaeude_DefinitionRegistry.new()
var _bau_maschine := Gebaeude_BauMaschine.new()
var _produktions_maschine := Gebaeude_ProduktionsMaschine.new()
## Die Helfer tragen je eine Verantwortung; der Manager nur die Komposition.
var _laufzeit := Gebaeude_Laufzeit.new()
var _bauplatz := Gebaeude_BauplatzPruefer.new()
var _bau_auftrag := Gebaeude_BauAuftrag.new()
var _status_leser := Gebaeude_StatusLeser.new()
var _karten_gate := Gebaeude_KartenGate.new()

## Kategorie logik: Verbindungen zu anderen Domänen und Tick.
var _model: Welt_Model = null
var _registry: Welt_Registry = null
var _ressourcen: Einheit_Ressourcen = null
var _lager: Lager_Manager = null
var _fortschritt: Welt_FortschrittsMaschine = null
## Parallel-Map: Referenz auf die Welt für das Karten-Gate.
var _welt_world: Welt_World = null
## Zuletzt gemeldete Statuszeilen: Vergleichsgrundlage gegen Doppelmeldungen.
var _letzte_statuszeilen: String = ""

func _ready() -> void:
	# Die Weltuhr wird zur Laufzeit aufgelöst statt über den Autoload-Globalnamen,
	# damit der Manager auch in Headless-Läufen ohne Autoloads kompilierbar bleibt.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)
	# Menü-Gegenprüfung: Ein geöffnetes Menü stößt die Abstimmung aller
	# Gebäude-Fortschritte an, damit Anzeige und Zeiten präzise bleiben.
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("menue_geoeffnet") and not bus.menue_geoeffnet.is_connected(_auf_menue_geoeffnet):
		bus.menue_geoeffnet.connect(_auf_menue_geoeffnet)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("menue_geoeffnet") and bus.menue_geoeffnet.is_connected(_auf_menue_geoeffnet):
		bus.menue_geoeffnet.disconnect(_auf_menue_geoeffnet)

func einrichten(model: Welt_Model, registry: Welt_Registry, ressourcen: Einheit_Ressourcen, lager: Lager_Manager, fortschritt: Welt_FortschrittsMaschine = null, welt_world: Welt_World = null) -> void:
	_model = model
	_registry = registry
	_ressourcen = ressourcen
	_lager = lager
	_fortschritt = fortschritt
	_welt_world = welt_world
	_bauplatz.einrichten(model, _definitionen, registry)
	_status_leser.einrichten(model, _definitionen, _bau_maschine, _produktions_maschine)
	_bau_auftrag.einrichten(model, ressourcen, lager, _definitionen, _bau_maschine, _produktions_maschine, fortschritt, _bauplatz, _meldung_text, _status_zeilen_melden)
	_laufzeit.einrichten(model, ressourcen, lager, _definitionen, _bau_maschine, _produktions_maschine, fortschritt, _meldung_text, _gebaeude_fertig_call)

func modell_wechseln(neues_modell: Welt_Model, welt_world: Welt_World = null) -> void:
	## Kartenwechsel-Handshake: Tauscht die Modell-Referenz atomar aus.
	## Der Tick-Empfang läuft ohne Unterbrechung weiter; neue Gebäude
	## werden auf der neuen Karte gesucht und getickt.
	_model = neues_modell
	_welt_world = welt_world
	_laufzeit.model_setzen(neues_modell)
	_bauplatz.model_setzen(neues_modell)
	_bau_auftrag.model_setzen(neues_modell)
	_status_leser.model_setzen(neues_modell)
	_letzte_statuszeilen = ""

func bauen_anfordern(gebaeude_id: String, welt_position: Vector2) -> Dictionary:
	var ergebnis := _bau_auftrag.bauen_anfordern(gebaeude_id, welt_position)
	_melde_platzierung(ergebnis)
	return ergebnis

func bauplan_anfordern(gebaeude_id: String, welt_position: Vector2) -> Dictionary:
	var ergebnis := _bau_auftrag.bauplan_anfordern(gebaeude_id, welt_position)
	_melde_platzierung(ergebnis)
	return ergebnis

func voraussetzung_erfuellt(gebaeude_id: String) -> Dictionary:
	return _bauplatz.voraussetzung_erfuellt(gebaeude_id)

func status_zeilen() -> Array[String]:
	return _status_leser.zeilen()

func _melde_platzierung(ergebnis: Dictionary) -> void:
	## Der Renderer erfährt jede neue Baustelle sofort, ohne Sichtbereichs-Scan.
	if bool(ergebnis.get("ok", false)) and ergebnis.has("objekt_index"):
		gebaeude_platziert.emit(int(ergebnis["objekt_index"]))

func _meldung_text(meldung: String) -> void:
	gebaeude_meldung.emit(meldung)

func _gebaeude_fertig_call(gebaeude_id: String) -> void:
	gebaeude_fertiggestellt.emit(gebaeude_id)

func _status_zeilen_melden() -> void:
	# Doppelmeldungsschutz: Nur ein echter Wechsel der Zeilen wird gemeldet.
	var zeilen := _status_leser.zeilen()
	var zusammengefasst := " | ".join(zeilen)
	if zusammengefasst == _letzte_statuszeilen:
		return
	_letzte_statuszeilen = zusammengefasst
	status_geaendert.emit(zeilen)

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	if not _karten_gate.darf_ticken(_welt_world, _model):
		return
	if _model == null or not _laufzeit.bereit():
		return
	_status_zeilen_melden()
	for index in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition == null:
			continue
		_laufzeit.gebaeude_ticken(index, definition)

func _auf_menue_geoeffnet() -> void:
	# Menü-Gegenprüfung: Die Skalierung rechnet die Laufzeit; der Manager
	# leitet nur pro Gebäude an sie weiter.
	if _model == null:
		return
	for index in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition == null:
			continue
		_laufzeit.abstimmen(index, definition)
