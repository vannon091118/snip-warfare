extends Job_Basis
class_name Job_HolzfaellerStumpf
## Job des Holzfällers am Baumstumpf: Stümpfe sind das Job-Objekt,
## das Ergebnis ist Holz. Alle Werte stehen zentral in game/data/job_config.json.

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func passt_zu_objekt(element_id: String) -> bool:
	return element_id == "baum_stumpf"
