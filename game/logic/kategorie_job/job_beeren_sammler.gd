extends Job_Basis
class_name Job_BeerenSammler
## Job des Beerensammlers: Büsche sind das Zielobjekt, das Ergebnis sind Beeren.
## Alle Werte stehen zentral in game/data/job_config.json.

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func _passt_zu_objekt_fallback(element_id: String) -> bool:
	return element_id == "busch"
