extends RefCounted
class_name Ui_BauAuftragMaschine
## Bauauftrag-Maschine der Eingabe-Domäne: Hält genau einen aktiven Bauauftrag,
## meldet den Bauplatz-Wunsch, platziert den Bauplan am Klick-Ort und bricht
## ab. Sie kennt die Gedecke einer jeden Bauart nicht — nur den Zweig.
##
## Verantwortlichkeit: Bau-Auftrags-Lebenslauf.
##
## Zweige je bautyp:
##  - moebel   → Objekt_MoebelPlatzierer (direkt ins Modell, kein Lagerbezug)
##  - lagerzone→ Welt_LagerzoneRegister (Raum-Prüfung, Lager anlegen, Signal)
##  - sonst    → Gebaeude_Manager.bauplan_anfordern (Wände, Türen, Boden, Gebäude)

var _gebaeude: Gebaeude_Manager = null
var _moebel_platzierer: Objekt_MoebelPlatzierer = null
var _lagerzone_register: Welt_LagerzoneRegister = null
var _definitionen: Gebaeude_DefinitionRegistry = null
var _hud: VBoxContainer = null
var _aktiver_bau_auftrag: String = ""

func einrichten(gebaeude: Gebaeude_Manager, hud: VBoxContainer, moebel_platzierer: Objekt_MoebelPlatzierer = null) -> void:
	_gebaeude = gebaeude
	_hud = hud
	_moebel_platzierer = moebel_platzierer

func lagerzone_register_setzen(register: Welt_LagerzoneRegister) -> void:
	_lagerzone_register = register

func definitionen_setzen(registry: Gebaeude_DefinitionRegistry) -> void:
	_definitionen = registry

func auftrag_aktiv() -> bool:
	return _aktiver_bau_auftrag != ""

func auftrag_id() -> String:
	return _aktiver_bau_auftrag

func auftrag_setzen(gebaeude_id: String) -> void:
	_aktiver_bau_auftrag = gebaeude_id
	if _hud != null:
		(_hud as Variant).meldung_setzen("Bauplatz für %s wählen (Linksklick platziert, Rechtsklick/Esc bricht ab)" % gebaeude_id.capitalize())

func auftrag_platzieren_an(ziel_pos: Vector2) -> void:
	if _aktiver_bau_auftrag == "":
		return
	_bauen_an_position(_aktiver_bau_auftrag, ziel_pos)
	_aktiver_bau_auftrag = ""

func auftrag_abbrechen() -> void:
	if _aktiver_bau_auftrag == "":
		return
	_aktiver_bau_auftrag = ""
	if _hud != null:
		(_hud as Variant).meldung_setzen("Bauauftrag abgebrochen.")

func _bauen_an_position(gebaeude_id: String, pos: Vector2) -> void:
	if _gebaeude == null or _hud == null:
		return
	var bautyp := _bautyp_fuer(gebaeude_id)
	if bautyp == "moebel":
		if _moebel_platzierer != null and _moebel_platzierer._registry != null and _moebel_platzierer._registry.moebel().moebel(gebaeude_id) != null:
			var moebel_ergebnis := _moebel_platzierer.platzieren(gebaeude_id, pos)
			if bool(moebel_ergebnis.get("ok", false)):
				(_hud as Variant).meldung_setzen("Möbel platziert: %s" % gebaeude_id.capitalize())
			else:
				(_hud as Variant).meldung_setzen("Platzieren nicht möglich: %s" % str(moebel_ergebnis.get("grund", "unbekannt")))
			return
		# Fallback: Definition als Gebäude platzieren (neue Möbel-Einträge ohne Registry-Eintrag)
		var ergebnis_moebel: Dictionary = _gebaeude.bauplan_anfordern(gebaeude_id, pos)
		if bool(ergebnis_moebel.get("ok", false)):
			(_hud as Variant).meldung_setzen("Bauplan platziert: %s" % gebaeude_id.capitalize())
		else:
			(_hud as Variant).meldung_setzen("Bauen nicht möglich: %s" % str(ergebnis_moebel.get("grund", "unbekannt")))
		return
	if bautyp == "lagerzone":
		if _lagerzone_register == null:
			(_hud as Variant).meldung_setzen("Lager-Werkzeug nicht bereit.")
			return
		var zone_ergebnis := _lagerzone_register.lagerzone_registrieren(pos)
		if bool(zone_ergebnis.get("ok", false)):
			(_hud as Variant).meldung_setzen("Lagerfläche registriert: %s" % str(zone_ergebnis.get("raum_id", "")))
		else:
			(_hud as Variant).meldung_setzen("Lagerfläche: %s" % str(zone_ergebnis.get("grund", "ungültiger Raum")))
		return
	var ergebnis: Dictionary
	if _gebaeude.has_method("bauplan_anfordern"):
		ergebnis = _gebaeude.bauplan_anfordern(gebaeude_id, pos)
	else:
		ergebnis = _gebaeude.bauen_anfordern(gebaeude_id, pos)
	if bool(ergebnis.get("ok", false)):
		(_hud as Variant).meldung_setzen("Bauplan platziert: %s" % gebaeude_id.capitalize())
	else:
		(_hud as Variant).meldung_setzen("Bauen nicht möglich: %s" % str(ergebnis.get("grund", "unbekannt")))

func _bautyp_fuer(gebaeude_id: String) -> String:
	if _definitionen != null:
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition != null:
			return str(definition.bautyp)
	# Rückfall: alte Möbel-IDs aus element_katalog
	if _moebel_platzierer != null and _moebel_platzierer._registry != null:
		if _moebel_platzierer._registry.moebel().moebel(gebaeude_id) != null:
			return "moebel"
	return "gebaeude"
