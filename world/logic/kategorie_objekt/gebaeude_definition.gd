extends RefCounted
class_name Gebaeude_Definition
## Datenklasse einer Gebäude-Definition. Enthält ausschließlich Daten aus
## world/data/gebaeude.json: Baukosten, Bauzeit, Arbeitskraft und das
## Produktionsrezept. Keine Logik, keine Aufrufe, keine Zeitquelle.

## Kategorie daten: alle Felder der Gebäude-Definition.
var id: String = ""
var angezeigter_name: String = ""
var kategorie: String = ""
var icon_pfad: String = ""
var welt_objekt_id: String = ""
var baukosten: Dictionary = {}
var bauzeit_ticks: int = 0
var arbeitskraft: String = ""
## Einzige Gating-Wahrheit je Gebaeude: 0 heisst immer frei, N heisst frei
## ab Progressions-Stufe N. Kein UI-Code erfindet mehr eine Stufe.
var gesperrt_ab_stufe: int = 0
## Startvorrat des Ankunftsortes: Wird beim Aufstellen dieses Gebaeudes
## einmalig ins naechste Lager gebucht (Startbestand des Lagerfeuers).
var startbestand: Dictionary = {}
## Belegungsregel als Datum: Ein Gebäude mit true blockiert seine Kachel für
## weitere Gebäude. Die Bauverbindung fragt nur, kein UI erfindet die Regel.
var belegt_kachel: bool = true
var voraussetzungen: Array[String] = []
var inputs: Array[Dictionary] = []
var outputs: Array[Dictionary] = []
var dauer_ticks: int = 0
var wiederholbar: bool = true
var blockiert_ohne_eingang: bool = true
var blockiert_ohne_lagerplatz: bool = true

## Kategorie logik: Einlesen und reine Leser der Definition.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	id = str(eintrag.get("id", ""))
	angezeigter_name = str(eintrag.get("name", id))
	kategorie = str(eintrag.get("kategorie", "Produktion"))
	icon_pfad = str(eintrag.get("icon_pfad", ""))
	welt_objekt_id = str(eintrag.get("welt_objekt_id", id))
	baukosten = (eintrag.get("baukosten", {}) as Dictionary).duplicate(true)
	bauzeit_ticks = int(eintrag.get("bauzeit_ticks", 0))
	arbeitskraft = str(eintrag.get("arbeitskraft", ""))
	gesperrt_ab_stufe = int(eintrag.get("gesperrt_ab_stufe", 0))
	belegt_kachel = bool(eintrag.get("belegt_kachel", true))
	startbestand = (eintrag.get("startbestand", {}) as Dictionary).duplicate(true)
	voraussetzungen.clear()
	for voraussetzung: Variant in (eintrag.get("voraussetzungen", []) as Array):
		voraussetzungen.append(str(voraussetzung))
	var produktion: Dictionary = eintrag.get("produktion", {})
	inputs.clear()
	for input: Variant in (produktion.get("inputs", []) as Array):
		if typeof(input) == TYPE_DICTIONARY:
			inputs.append((input as Dictionary).duplicate(true))
	outputs.clear()
	for output: Variant in (produktion.get("outputs", []) as Array):
		if typeof(output) == TYPE_DICTIONARY:
			outputs.append((output as Dictionary).duplicate(true))
	dauer_ticks = int(produktion.get("dauer_ticks", 0))
	wiederholbar = bool(produktion.get("wiederholbar", true))
	blockiert_ohne_eingang = bool(produktion.get("blockiert_ohne_eingang", true))
	blockiert_ohne_lagerplatz = bool(produktion.get("blockiert_ohne_lagerplatz", true))

func input_menge(ressource: String) -> int:
	for input: Dictionary in inputs:
		if str(input.get("ressource", "")) == ressource:
			return int(input.get("menge", 0))
	return 0

func output_menge(ressource: String) -> int:
	for output: Dictionary in outputs:
		if str(output.get("ressource", "")) == ressource:
			return int(output.get("menge", 0))
	return 0

func baukosten_paare() -> Array[Dictionary]:
	# Deterministische Reihenfolge der Kosten je Ressource.
	var paare: Array[Dictionary] = []
	for ressource: String in baukosten.keys():
		paare.append({"ressource": ressource, "menge": int(baukosten[ressource])})
	paare.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["ressource"]) < str(b["ressource"]))
	return paare
