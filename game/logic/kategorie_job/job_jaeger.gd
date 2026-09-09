extends Job_Basis
class_name Job_Jaeger
## Job des Jägers: erlegte Tiere sind das Job-Objekt, das Ergebnis ist Fleisch.
## Der Ertrag und die Lebenspunkte des Tieres stehen in tier_verhalten.json,
## die Arbeitswerte des Jobs in game/data/job_config.json.

func ziel_typ() -> ZielTyp:
	return ZielTyp.TIER

func _passt_zu_objekt_fallback(_element_id: String) -> bool:
	return false

func _passt_zu_tier_fallback(tier_id: String) -> bool:
	return tier_id == "baer" or tier_id == "hase" or tier_id == "vogel" or tier_id == "vogelgruppe"
