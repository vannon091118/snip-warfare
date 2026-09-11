extends RefCounted
class_name Pop_MoodModifikator
## Datenklasse eines Mood-Modifikators. Eigene Klasse je Progression-Gate.
## Hält Schwellen, Sprechblase, HP-Folge und die Eskalationskette.
## Keine Logik ausser Lesen; welche Stufe gilt, fragt die Maschine ab.

## Kategorie daten: Identität und die getypte Kette aus dem Pool.
var mod_id: String = ""
var need_id: String = ""
var emoji: String = ""
var sprechblase_text: String = ""
var schwellwert: float = 0.0
var hp_abzug_je_tick: int = 0
var verhalten: String = ""
var eskalation: Array[Pop_MoodEskalationStufe] = []

## Kategorie logik: Laden und Stufenwahl über die Kette.

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	mod_id = eintrag_id
	need_id = str(eintrag.get("need_id", "waerme"))
	emoji = str(eintrag.get("emoji", "❓"))
	sprechblase_text = str(eintrag.get("sprechblase_text", mod_id))
	schwellwert = float(eintrag.get("schwellwert", 0.0))
	hp_abzug_je_tick = int(eintrag.get("hp_abzug_je_tick", 0))
	verhalten = str(eintrag.get("verhalten", ""))
	_eskalation_lesen(eintrag.get("eskalation", []))

func _eskalation_lesen(roh: Variant) -> void:
	eskalation.clear()
	if typeof(roh) != TYPE_ARRAY:
		return
	for stufen_eintrag: Variant in roh as Array:
		if typeof(stufen_eintrag) != TYPE_DICTIONARY:
			continue
		var stufe := Pop_MoodEskalationStufe.new()
		stufe.aus_eintrag(stufen_eintrag as Dictionary)
		eskalation.append(stufe)

func hat_eskalation() -> bool:
	return not eskalation.is_empty()

func stufe_fuer(staerke: float) -> Pop_MoodEskalationStufe:
	# Höchste Stufe, deren Schwelle die Stärke schon erreicht. Die Kette
	# steigt lückenlos, deshalb bricht die Suche beim ersten Nicht-Erreichen
	# ab; unterhalb der ersten Schwelle gilt die erste Stufe.
	if eskalation.is_empty():
		return null
	var gewaehlt: Pop_MoodEskalationStufe = eskalation[0]
	for stufe in eskalation:
		if staerke >= stufe.schwelle:
			gewaehlt = stufe
		else:
			break
	return gewaehlt
