extends RefCounted
class_name Pop_MoodModifikator
## Datenklasse eines Mood-Modifikators. Eigene Klasse je Progression-Gate.
## Hält Schwellen, Sprechblase und HP-Folge. Keine Logik ausser Lesen.

var mod_id: String = ""
var need_id: String = ""
var emoji: String = ""
var sprechblase_text: String = ""
var schwellwert: float = 0.0
var hp_abzug_je_tick: int = 0
var verhalten: String = ""

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	mod_id = eintrag_id
	need_id = str(eintrag.get("need_id", "waerme"))
	emoji = str(eintrag.get("emoji", "❓"))
	sprechblase_text = str(eintrag.get("sprechblase_text", mod_id))
	schwellwert = float(eintrag.get("schwellwert", 0.0))
	hp_abzug_je_tick = int(eintrag.get("hp_abzug_je_tick", 0))
	verhalten = str(eintrag.get("verhalten", ""))
