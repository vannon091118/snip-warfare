extends RefCounted
class_name Pop_MoodEskalationStufe
## Datenklasse einer Eskalationsstufe. Jede Stufe eines Modifikators ist
## eine eigene Instanz und trägt ihre Not-Grenze, ihren Emoji-Kopf, den
## Grund, die Wirkung, das Verhalten und die verzahnte Folgestufe.
## Reines Einlesen aus population/data/mood_modifikatoren.json; welche
## Stufe gilt, entscheidet allein die Maschine über stufe_fuer.

var stufe: int = 0
var schwelle: float = 0.0
var emoji: String = "❓"
var grund: String = ""
var wirkung: String = ""
var verhalten: String = ""
var folge_mod_id: String = ""

func aus_eintrag(eintrag: Dictionary) -> void:
	stufe = int(eintrag.get("stufe", 0))
	schwelle = float(eintrag.get("schwelle", 0.0))
	emoji = str(eintrag.get("emoji", "❓"))
	grund = str(eintrag.get("grund", ""))
	wirkung = str(eintrag.get("wirkung", ""))
	verhalten = str(eintrag.get("verhalten", ""))
	folge_mod_id = str(eintrag.get("folge_mod_id", ""))
