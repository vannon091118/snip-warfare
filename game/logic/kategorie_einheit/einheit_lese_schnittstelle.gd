extends RefCounted
class_name Einheit_LeseSchnittstelle
## Geschlossener Lese-Schnittpunkt: Nur diese Klasse liest Einheiten aus der
## Liste des Managers. Der direkte Zugriff auf die Liste bleibt Interna des
## Managers, und jede Lesefrage hat hier genau eine Antwort.

const OHNE_TREFFER := -1


static func status(einheiten: Array[Dictionary], index: int) -> Einheit_Status:
	if index < 0 or index >= einheiten.size():
		return null
	return einheiten[index]["status"] as Einheit_Status


static func rasse(einheiten: Array[Dictionary], index: int) -> String:
	if index < 0 or index >= einheiten.size():
		return ""
	return str(einheiten[index].get("rasse", ""))


static func hp(einheiten: Array[Dictionary], index: int) -> int:
	## Lebenspunkte fuer die Schwaechsten-Suche; ohne Treffer der neutrale Wert.
	var st := status(einheiten, index)
	return 0 if st == null or st.vital == null else st.vital.hp


static func vital(einheiten: Array[Dictionary], index: int) -> Einheit_VitalStatus:
	var st := status(einheiten, index)
	return null if st == null else st.vital


static func position(einheiten: Array[Dictionary], index: int) -> Vector2:
	if index < 0 or index >= einheiten.size():
		return Vector2.ZERO
	var st := status(einheiten, index)
	if st != null:
		return st.welt_position
	return einheiten[index]["position"]


static func mood(einheiten: Array[Dictionary], index: int) -> Pop_MoodMaschine:
	if index < 0 or index >= einheiten.size():
		return null
	return einheiten[index].get("mood", null) as Pop_MoodMaschine


static func job_id(einheiten: Array[Dictionary], index: int) -> String:
	## Die Kennung des laufenden Jobs; ohne Job ein leerer Text.
	var st := status(einheiten, index)
	if st == null or st.job == null:
		return ""
	return st.job.job_id


static func zahl(einheiten: Array[Dictionary]) -> int:
	return einheiten.size()


static func idle_indizes(einheiten: Array[Dictionary]) -> Array[int]:
	## Alle Einheiten ohne Job: Sie koennen neue Auftraege uebernehmen.
	var gefundene: Array[int] = []
	for idx in einheiten.size():
		if job_id(einheiten, idx) == "":
			gefundene.append(idx)
	return gefundene


static func naechste_bei(einheiten: Array[Dictionary], welt_position: Vector2, radius: float) -> int:
	## Die naechste Einheit innerhalb des Radius; sonst der neutrale Wert.
	var bester := OHNE_TREFFER
	var beste_distanz := radius + 1.0
	for idx in einheiten.size():
		var st := status(einheiten, idx)
		if st == null:
			continue
		var distanz := st.welt_position.distance_to(welt_position)
		if distanz <= radius and distanz < beste_distanz:
			beste_distanz = distanz
			bester = idx
	return bester
