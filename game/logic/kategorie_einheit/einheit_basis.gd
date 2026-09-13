extends Node2D
class_name Einheit_Basis
## Bestand der Einheiten-Domäne: Diese Basis hält die Einheiten-Liste und den
## geschlossenen Lese-Schnittpunkt. Nur hier wird die Liste gelesen, und jede
## Lesefrage hat genau eine Antwort. Der Manager erbt den Bestand und trägt
## darüber Maschinen, Takt und Aufbau.

## Kategorie daten: Einheiten-Liste mit Status, Darsteller und Position.
var _einheiten: Array[Dictionary] = []

## Kategorie logik: Der geschlossene Lese-Schnittpunkt der Domäne.
func einheit_zahl() -> int:
	return Einheit_LeseSchnittstelle.zahl(_einheiten)


func idle_einheiten() -> Array[int]:
	# Alle Einheiten ohne laufenden Job koennen neue Auftraege uebernehmen.
	return Einheit_LeseSchnittstelle.idle_indizes(_einheiten)


func einheit_bei(welt_position: Vector2, radius: float) -> int:
	## Linksklick-Einheitenwahl: Die naechste Einheit im Radius, sonst -1.
	return Einheit_LeseSchnittstelle.naechste_bei(_einheiten, welt_position, radius)


func einheit_status(index: int) -> Einheit_Status:
	return Einheit_LeseSchnittstelle.status(_einheiten, index)


func einheit_rasse(index: int) -> String:
	return Einheit_LeseSchnittstelle.rasse(_einheiten, index)


func einheit_hp(index: int) -> int:
	return Einheit_LeseSchnittstelle.hp(_einheiten, index)


func einheit_vital(index: int) -> Einheit_VitalStatus:
	return Einheit_LeseSchnittstelle.vital(_einheiten, index)


func einheit_position(index: int) -> Vector2:
	return Einheit_LeseSchnittstelle.position(_einheiten, index)


func einheit_mood(index: int) -> Pop_MoodMaschine:
	return Einheit_LeseSchnittstelle.mood(_einheiten, index)


func job_id_einheit(einheit_index: int) -> String:
	return Einheit_LeseSchnittstelle.job_id(_einheiten, einheit_index)
