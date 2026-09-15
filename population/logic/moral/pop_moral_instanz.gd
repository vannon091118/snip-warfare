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

## Kategorie logik: Laden, Fragen beantworten, Grundsaetze setzen.

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

func grundsaetze_setzen(neu: Dictionary) -> void:
	# Der Spieler-Griff: Nur bekannte Schalter wandern hinein, alles andere ruht.
	for schluessel: String in neu.keys():
		if _grundsaetze.has(schluessel):
			_grundsaetze[schluessel] = neu[schluessel]

func grundsaetze() -> Dictionary:
	return _grundsaetze.duplicate(true)
