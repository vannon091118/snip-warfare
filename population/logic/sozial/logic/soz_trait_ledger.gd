extends RefCounted
class_name Soz_TraitLedger
## Kategorie daten: Traits je Einheit; Festwerte, die mit der Ankunft kommen.
## Kategorie logik: Wirkung auf Gerede, Glauben und Beziehungen nur aus Daten.
## Traits gehören zur Bevölkerung: Jeder neue Bewohner trägt einen Satz davon.

## Kategorie daten: Der geladene Trait-Pool aus sozial_regeln.json.
var _pool: Dictionary = {}
## Kategorie daten: Einheit-Id -> Array[String] Trait-Namen.
var _traits: Dictionary = {}

func einrichten(pool: Dictionary) -> void:
	_pool = pool
	_traits.clear()

func traits_setzen(einheit_id: int, namen: Array) -> void:
	var gueltig: Array = []
	for name in namen:
		if _pool.has(name):
			gueltig.append(name)
	_traits[einheit_id] = gueltig

func traits_von(einheit_id: int) -> Array:
	return _traits.get(einheit_id, []) as Array

## Kategorie logik: Gebündelte Wirkung je Einheit; fehlt ein Trait, bleibt alles neutral.

func wirkung(einheit_id: int) -> Dictionary:
	var summe := {"gerede": 1.0, "glaube": 0.0, "empfaenglichkeit": 1.0, "beziehung": 0.0}
	for name in traits_von(einheit_id):
		var t: Dictionary = _pool.get(name, {})
		summe["gerede"] = summe["gerede"] * float(t.get("gerede_bonus", 1.0))
		summe["glaube"] = summe["glaube"] + float(t.get("glaubens_bonus", 0.0))
		summe["empfaenglichkeit"] = summe["empfaenglichkeit"] * float(t.get("image_empfaenglichkeit", 1.0))
		summe["beziehung"] = summe["beziehung"] + float(t.get("beziehungs_wirkung", 0.0))
	return summe
