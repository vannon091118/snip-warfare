extends RefCounted
class_name Pop_Mood
## Reiner Zustand der Stimmung je Einheit. Keine Berechnung;
## die Maschine schreibt, die Denkblase liest. Seit den Eskalationsketten
## trägt die Mood neben Emoji und Kurzzeile auch Grund und Wirkung der
## erreichten Stufe sowie die Kette, aus der sie stammt.

var aktive_need_id: String = ""
var emoji: String = ""
var sprechblase_text: String = ""
var intensitaet: float = 0.0
var quelle: String = ""
var grund: String = ""
var wirkung: String = ""
var verhalten: String = ""
var stufe: int = 0
var kette: String = ""
var folge_mod_id: String = ""

func leer() -> bool:
	return aktive_need_id.is_empty()

func beschriftung(registry: Pop_NeedRegistry) -> String:
	if leer() or registry == null:
		return ""
	var typ := registry.typ_fuer(aktive_need_id)
	if typ == null:
		return sprechblase_text
	return "%s %s" % [emoji, typ.sprechblase_text]

func erzaehlung() -> String:
	# Grund und Wirkung im Emoji-Stil: Die erste Zeile sagt, warum der
	# Stickman so schaut, die zweite, was er gleich tun will. Ohne Kette
	# bleibt es bei der alten kurzen Sprechblase.
	if grund.is_empty() and wirkung.is_empty():
		return "%s %s" % [emoji, sprechblase_text]
	if wirkung.is_empty():
		return "%s %s" % [emoji, grund]
	if grund.is_empty():
		return "%s %s" % [emoji, wirkung]
	return "%s %s\n%s" % [emoji, grund, wirkung]
