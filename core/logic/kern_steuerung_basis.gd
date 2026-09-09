extends RefCounted
class_name Kern_SteuerungBasis
## Datenklasse der Steuerung. Haelt nur Daten aus game/data/steuerung.json;
## keine feste Verdrahtung, kein hart codierter Shortcut. Die Registry liest
## diese Datei und andere Maschinen ziehen nur ueber diese Klasse ihre Werte.

## Kategorie daten: Felder der Steuerungskonfiguration.
var version: int = 1
var kamera_tasten: Array[String] = []
var kamera_alternativ: Array[String] = []
var kamera_geschwindigkeit: float = 520.0
var kamera_beschreibung: String = ""
var auswahl_radius: float = 60.0
var auswahl_rechteck_stil: String = ""
var kontext_ausloeser: String = "rechtsklick"
var kontext_position: String = "am Cursor"
var kontext_aktionen: Array[Dictionary] = []
var hinweis_werkzeug: String = ""
var ticks_hinweis: String = ""

## Kategorie logik: Einlesen und Abfragen der Config.
func aus_eintrag(eintrag: Dictionary) -> void:
	version = int(eintrag.get("version", 1))
	var kamera: Dictionary = eintrag.get("kamera", {}) if typeof(eintrag.get("kamera", {})) == TYPE_DICTIONARY else {}
	var auswahl: Dictionary = eintrag.get("auswahl", {}) if typeof(eintrag.get("auswahl", {})) == TYPE_DICTIONARY else {}
	var kontext: Dictionary = eintrag.get("kontextmenue", {}) if typeof(eintrag.get("kontextmenue", {})) == TYPE_DICTIONARY else {}
	kamera_tasten.clear()
	for eintrag_taste in kamera.get("tasten", []):
		kamera_tasten.append(str(eintrag_taste))
	kamera_alternativ.clear()
	for eintrag_alt in kamera.get("alternativ_tasten", []):
		kamera_alternativ.append(str(eintrag_alt))
	kamera_geschwindigkeit = float(kamera.get("geschwindigkeit", 520.0))
	kamera_beschreibung = str(kamera.get("beschreibung", ""))
	auswahl_radius = float(auswahl.get("auswahl_radius", 60.0))
	auswahl_rechteck_stil = str(auswahl.get("rechteck_stil", ""))
	kontext_ausloeser = str(kontext.get("ausloeser", "Rechtsklick oeffnet immer ein Kontextmenue"))
	kontext_position = str(kontext.get("position", "am Cursor"))
	kontext_aktionen.clear()
	for aktion in kontext.get("aktionen", []):
		if typeof(aktion) == TYPE_DICTIONARY:
			kontext_aktionen.append((aktion as Dictionary).duplicate(true))
	hinweis_werkzeug = str(eintrag.get("hinweis_werkzeug", ""))
	ticks_hinweis = str(eintrag.get("ticks_hinweis", ""))

func tooltip_fuer_aktion(aktion_id: String) -> String:
	for aktion in kontext_aktionen:
		if str(aktion.get("id", "")) == aktion_id:
			var vorlage := str(aktion.get("tooltip", ""))
			var werkzeug := str(aktion.get("werkzeug", ""))
			return vorlage.replace("{werkzeug}", werkzeug)
	return ""

func icon_fuer_aktion(aktion_id: String) -> String:
	for aktion in kontext_aktionen:
		if str(aktion.get("id", "")) == aktion_id:
			return str(aktion.get("icon_pfad", ""))
	return ""

func label_fuer_aktion(aktion_id: String) -> String:
	for aktion in kontext_aktionen:
		if str(aktion.get("id", "")) == aktion_id:
			return str(aktion.get("label", aktion_id))
	return aktion_id

func logik_fuer_aktion(aktion_id: String) -> String:
	for aktion in kontext_aktionen:
		if str(aktion.get("id", "")) == aktion_id:
			return str(aktion.get("logik_id", ""))
	return ""

func faktor_fuer_aktion(aktion_id: String) -> float:
	for aktion in kontext_aktionen:
		if str(aktion.get("id", "")) == aktion_id:
			return float(aktion.get("faktor", 1.0))
	return 1.0
