extends RefCounted
class_name Kern_ModifikatorBasis
## Datenklasse eines Modifikators. Ein Modifikator ist eine eigene Klasse
## mit einem Faktor. Der Faktor 1.0 bedeutet 10 Sekunden Takt; die Ticks
## ergeben sich aus der globalen Weltuhr (faktor * 10 Sekunden in Ticks).
## Objekte, Tiere und Einheiten kombinieren eine Logik mit einem Modifikator
## über ihre Registries; damit entstehen Varianten ohne neue Verhaltensklassen.
## Zusätzlich trägt ein Modifikator physische Folgen: Job-Einschränkungen,
## Attribut-Modifikationen, Dauer in Ticks und Heilbarkeit.

enum ModifikatorTyp {
	GESCHWINDIGKEIT,
	VERLETZUNG,
	BUFF,
	DEBUFF,
}

## Kategorie daten: Felder des Modifikators.
var modifikator_id: String = ""
var angezeigter_name: String = ""
var typ: ModifikatorTyp = ModifikatorTyp.GESCHWINDIGKEIT
var beschreibung: String = ""
var faktor: float = 1.0
var job_einschraenkungen: Array[String] = []
var attribute_modifikation: Dictionary = {}
var dauer_ticks: int = 0
var heilbar: bool = true
var icon_pfad: String = ""

## Kategorie logik: Einlesen und Ticken der Dauer.

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	modifikator_id = eintrag_id
	angezeigter_name = str(eintrag.get("name", eintrag_id))
	typ = _typ_aus_text(str(eintrag.get("typ", "GESCHWINDIGKEIT")))
	beschreibung = str(eintrag.get("beschreibung", ""))
	faktor = float(eintrag.get("faktor", 1.0))
	job_einschraenkungen.clear()
	var einschraenkungen: Variant = eintrag.get("job_einschraenkungen", [])
	if typeof(einschraenkungen) == TYPE_ARRAY:
		for job_id: String in einschraenkungen:
			job_einschraenkungen.append(job_id)
	attribute_modifikation = eintrag.get("attribute_modifikation", {})
	dauer_ticks = int(eintrag.get("dauer_ticks", 0))
	heilbar = bool(eintrag.get("heilbar", true))
	icon_pfad = str(eintrag.get("icon_pfad", ""))

func blockiert_job(job_id: String) -> bool:
	# Nur Verletzungen sperren Jobs; Buffs und Debuffs sperren nichts.
	if typ != ModifikatorTyp.VERLETZUNG:
		return false
	return job_id in job_einschraenkungen

func blockierender_name_fuer_job(job_id: String) -> String:
	if blockiert_job(job_id):
		return angezeigter_name
	return ""

func tick_zaehlen() -> void:
	# Ein Tick der Weltuhr zählt die verbleibende Dauer herunter.
	if dauer_ticks > 0:
		dauer_ticks -= 1

func abgelaufen() -> bool:
	return dauer_ticks == 0

func _typ_aus_text(text: String) -> ModifikatorTyp:
	match text:
		"VERLETZUNG":
			return ModifikatorTyp.VERLETZUNG
		"BUFF":
			return ModifikatorTyp.BUFF
		"DEBUFF":
			return ModifikatorTyp.DEBUFF
	return ModifikatorTyp.GESCHWINDIGKEIT
