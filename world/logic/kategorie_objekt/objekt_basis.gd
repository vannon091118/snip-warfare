extends RefCounted
class_name Objekt_Basis
## Datenklasse eines platzierbaren Weltobjekts. Enthält ausschließlich Daten
## und keine Funktionsaufrufe: Jede Klasse liest ihre Werte selbst aus dem
## Element-Katalog. Der Renderer und die State Machines lesen nur diese
## Felder und übersetzen sie in Darstellung beziehungsweise Verhalten.

var id: String = ""
var angezeigter_name: String = ""
var kategorie: StringName = &""
var typ: StringName = &"objekt"
var textur_pfad: String = ""
var anzeige_breite: float = 128.0
var anzeige_hoehe: float = 128.0
var arbeits_ressource: String = ""
var logik_id: String = ""
var modifikator_id: String = "normal"
var faktor: float = 1.0
var funktions_animation: String = ""
var schluessel_daten: Dictionary = {}

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	# Reines Einlesen der Daten; hier wird nichts berechnet und nichts aufgerufen.
	id = str(eintrag.get("id", ""))
	angezeigter_name = str(eintrag.get("name", id))
	kategorie = StringName(str(eintrag.get("kategorie", "Objekt")))
	typ = StringName(str(eintrag.get("typ", "objekt")))
	textur_pfad = str(eintrag.get("textur_pfad", ""))
	anzeige_breite = float(eintrag.get("anzeige_breite", 128.0))
	anzeige_hoehe = float(eintrag.get("anzeige_hoehe", 128.0))
	arbeits_ressource = str(eintrag.get("arbeits_ressource", ""))
	logik_id = str(eintrag.get("logik_id", ""))
	modifikator_id = str(eintrag.get("modifikator_id", "normal"))
	faktor = float(eintrag.get("faktor", 1.0))
	# Funktions-Animation als Registry-Name aus game/data/animationen.json:
	# Der Darsteller entscheidet daraus, ob er das Objekt animiert malt.
	funktions_animation = str(eintrag.get("funktions_animation", ""))
	schluessel_daten = eintrag.duplicate()

func ticks_fuer_faktor() -> int:
	return Kern_Weltuhr.ticks_aus_faktor(faktor)

func effektive_logik() -> String:
	return logik_id

func effektiver_modifikator() -> String:
	return modifikator_id
