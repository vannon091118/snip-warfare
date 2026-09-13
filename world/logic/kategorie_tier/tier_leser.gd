extends RefCounted
class_name Tier_Leser
## Lesesaal der Tier-Einträge: Jede Frage nach Zahl, Index, Status, Art,
## Position oder Faktor hat genau eine Antwort, und keine davon verändert die
## Liste. Stabile Tier-Nummern sind der einzige Griff auf einen Eintrag.

static func zahl(tiere: Array[Dictionary]) -> int:
	return tiere.size()

static func index_fuer(tiere: Array[Dictionary], tier_nummer: int) -> int:
	for index in tiere.size():
		if tiere[index]["id"] == tier_nummer:
			return index
	return -1

static func status_fuer(tiere: Array[Dictionary], tier_nummer: int) -> Tier_Status:
	var index := index_fuer(tiere, tier_nummer)
	if index < 0:
		return null
	return tiere[index]["status"]

static func art(tiere: Array[Dictionary], tier_nummer: int) -> String:
	for tier: Dictionary in tiere:
		if tier["id"] == tier_nummer:
			return str(tier["tier_id"])
	return ""

static func position(tiere: Array[Dictionary], tier_nummer: int) -> Vector2:
	# Ungültige Nummern liefern Vector2.INF, damit Aufrufer ihr Ziel prüfen.
	for tier: Dictionary in tiere:
		if tier["id"] == tier_nummer:
			return tier["position"]
	return Vector2.INF

static func effektiver_faktor(tiere: Array[Dictionary], verhalten: Tier_Registry, tier_nummer: int) -> float:
	## G1-Leser: Eigenfaktor mal Logik-Basisfaktor; unbekannt bleibt neutral.
	var daten := verhalten.tier_daten(art(tiere, tier_nummer))
	return 1.0 if daten == null else daten.effektiver_faktor()

static func id_bei(tiere: Array[Dictionary], verhalten: Tier_Registry, ziel: Vector2, radius: float) -> int:
	# Nummer des Tieres nahe dem Punkt, sonst -1; fliehende Vögel kreisen hoch
	# über dem Boden, der Trefferbereich wächst mit der Körpergröße.
	var bester_id := -1
	var bester_abstand := INF
	for tier: Dictionary in tiere:
		var groesse := verhalten.frame_groesse(str(tier["tier_id"]))
		var mitte: Vector2 = tier["position"] + Vector2(0, -groesse.y / 2.0)
		var abstand := mitte.distance_to(ziel)
		if abstand <= radius + groesse.y * 0.6 and abstand < bester_abstand:
			bester_abstand = abstand
			bester_id = tier["id"]
	return bester_id

static func bestand(tiere: Array[Dictionary]) -> Array[Dictionary]:
	## Geschlossener Leser: Kopie, damit niemand die Interna mutiert.
	var kopie: Array[Dictionary] = []
	for tier: Dictionary in tiere:
		kopie.append({
			"id": tier.get("id", -1),
			"tier_id": str(tier.get("tier_id", "")),
			"position": tier.get("position", Vector2.ZERO),
		})
	return kopie
