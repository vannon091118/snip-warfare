extends RefCounted
class_name Pop_MoralInstanz
## Moral-Instanz der Kolonie: Sie traegt die Grundsaetze des Spielers als
## reine Daten und beantwortet die Zielwahl-Fragen der Verhaltens-Maschine.
## Sie verbietet keine Jagd und rechnet nichts: Sie sperrt ein Verhalten
## und nennt die Ersatzhandlung aus dem Pool moral_regeln.json. Die
## Eskalations-Schwellen bleiben ausschliesslich in mood_modifikatoren.json.

const QUELLE := "res://world/data/moral_regeln.json"

## Kategorie daten: Die Grundsaetze und ihre Ersatzhandlungen aus dem Pool.
var _grundsaetze: Dictionary = {}
var _ersatzhandlungen: Array[Dictionary] = []

## Kategorie logik: Laden, Fragen beantworten, Grundsaetze setzen,
## Schalter-Metadaten fuer das Grundsatz-Fenster liefern.

const SCHALTER_TEXTE := {
	"kannibalismus_erlaubt": {
		"label": "Kannibalismus erlauben",
		"tooltip": "Sobald die Hunger-Kette den Verzweiflungsschritt erreicht, darf eine Einheit den schwaechsten Nachbarn jagen. Verboten bleibt die Umleitung zur Ersatzhandlung.",
	},
	"tiere_bevorzugt": {
		"label": "Tiere als Nahrung bevorzugen",
		"tooltip": "Die Beute-Auswahl greift zuerst zu jagdbaren Tieren, bevor Artgenossen in Betracht kommen.",
	},
	"bindungsobjekt_geschuetzt": {
		"label": "Gebundene Tiere schuetzen",
		"tooltip": "Tiere mit Bindung an die Kolonie fallen aus der Beute-Auswahl, das naechste ungebundene Tier rueckt nach.",
	},
	"verhungern_erlaubt": {
		"label": "Verhungern als letztes Mittel",
		"tooltip": "Bleibt keine legale Ersatzhandlung, darf die Einheit verhungern, statt die Verzweiflungstat zu tragen.",
	},
}

func _init() -> void:
	laden()

func laden() -> void:
	_grundsaetze.clear()
	_ersatzhandlungen.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Moral-Regeln nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Moral-Regeln ungueltiges Format: %s" % QUELLE)
		return
	var pool: Dictionary = gelesen as Dictionary
	_grundsaetze = (pool.get("grundsaetze", {}) as Dictionary).duplicate(true)
	for eintrag: Variant in pool.get("ersatzhandlungen", []):
		if eintrag is Dictionary:
			_ersatzhandlungen.append((eintrag as Dictionary).duplicate(true))

func darf_wert(schalter_id: String) -> bool:
	## Der reine Schalter-Wert, den das Fenster liest und schreibt.
	return bool(_grundsaetze.get(schalter_id, false))

func darf_verhalten(verhalten_id: String) -> bool:
	## Die Frage der Verhaltens-Maschine: Traegt die Kolonie diesen Schritt?
	match verhalten_id:
		"kannibalismus", "kannibalismus_erwaegen", "kannibalismus_planen":
			return bool(_grundsaetze.get("kannibalismus_erlaubt", false))
		_:
			return true

func ersatzhandlung_fuer(blockade_id: String) -> String:
	## Die Umleitung statt der Tat: Die erste passende Regel gewinnt.
	return str(ersatz_regel_fuer_blockade(blockade_id).get("aktion", ""))

func ersatz_regel_fuer_blockade(blockade_id: String) -> Dictionary:
	for regel: Dictionary in _ersatzhandlungen:
		if str(regel.get("bei_blockade", "")) == blockade_id:
			return regel
	return {}

func ersatz_regel(aktion_id: String) -> Dictionary:
	## Die volle Regel zu einer Aktion: Job und Ziel-Objekte fuer die Autonomie.
	for regel: Dictionary in _ersatzhandlungen:
		if str(regel.get("aktion", "")) == aktion_id:
			return regel
	return {}

func grundsaetz_setzen(schalter_id: String, erlaubt: bool) -> void:
	## Der Einzel-Griff des Fensters: Nur bekannte Schalter wandern hinein.
	if _grundsaetze.has(schalter_id):
		_grundsaetze[schalter_id] = erlaubt

func grundsaetze_setzen(neu: Dictionary) -> void:
	# Der Spieler-Griff: Nur bekannte Schalter wandern hinein, alles andere ruht.
	for schluessel: String in neu.keys():
		if _grundsaetze.has(schluessel):
			_grundsaetze[schluessel] = neu[schluessel]

func grundsaetze() -> Dictionary:
	return _grundsaetze.duplicate(true)

func schalter_ids() -> Array[String]:
	## Die reinen Schluessel des Schalter-Regals, ohne die Beschreibungs-Zeile.
	var ids: Array[String] = []
	for schluessel: String in _grundsaetze.keys():
		if schluessel == "beschreibung":
			continue
		ids.append(schluessel)
	ids.sort()
	return ids

func schalter_text(schalter_id: String) -> Dictionary:
	## Label und Tooltip eines Schalters fuer das Fenster; ohne Eintrag ruht der
	## Schalter unbeschriftet und das Fenster zeigt nur den Schluessel.
	return (SCHALTER_TEXTE.get(schalter_id, {}) as Dictionary).duplicate(true)


static func schalter_ids_fuer() -> Array[String]:
	## Die statische Bruecke der UI: Die Schluessel stehen in den Konstanten
	## des Datei-Scope, eine Instanz wird dafuer nicht angefasst.
	var ids: Array[String] = []
	for schluessel: String in SCHALTER_TEXTE.keys():
		ids.append(schluessel)
	ids.sort()
	return ids


static func schalter_text_statisch(schalter_id: String) -> Dictionary:
	return (SCHALTER_TEXTE.get(schalter_id, {}) as Dictionary).duplicate(true)
