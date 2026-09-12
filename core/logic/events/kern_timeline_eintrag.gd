extends RefCounted
class_name Kern_TimelineEintrag
## Ein einzelner Eintrag der Zustands-Timeline. Er beschreibt eine Mutation
## als Delta: Nur die betroffenen Schluessel stehen in vorher und nachher,
## nie der komplette Zustand (kein Dump). Quelle und Beschreibung erklaeren,
## warum der Zustand sich geaendert hat; der Modifikator-Einfluss wird als
## ID und Faktor festgehalten, damit Kombinationen sichtbar bleiben.

## Kategorie daten: Was sich wann und warum geaendert hat.
var tick: int = 0
var ziel_id: String = ""
var quelle: String = ""
var beschreibung: String = ""
var vorher: Dictionary = {}
var nachher: Dictionary = {}
var modifikator_id: String = ""
var faktor: float = 1.0

func einrichten(neuer_tick: int, neues_ziel: String, neue_quelle: String,
		neue_beschreibung: String, alter_zustand: Dictionary, neuer_zustand: Dictionary,
		mod_id: String = "", neuer_faktor: float = 1.0) -> void:
	tick = neuer_tick
	ziel_id = neues_ziel
	quelle = neue_quelle
	beschreibung = neue_beschreibung
	vorher = alter_zustand.duplicate(true)
	nachher = neuer_zustand.duplicate(true)
	modifikator_id = mod_id
	faktor = neuer_faktor

func delta_text() -> String:
	# Kompakte menschenlesbare Fassung eines Eintrags fuer das HUD.
	var teile: Array[String] = []
	for schluessel: String in nachher.keys():
		teile.append("%s: %s -> %s" % [schluessel, str(vorher.get(schluessel, "?")), str(nachher[schluessel])])
	return beschreibung + (" (%s)" % ", ".join(teile) if not teile.is_empty() else "")
