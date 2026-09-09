extends RefCounted
class_name Kern_ModifikatorBasis
## Datenklasse eines Modifikators. Ein Modifikator ist eine eigene Klasse
## mit einem Faktor. Der Faktor 1.0 bedeutet 10 Sekunden Takt; die Ticks
## ergeben sich aus der globalen Weltuhr (faktor * 10 Sekunden in Ticks).
## Objekte und Tiere kombinieren eine Logik mit einem Modifikator über ihre
## Registries; damit entstehen Varianten ohne neue Verhaltensklassen.
##
## Erweiterung Phase 3.3: Physische Modifikatoren (Verletzungen, Buffs, Debuffs)
## mit Job-Einschränkungen, Attribut-Modifikationen, Dauer und Heilbarkeit.

enum ModifikatorTyp {
	GESCHWINDIGKEIT,
	VERLETZUNG,
	BUFF,
	DEBUFF
}

var modifikator_id: String = ""
var name: String = ""
var typ: ModifikatorTyp = ModifikatorTyp.GESCHWINDIGKEIT
var beschreibung: String = ""
var faktor: float = 1.0
var job_einschraenkungen: Array[String] = []
var attribute_modifikation: Dictionary = {}
var dauer_ticks: int = 0
var heilbar: bool = true
var icon_pfad: String = ""

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	modifikator_id = eintrag_id
	name = str(eintrag.get("name", eintrag_id))
	var typ_str := str(eintrag.get("typ", "GESCHWINDIGKEIT"))
	match typ_str:
		"VERLETZUNG":
			typ = ModifikatorTyp.VERLETZUNG
		"BUFF":
			typ = ModifikatorTyp.BUFF
		"DEBUFF":
			typ = ModifikatorTyp.DEBUFF
		_:
			typ = ModifikatorTyp.GESCHWINDIGKEIT
	beschreibung = str(eintrag.get("beschreibung", ""))
	faktor = float(eintrag.get("faktor", 1.0))
	job_einschraenkungen = eintrag.get("job_einschraenkungen", [])
	attribute_modifikation = eintrag.get("attribute_modifikation", {})
	dauer_ticks = int(eintrag.get("dauer_ticks", 0))
	heilbar = bool(eintrag.get("heilbar", true))
	icon_pfad = str(eintrag.get("icon_pfad", ""))

func tick_zaehlen() -> void:
	if dauer_ticks > 0:
		dauer_ticks -= 1