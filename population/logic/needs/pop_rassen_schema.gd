extends RefCounted
class_name Pop_RassenSchema
## Datenklasse eines Rassen-Schemas.
-- Reines Einlesen aus rassen_schemata.json oder Generierung durch Rassen_Generator.
-- Jede Rasse trägt Multiplikatoren, mit denen die Need-Maschinen ihre Werte
-- skalieren: Nahrungsverbrauch, Dringlichkeit, Abfall, Schwellwert und
-- Bewegung. Der zentrale Modifikator-Faktor multipliziert zusätzlich; das
-- Schema selbst enthält keine Logik und ruft nichts auf.
-- Instanzen sind nach Initialisierung immutabel (nicht mehr änderbar).
-- Immuntät wird durch _finalisiert-Flag und Preflight-Prüfung durchgesetzt.

## Kategorie daten: Rassen-Identität und Multiplikator-Faktoren.
var rasse_id: String = ""
var angezeigter_name: String = ""
var beschreibung: String = ""

## Diese Faktoren sind nach dem Setzen via _finalisieren() nicht mehr änderbar.
## Werden als var deklariert, um Godot-Syntax zu erlauben, aber die
-- Immuntät wird durch _finalisiert-Flag und setter-Prüfung durchgesetzt.
var faktor_nahrung: float = 1.0
var faktor_dringlichkeit: float = 1.0
var faktor_abfall: float = 1.0
var faktor_schwellwert: float = 1.0
var faktor_bewegung: float = 1.0
var grab_bonus: float = 1.0
var icon_pfad: String = ""

## Interner Zustand
var _finalisiert: bool = false

## Kategorie logik: Erstelle Schema aus Daten-Eintrag (aus rassen_schemata.json).

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	## Setze alle Felder aus dem Eintrag - nach diesem Aufruf ist die Instanz immutabel
	_pruefe_nicht_finalisiert("aus_eintrag")
	rasse_id = eintrag_id
	angezeigter_name = str(eintrag.get("name", eintrag_id))
	beschreibung = str(eintrag.get("beschreibung", ""))

	## Faktor-Werte ausschließlich aus dem Daten-Pool lesen - KEINE hartcodierten Werte
	faktor_nahrung = float(eintrag.get("faktor_nahrung", 1.0))
	faktor_dringlichkeit = float(eintrag.get("faktor_dringlichkeit", 1.0))
	faktor_abfall = float(eintrag.get("faktor_abfall", 1.0))
	faktor_schwellwert = float(eintrag.get("faktor_schwellwert", 1.0))
	faktor_bewegung = float(eintrag.get("faktor_bewegung", 1.0))
	grab_bonus = float(eintrag.get("grab_bonus", 1.0))

	icon_pfad = str(eintrag.get("icon_pfad", ""))

	## Finalisieren: Ab jetzt immutabel
	_finalisieren()

## Kategorie logik: Initialisierung für generierte Rassen (vor Finalisierung).

func _initialisiere_generiert(p_rasse_id: String, p_name: String, p_beschreibung: String) -> void:
	_pruefe_nicht_finalisiert("_initialisiere_generiert")
	rasse_id = p_rasse_id
	angezeigter_name = p_name
	beschreibung = p_beschreibung

## Kategorie logik: Protected Setter für Generierung (nur vor Finalisierung erlaubt).

func _faktor_nahrung_setzen(wert: float) -> void:
	_pruefe_nicht_finalisiert("_faktor_nahrung_setzen")
	faktor_nahrung = wert

func _faktor_dringlichkeit_setzen(wert: float) -> void:
	_pruefe_nicht_finalisiert("_faktor_dringlichkeit_setzen")
	faktor_dringlichkeit = wert

func _faktor_abfall_setzen(wert: float) -> void:
	_pruefe_nicht_finalisiert("_faktor_abfall_setzen")
	faktor_abfall = wert

func _faktor_schwellwert_setzen(wert: float) -> void:
	_pruefe_nicht_finalisiert("_faktor_schwellwert_setzen")
	faktor_schwellwert = wert

func _faktor_bewegung_setzen(wert: float) -> void:
	_pruefe_nicht_finalisiert("_faktor_bewegung_setzen")
	faktor_bewegung = wert

func _grab_bonus_setzen(wert: float) -> void:
	_pruefe_nicht_finalisiert("_grab_bonus_setzen")
	grab_bonus = wert

func _icon_pfad_setzen(pfad: String) -> void:
	_pruefe_nicht_finalisiert("_icon_pfad_setzen")
	icon_pfad = pfad

## Kategorie logik: Finalisierung - macht die Instanz immutabel.

func _finalisieren() -> void:
	if _finalisiert:
		push_error("Pop_RassenSchema '%s' bereits finalisiert" % rasse_id)
		return
	_finalisiert = true
	push_debug("Pop_RassenSchema '%s' (%s) ist nun immutabel - keine weiteren Änderungen erlaubt." % [rasse_id, angezeigter_name])

func _pruefe_nicht_finalisiert(aufrufer: String) -> void:
	if _finalisiert:
		push_error("Versuch, finales Pop_RassenSchema '%s' über %s zu ändern - VERBOTEN" % [rasse_id, aufrufer])
		## Im Preflight wird dies als Fehler E025 (Warnung) gemeldet

## Kategorie logik: Wert für einen bestimmten Bedürfnistyp zurückgeben.

func faktor_fuer(bedarfstyp: String) -> float:
	match bedarfstyp:
		"nahrung":
			return faktor_nahrung
		"dringlichkeit":
			return faktor_dringlichkeit
		"abfall":
			return faktor_abfall
		"schwellwert":
			return faktor_schwellwert
		"bewegung":
			return faktor_bewegung
		"grab":
			return grab_bonus
		return 1.0

## Kategorie logik: Serialisierung für Speicherstand.

func nach_woerterbuch() -> Dictionary:
	return {
		"rasse_id": rasse_id,
		"name": angezeigter_name,
		"beschreibung": beschreibung,
		"faktor_nahrung": faktor_nahrung,
		"faktor_dringlichkeit": faktor_dringlichkeit,
		"faktor_abfall": faktor_abfall,
		"faktor_schwellwert": faktor_schwellwert,
		"faktor_bewegung": faktor_bewegung,
		"grab_bonus": grab_bonus,
		"icon_pfad": icon_pfad
	}

func aus_woerterbuch(daten: Dictionary) -> void:
	_pruefe_nicht_finalisiert("aus_woerterbuch")
	rasse_id = str(daten.get("rasse_id", ""))
	angezeigter_name = str(daten.get("name", ""))
	beschreibung = str(daten.get("beschreibung", ""))
	faktor_nahrung = float(daten.get("faktor_nahrung", 1.0))
	faktor_dringlichkeit = float(daten.get("faktor_dringlichkeit", 1.0))
	faktor_abfall = float(daten.get("faktor_abfall", 1.0))
	faktor_schwellwert = float(daten.get("faktor_schwellwert", 1.0))
	faktor_bewegung = float(daten.get("faktor_bewegung", 1.0))
	grab_bonus = float(daten.get("grab_bonus", 1.0))
	icon_pfad = str(daten.get("icon_pfad", ""))
	_finalisieren()

## Kategorie logik: Prüfung auf Immuntät.

func ist_finalisiert() -> bool:
	return _finalisiert