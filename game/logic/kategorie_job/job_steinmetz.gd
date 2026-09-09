extends Job_Basis
class_name Job_Steinmetz
## Job des Steinmetzen: Steine sind das Job-Objekt, das Ergebnis ist Stein.
## Alle Werte stehen zentral in game/data/job_config.json.

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func _passt_zu_objekt_fallback(element_id: String) -> bool:
	return element_id == "stein" or element_id == "steine_gruppe"
