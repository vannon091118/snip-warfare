extends Job_Basis
class_name Job_Heiler
## Job des Heilers: Er arbeitet an verletzten Einheiten und heilt ihre
## Modifikatoren; es gibt keine Ernte. Alle Werte stehen zentral in
## game/data/job_config.json.

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func passt_zu_objekt(_element_id: String) -> bool:
	# Der Heiler erntet nichts; sein Einsatzziel wird später über die
	# Einheiten-Domäne gewählt, nicht über den Element-Katalog.
	return false
