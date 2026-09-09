extends RefCounted
class_name Pop_Mood
## Reiner Zustand der Stimmung je Einheit. Keine Berechnung;
## die Maschine schreibt, die Denkblase liest.

var aktive_need_id: String = ""
var emoji: String = ""
var sprechblase_text: String = ""
var intensitaet: float = 0.0
var quelle: String = ""

func leer() -> bool:
	return aktive_need_id.is_empty()

func beschriftung(registry: Pop_NeedRegistry) -> String:
	if leer() or registry == null:
		return ""
	var typ := registry.typ_fuer(aktive_need_id)
	if typ == null:
		return sprechblase_text
	return "%s %s" % [emoji, typ.sprechblase_text]
