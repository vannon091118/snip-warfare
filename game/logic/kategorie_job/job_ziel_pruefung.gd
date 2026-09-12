extends RefCounted
class_name Job_ZielPruefung
## Prueft, ob ein Ziel zu einem Job passt. Steht eine Ziel-Liste in den Daten,
## entscheidet sie; sonst fragt die Pruefung den Job selbst, damit Unterklassen
## ihr eigenes Ziel weiterhin ueber die Basis melden koennen.


static func passt_objekt(ziel_objekte: Array[String], element_id: String, job: Job_Basis) -> bool:
	if not ziel_objekte.is_empty():
		return ziel_objekte.has(element_id)
	return job._passt_zu_objekt_fallback(element_id)


static func passt_tier(ziel_tiere: Array[String], tier_id: String, job: Job_Basis) -> bool:
	if not ziel_tiere.is_empty():
		return ziel_tiere.has(tier_id)
	return job._passt_zu_tier_fallback(tier_id)
