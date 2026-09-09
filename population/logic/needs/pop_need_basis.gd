extends RefCounted
class_name Pop_NeedBasis
## Datenklasse eines Bedürfnisses. Reines Einlesen aus needs.json.
## Jede Need hat eine eigene Klasse; Logik liegt in der Maschine.

var need_id: String = ""
var need_name: String = ""
var beschreibung: String = ""
var ressource: String = ""
var schwellwert: int = 0
var dringlichkeit_pro_tick: float = 0.02
var abfall_pro_tick: float = 0.04
var icon_pfad: String = ""
var emoji: String = "❓"
var sprechblase_text: String = ""
var farbe: String = "#FFFFFF"

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	need_id = str(eintrag.get("id", ""))
	need_name = str(eintrag.get("name", need_id))
	beschreibung = str(eintrag.get("beschreibung", ""))
	ressource = str(eintrag.get("ressource", ""))
	schwellwert = int(eintrag.get("schwellwert", 0))
	dringlichkeit_pro_tick = float(eintrag.get("dringlichkeit_pro_tick", 0.02))
	abfall_pro_tick = float(eintrag.get("abfall_pro_tick", 0.04))
	icon_pfad = str(eintrag.get("icon_pfad", ""))
	emoji = str(eintrag.get("emoji", "❓"))
	sprechblase_text = str(eintrag.get("sprechblase_text", need_name))
	farbe = str(eintrag.get("farbe", "#FFFFFF"))
