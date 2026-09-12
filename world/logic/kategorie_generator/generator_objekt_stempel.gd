extends RefCounted
class_name Welt_GeneratorObjektStempel
## Cluster-Stempel-Maschine des Generators: Stempelt die Cluster-Definitionen
## der Registry als dichte Spawn-Gruppen in einen Chunk. Jede Entscheidung
## (Chance, Mittelpunkt, je Platz) kommt ortsfest aus dem Chunk-Zustand:
## dieselbe Welt plus derselbe Chunk stempelt dieselben Gruppen, egal welche
## Reihenfolge. Tiere aus Clustern zählen als Weltobjekte und zugleich zur
## Tier-Zahl des Chunks.

## Kategorie daten: Registry- und Chunk-Referenzen.
var _registry: Welt_GeneratorRegistry = null
var _chunk_groesse: int = 8

## Kategorie logik: Stempeln und Platz-Auswahl.

func einrichten(registry: Welt_GeneratorRegistry, chunk_groesse: int) -> void:
	_registry = registry
	_chunk_groesse = chunk_groesse

func stempeln(model: Welt_Model, chunk: Vector2i, biom_id: String, chunk_zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := {"objekt_zahl": 0, "tier_zahl": 0}
	var tier_ids := _registry.ids_mit_gewicht("tiere")
	for cluster_id: String in _registry.ids_der_kategorie("cluster"):
		var wort := _registry.eintrag_wort_fuer(cluster_id)
		if not (wort.get("biome", []) as Array).has(biom_id):
			continue
		var chance := float(wort.get("chance", 0.0))
		if chance <= 0.0:
			continue
		var wurf := float(chunk_zufall.naechste_zahl() % 1000000) / 1000000.0
		if wurf >= chance:
			continue
		var element_id := str(wort.get("element_id", cluster_id))
		var radius := int(wort.get("radius_kacheln", 2))
		var anzahl := 0
		if bool(wort.get("wandernd", false)):
			# Wandernde Gruppen (Schwärme) ziehen ihre Größe separat:
			# zwischen anzahl_min und anzahl_max, wieder ortsfest.
			var minimum := int(wort.get("anzahl_min", 2))
			var maximum := maxi(int(wort.get("anzahl_max", minimum)), minimum)
			anzahl = minimum + int(chunk_zufall.naechste_zahl() % int(maximum - minimum + 1))
		else:
			anzahl = int(wort.get("anzahl", 0)) + int(wort.get("umgebung_zusatz", 0))
		if anzahl <= 0:
			continue
		var start_x := chunk.x * _chunk_groesse
		var start_y := chunk.y * _chunk_groesse
		var mitte := Vector2i(
			start_x + int(chunk_zufall.naechste_zahl() % _chunk_groesse),
			start_y + int(chunk_zufall.naechste_zahl() % _chunk_groesse))
		var objekt_ist_tier := tier_ids.any(func(t_id: String) -> bool:
			return _registry.element_pfad_fuer(t_id) == element_id)
		for platz in _plaetze(model, mitte, radius, anzahl, chunk_zufall):
			model.objekt_hinzufuegen(element_id, _kachel_mitte(model, platz))
			ergebnis["objekt_zahl"] = int(ergebnis["objekt_zahl"]) + 1
			if objekt_ist_tier:
				ergebnis["tier_zahl"] = int(ergebnis["tier_zahl"]) + 1
	return ergebnis

func _plaetze(model: Welt_Model, mitte: Vector2i, radius: int, anzahl: int, chunk_zufall: Kern_Zufall) -> Array[Vector2i]:
	# Liefert bis zu anzahl freie Felder im Ring um die Mitte: Der nächste
	# freie Ring gewinnt, die Reihenfolge innerhalb entscheidet der
	# Chunk-Zustand, damit Cluster nicht als perfektes Quadrat stehen.
	var plaetze: Array[Vector2i] = []
	if anzahl <= 0:
		return plaetze
	var kandidaten: Array[Vector2i] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var feld := mitte + Vector2i(dx, dy)
			if feld.x < 0 or feld.y < 0 or feld.x >= model.raster_breite or feld.y >= model.raster_hoehe:
				continue
			kandidaten.append(feld)
	while not kandidaten.is_empty() and plaetze.size() < anzahl:
		var index := int(chunk_zufall.naechste_zahl() % kandidaten.size())
		plaetze.append(kandidaten[index])
		kandidaten.remove_at(index)
	return plaetze

func _kachel_mitte(model: Welt_Model, kachel: Vector2i) -> Vector2:
	# Kachelmitte in Weltkoordinaten aus der einen Kachelgroesse des Modells.
	var kante := float(model.kachel_groesse)
	return Vector2((float(kachel.x) + 0.5) * kante, (float(kachel.y) + 0.5) * kante)
