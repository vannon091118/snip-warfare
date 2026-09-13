extends RefCounted
class_name Pop_MoodAbleitung
## Ableitung der Stimmung: Aus den Need-Werten und der Wärme wird genau eine
## Blase. Sie rechnet den Need-Schritt und wählt die stärkste Not; die
## Eskalationskette hat Vorrang vor dem Need-Text. Kein Tick, kein Signal;
## die Maschine übernimmt das Ergebnis und meldet es.

var _waerme: Pop_MoodWaermeGate = null
var _mods: Pop_MoodModifikatorRegistry = null
var _need_registry: Pop_NeedRegistry = null

func einrichten(waerme: Pop_MoodWaermeGate, mods: Pop_MoodModifikatorRegistry, need_registry: Pop_NeedRegistry) -> void:
	_waerme = waerme
	_mods = mods
	_need_registry = need_registry

func schritt(typ: Pop_NeedBasis, vorher: float, verfuegbar: int, raten: Pop_MoodRaten, schema: Pop_RassenSchema) -> float:
	## Ein Need-Schritt: Unter dem Schwellwert steigt die Dringlichkeit, sonst
	## fällt sie. Die Raten kommen ausschließlich aus dem Raten-Rechner.
	if verfuegbar < raten.schwellwert(typ, schema):
		return clampf(vorher + raten.dringlichkeit(typ, schema), 0.0, 1.0)
	return clampf(vorher - raten.abfall(typ, schema), 0.0, 1.0)

func ableiten(werte: Dictionary) -> Pop_Mood:
	if _waerme.gate_mod() != null:
		return _waerme_blase()
	var best_id := ""
	var best_staerke := 0.0
	for need_id: String in werte.keys():
		var staerke := float(werte[need_id])
		if staerke > best_staerke:
			best_staerke = staerke
			best_id = need_id
	if best_staerke < 0.15:
		return Pop_Mood.new()
	var typ: Pop_NeedBasis = _need_registry.typ_fuer(best_id) if _need_registry != null else null
	var neu := Pop_Mood.new()
	neu.aktive_need_id = best_id
	neu.intensitaet = best_staerke
	neu.quelle = "tick"
	# Eskalationskette zuerst: erreicht keine Stufe, bleibt der Need-Text.
	if not Pop_MoodEskalation.uebernehmen(neu, _mods.mod_fuer_need(best_id) if _mods != null else null, best_staerke):
		if typ != null:
			neu.emoji = typ.emoji
			neu.sprechblase_text = typ.sprechblase_text
	return neu

func _waerme_blase() -> Pop_Mood:
	## Die Wärme sticht jede Need-Not: Kälte und Hitze erzählen ihre eigene
	## Blase über die Schwellwerte der Registry.
	var gate_mod := _waerme.gate_mod()
	var g := Pop_Mood.new()
	g.aktive_need_id = gate_mod.need_id
	g.emoji = gate_mod.emoji
	g.sprechblase_text = gate_mod.sprechblase_text
	g.intensitaet = clampf(absf(_waerme.wert()), 0.4, 1.0)
	g.quelle = "waerme"
	Pop_MoodEskalation.uebernehmen(g, gate_mod, _waerme.not_ausmass())
	return g
