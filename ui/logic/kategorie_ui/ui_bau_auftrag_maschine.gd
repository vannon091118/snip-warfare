extends RefCounted
class_name Ui_BauAuftragMaschine
## Bauauftrag-Maschine der Eingabe-Domäne: Hält genau einen aktiven Bauauftrag,
## meldet den Bauplatz-Wunsch, platziert den Bauplan am Klick-Ort und bricht
## ab. Kein Klick-Übersetzen, kein Job-Kram: nur der Bau-Auftrags-Lebenslauf.

## Kategorie daten: Auftrags- und Ziel-Referenzen.
var _gebaeude: Gebaeude_Manager = null
var _hud: VBoxContainer = null
var _aktiver_bau_auftrag: String = ""

## Kategorie logik: Auftrag halten, platzieren, abbrechen.

func einrichten(gebaeude: Gebaeude_Manager, hud: VBoxContainer) -> void:
	_gebaeude = gebaeude
	_hud = hud

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
	var ergebnis: Dictionary
	if _gebaeude.has_method("bauplan_anfordern"):
		ergebnis = _gebaeude.bauplan_anfordern(gebaeude_id, pos)
	else:
		ergebnis = _gebaeude.bauen_anfordern(gebaeude_id, pos)
	if bool(ergebnis.get("ok", false)):
		(_hud as Variant).meldung_setzen("Bauplan platziert: %s" % gebaeude_id.capitalize())
	else:
		(_hud as Variant).meldung_setzen("Bauen nicht möglich: %s" % str(ergebnis.get("grund", "unbekannt")))
