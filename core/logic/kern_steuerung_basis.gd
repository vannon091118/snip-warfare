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

func gesperrt_ab_stufe_fuer_aktion(aktion_id: String) -> int:
	# Menschenlesbare Sperre je Aktion: 0 heißt immer offen, N heißt frei
	# ab Progressions-Stufe N. Die Progressions-Maschine beantwortet die
	# Frage, ob die Stufe erreicht ist; diese Klasse liest nur die Zahl.
	for aktion in kontext_aktionen:
		if str(aktion.get("id", "")) == aktion_id:
			return int(aktion.get("gesperrt_ab_stufe", 0))
	return 0

## Kategorie logik: Eingabe-Aktionen (InputMap) aus der Konfiguration.

## Die vier Kamera-Richtungs-Aktionen des Projekts: Die Spielszene liest
## sie über Input.get_vector, ohne eine Taste im Code zu kennen.
const AKTION_HOCH := "kamera_hoch"
const AKTION_LINKS := "kamera_links"
const AKTION_RUNTER := "kamera_runter"
const AKTION_RECHTS := "kamera_rechts"
## Vorgabe der Konfiguration: kamera.tasten steht in WASD-Reihenfolge,
## alternativ_tasten in Pfeiltasten-Reihenfolge (hoch, links, runter, rechts).
const KAMERA_RICHTUNGS_AKTIONEN: Array[String] = [AKTION_HOCH, AKTION_LINKS, AKTION_RUNTER, AKTION_RECHTS]
const KAMERA_ALTERNATIV_AKTIONEN: Array[String] = ["ui_up", "ui_left", "ui_down", "ui_right"]

## Menschliche Tastenbezeichnung aus steuerung.json in den Keycode der
## Engine übersetzt. Unbekannte Namen liefern KEY_NONE und werden beim
## Registrieren stillschweigend übergangen.
static func keycode_fuer_taste(name: String) -> Key:
	var nomen := name.strip_edges().to_lower()
	match nomen:
		"w":
			return KEY_W
		"a":
			return KEY_A
		"s":
			return KEY_S
		"d":
			return KEY_D
		"pfeil links", "links", "left":
			return KEY_LEFT
		"pfeil rechts", "rechts", "right":
			return KEY_RIGHT
		"pfeil hoch", "hoch", "up":
			return KEY_UP
		"pfeil runter", "runter", "down":
			return KEY_DOWN
		"leertaste", "space":
			return KEY_SPACE
		"escape", "esc":
			return KEY_ESCAPE
		"shift":
			return KEY_SHIFT
		"strg", "ctrl":
			return KEY_CTRL
		"enter":
			return KEY_ENTER
		_:
			return KEY_NONE

## Löst Gruppen-Namen in Einzeltasten auf: Ein einziger Eintrag
## "Pfeiltasten" in alternativ_tasten steht für alle vier Pfeile in der
## Reihenfolge hoch, links, runter, rechts. Alle anderen Listen bleiben
## unverändert.
static func tastenliste_aufloesen(tasten: Array[String]) -> Array[String]:
	if tasten.size() == 1:
		var einzeln := tasten[0].strip_edges().to_lower()
		if einzeln == "pfeiltasten" or einzeln == "arrow keys" or einzeln == "arrowkeys":
			return ["Pfeil hoch", "Pfeil links", "Pfeil runter", "Pfeil rechts"] as Array[String]
	return tasten

## Erzeugt die Engine-Aktionen aus kamera.tasten und kamera.alternativ_tasten.
## Die Ausführung liegt bei Kern_SteuerungRegistry.inputmap_registrieren,
## denn nur die Registry lädt die Konfiguration; diese Tabelle ordnet
## jeder Konfigurationsstelle ihren Aktionsnamen zu.
static func _aktion_auffuellen(tasten: Array[String], aktions_namen: Array[String]) -> int:
	var neu_registriert := 0
	for lauf in mini(tasten.size(), aktions_namen.size()):
		var aktions_name := aktions_namen[lauf]
		if not InputMap.has_action(aktions_name):
			InputMap.add_action(aktions_name)
		var code := keycode_fuer_taste(tasten[lauf])
		if code == KEY_NONE:
			continue
		var ereignis := InputEventKey.new()
		ereignis.keycode = code
		if not InputMap.action_has_event(aktions_name, ereignis):
			InputMap.action_add_event(aktions_name, ereignis)
		neu_registriert += 1
	return neu_registriert
