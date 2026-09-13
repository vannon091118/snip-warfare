extends RefCounted
class_name Kern_TastenTabelle
## Uebersetzungstabelle der Steuerung: Menschliche Tastennamen aus
## steuerung.json werden in Keycodes der Engine aufgeloest, Gruppen wie
## "Pfeiltasten" in ihre Einzeltasten gespalten, und die InputMap erhaelt
## die Kamera-Aktionen aus den geladenen Listen. Genau eine Verantwortung:
## Tasten uebersetzen und Aktionen fuellen. Kein Config-Lesen, kein
## Spielverhalten; die Registry laedt die Daten, diese Klasse ordnet sie zu.

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

## Kategorie logik: Uebersetzung und InputMap-Fuellung.

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

## Erzeugt die Engine-Aktionen aus den gegebenen Listen. Die Ausführung
## liegt bei Kern_SteuerungRegistry.inputmap_registrieren, denn nur die
## Registry lädt die Konfiguration; diese Tabelle ordnet jeder
## Konfigurationsstelle ihren Aktionsnamen zu.
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
