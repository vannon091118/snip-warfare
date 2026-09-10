extends RefCounted
class_name Welt_Generator
## Spitze des Generator-Moduls. Er kombiniert die finale Registry (was darf
## existieren), die Verteilungsmaschine (wo zieht der Seed was) und den
## Chunk-Prüfer (welcher Chunk wird angenommen). Er schreibt ausschließlich
## über Welt_Model Mutationen und liefert die fertige Welt als Zustand.
## Neue Objekte, Tiere, Fraktionen oder Biome kommen nur per Registry-Eintrag
## hinzu; dieser Generator ändert sich dabei nicht.
## Welt-Aufbau: WORLD -> REGION -> CHUNK -> OBJECT. Regionen werden aus dem
## Seed geplant (Biom-Makrostruktur), Chunks werden je Region-Biom gefüllt.

const CHUNK_GROESSE := 8
const REGION_KANTE := 4
const DEFINITION_PFAD := "res://world/data/welt_definition.json"

## Kategorie daten: die drei kombinierten Maschinen und das Protokoll.
var registry: Welt_GeneratorRegistry = null
var verteilung: Welt_GeneratorVerteilung = null
var chunk_pruefer: Welt_GeneratorChunkPruefer = null
var verworfene_chunks: int = 0
var regionen_geplant: int = 0

## Kategorie logik: Welt aufbauen aus Seed und Registry.

func _init() -> void:
	registry = Welt_GeneratorRegistry.new()
	verteilung = Welt_GeneratorVerteilung.new()
	chunk_pruefer = Welt_GeneratorChunkPruefer.new()
	chunk_pruefer.einrichten(registry)

func welt_erzeugen(model: Welt_Model, seed_wert: int, biom_id: String) -> bool:
	if model == null or registry == null:
		return false
	verteilung.start_zustand_setzen(seed_wert)
	var def_reg := Welt_DefinitionRegistry.new()
	def_reg.laden()
	var ziel_groesse := def_reg.lokalkarten_groesse_fuer(seed_wert)
	model.karte_erzeugen(ziel_groesse.x, ziel_groesse.y, "boden")
	model.welt_seed = seed_wert
	model.region_kante = REGION_KANTE
	verworfene_chunks = 0
	_regionen_planen(model, biom_id)
	var kacheln := CHUNK_GROESSE * CHUNK_GROESSE
	for chunk_y in ceili(float(model.raster_hoehe) / float(CHUNK_GROESSE)):
		for chunk_x in ceili(float(model.raster_breite) / float(CHUNK_GROESSE)):
			var region := model.region_an_kachel(chunk_x * CHUNK_GROESSE, chunk_y * CHUNK_GROESSE)
			var region_biom := str(region.get("biom_id", biom_id)) if not region.is_empty() else biom_id
			_chunk_fuellen_mit(model, Vector2i(chunk_x, chunk_y), kacheln, region_biom)
	return true

func _regionen_planen(model: Welt_Model, weltraum_biom: String) -> void:
	# REGION-Ebene: Jede Region wird aus einer ortsfesten Ableitung des
	# Welt-Seeds gezogen. Gleiche Welt plus gleiche Region-Koordinate ergibt
	# immer dasselbe Biom und denselben Seed-Beitrag, egal in welcher
	# Reihenfolge Regionen oder Chunks später materialisiert werden.
	model.regionen_leeren()
	model.region_kante = REGION_KANTE
	var biome_pool: Array[String] = [weltraum_biom]
	for eintrag_id: String in registry.ids_mit_gewicht("biome"):
		var wort := registry.eintrag_wort_fuer(eintrag_id)
		var biom_id_aus_pool := str(wort.get("element_id", eintrag_id))
		if not biome_pool.has(biom_id_aus_pool):
			biome_pool.append(biom_id_aus_pool)
	var regionen_x := ceili(float(model.raster_breite) / float(REGION_KANTE))
	var regionen_y := ceili(float(model.raster_hoehe) / float(REGION_KANTE))
	for region_y in regionen_y:
		for region_x in regionen_x:
			var region_id := _region_identitaet(region_x, region_y)
			var region_zufall := Kern_Zufall.abgeleitet_fuer(model.welt_seed, region_id)
			var ziehung := verteilung.ziehe_eintrag_mit(registry, "biome", weltraum_biom, region_zufall)
			var biom_wahl := weltraum_biom
			if ziehung != "":
				biom_wahl = str(registry.eintrag_wort_fuer(ziehung).get("element_id", ziehung))
			model.region_ergaenzen(region_x, region_y, biom_wahl, region_zufall.naechste_zahl(), CHUNK_GROESSE)
	regionen_geplant = regionen_x * regionen_y

func _region_identitaet(region_x: int, region_y: int) -> int:
	# 64-Bit-Mix der Region-Koordinate: innerhalb der signierten 63 Bit,
	# damit er als Kern_Zufall-Start taugt. Kein zweiter RNG.
	var identitaet := ((int(region_x) & 0xFFFF) << 16) | (int(region_y) & 0xFFFF)
	return (identitaet * 0x9E3779B1) & 0x7FFFFFFFFFFFFFFF

func welt_seed() -> int:
	return verteilung.zufall.zufallsstaende[0] if verteilung != null else 0

func region_materialisieren(model: Welt_Model, region_x: int, region_y: int) -> bool:
	# Einzelne Region reproduzierbar erzeugen: Liest ihr Biom, baut nur ihre
	# Chunks aus derselben ortsfesten Ableitung neu. Gleicht der Region aus
	# einer vollständigen Welt.
	var region := _finde_region(model, region_x, region_y)
	if region.is_empty():
		return false
	var biom_wahl := str(region.get("biom_id", "gemaaessigt"))
	var kacheln := CHUNK_GROESSE * CHUNK_GROESSE
	var chunk_pro_region := int(float(REGION_KANTE) / float(CHUNK_GROESSE))
	for dy in chunk_pro_region:
		for dx in chunk_pro_region:
			var chunk := Vector2i(region_x * chunk_pro_region + dx, region_y * chunk_pro_region + dy)
			_chunk_fuellen_mit(model, chunk, kacheln, biom_wahl)
	return true

func chunk_materialisieren(model: Welt_Model, chunk: Vector2i) -> bool:
	var region := model.region_an_kachel(chunk.x * CHUNK_GROESSE, chunk.y * CHUNK_GROESSE)
	var biom_wahl := str(region.get("biom_id", model.biom_id)) if not region.is_empty() else model.biom_id
	var kacheln := CHUNK_GROESSE * CHUNK_GROESSE
	_chunk_fuellen_mit(model, chunk, kacheln, biom_wahl)
	return true

func _finde_region(model: Welt_Model, region_x: int, region_y: int) -> Dictionary:
	for region: Dictionary in model.regionen:
		if int(region.get("region_x", -1)) == region_x and int(region.get("region_y", -1)) == region_y:
			return region
	return {}

func _chunk_fuellen(model: Welt_Model, chunk: Vector2i, kacheln: int, biom_id: String) -> void:
	# Kompatibilität: delegiert an die ortsfeste Ableitung.
	_chunk_fuellen_mit(model, chunk, kacheln, biom_id)

func _chunk_fuellen_mit(model: Welt_Model, chunk: Vector2i, kacheln: int, biom_id: String) -> void:
	# Deterministisch je Chunk: dieselbe Welt plus derselbe Chunk liefert
	# immer dieselben Objekte, unabhängig von der Reihenfolge anderer Chunks.
	var chunk_zufall := Kern_Zufall.abgeleitet_fuer_chunk(model.welt_seed, chunk.x, chunk.y)
	# Merker für den Rückruf: Verwürfe entfernen alles ab diesem Index,
	# damit ein verworfener Chunk keine Geisterobjekte hinterlässt.
	var start_index := model.objekt_anzahl()
	# Cluster zuerst: Sie stempeln dichte Gruppen (Wälder, Steinfields,
	# Tier-Bauten) als Weltzustand; die Streuung danach nutzt den Rest.
	var gestempelt := _cluster_stempeln(model, chunk, biom_id, chunk_zufall)
	var objekt_zahl := int(gestempelt["objekt_zahl"])
	var tier_zahl := int(gestempelt["tier_zahl"])
	var versuche := 0
	var plaetze: Array[Vector2i] = []
	var start_x := chunk.x * CHUNK_GROESSE
	var start_y := chunk.y * CHUNK_GROESSE
	for dy in CHUNK_GROESSE:
		for dx in CHUNK_GROESSE:
			var x := start_x + dx
			var y := start_y + dy
			if x < model.raster_breite and y < model.raster_hoehe:
				plaetze.append(Vector2i(x, y))
	while versuche < kacheln * 3:
		versuche += 1
		if plaetze.is_empty():
			break
		var platz_index := chunk_zufall.naechste_zahl() % plaetze.size()
		var platz: Vector2i = plaetze[platz_index]
		var ziehung := verteilung.ziehe_eintrag_mit(registry, "objekte", biom_id, chunk_zufall)
		if ziehung != "":
			var welt_pos := Vector2((float(platz.x) + 0.5) * Welt_Model.KACHEL_GROESSE, (float(platz.y) + 0.5) * Welt_Model.KACHEL_GROESSE)
			model.objekt_hinzufuegen(registry.element_pfad_fuer(ziehung), welt_pos)
			objekt_zahl += 1
			plaetze.remove_at(platz_index)
			if plaetze.is_empty():
				break
		var tier_ziehung := verteilung.ziehe_eintrag_mit(registry, "tiere", biom_id, chunk_zufall)
		if tier_ziehung != "":
			var tier_pos := Vector2((float(platz.x) + 0.5) * Welt_Model.KACHEL_GROESSE, (float(platz.y) + 0.5) * Welt_Model.KACHEL_GROESSE)
			model.objekt_hinzufuegen(registry.element_pfad_fuer(tier_ziehung), tier_pos)
			tier_zahl += 1
			if not plaetze.is_empty():
				# Tier nutzt denselben Platz-Index wie Objekt-Ziehung nicht doppelt entfernen.
				pass
		var pruefung := chunk_pruefer.chunk_pruefen(objekt_zahl, tier_zahl, plaetze.size(), kacheln)
		if bool(pruefung.get("angenommen", false)):
			return
		if versuche >= kacheln * 2:
			verworfene_chunks += 1
			_chunk_verwerfen(model, start_index)
			return
	verworfene_chunks += 1
	_chunk_verwerfen(model, start_index)


func _chunk_verwerfen(model: Welt_Model, start_index: int) -> void:
	# Ein verworfener Chunk verlässt die Welt nicht: Alle Objekte, die
	# dieser Versuch hinterlassen hat, werden entfernt; der Weltzustand
	# bleibt auf dem Stand vor dem Chunk. Keine Geisterobjekte.
	var letzte := model.objekt_anzahl() - 1
	while letzte >= start_index:
		model.objekt_entfernen(letzte)
		letzte -= 1


## Kategorie logik: Cluster-Stempel für dichte Spawn-Gruppen.

func _cluster_stempeln(model: Welt_Model, chunk: Vector2i, biom_id: String, chunk_zufall: Kern_Zufall) -> Dictionary:
	# Stempelt die Cluster-Definitionen der Registry in den Chunk. Jede
	# Entscheidung (Chance, Mittelpunkt, je Platz) kommt ortsfest aus dem
	# Chunk-Zustand: dieselbe Welt plus derselbe Chunk stempelt dieselben
	# Gruppen, egal welche Reihenfolge. Tiere aus Clustern zählen als
	# Weltobjekte und zugleich zur Tier-Zahl des Chunks.
	var ergebnis := {"objekt_zahl": 0, "tier_zahl": 0}
	var tier_ids := registry.ids_mit_gewicht("tiere")
	for cluster_id: String in registry.ids_der_kategorie("cluster"):
		var wort := registry.eintrag_wort_fuer(cluster_id)
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
		var start_x := chunk.x * CHUNK_GROESSE
		var start_y := chunk.y * CHUNK_GROESSE
		var mitte := Vector2i(
			start_x + int(chunk_zufall.naechste_zahl() % CHUNK_GROESSE),
			start_y + int(chunk_zufall.naechste_zahl() % CHUNK_GROESSE))
		var objekt_ist_tier := tier_ids.any(func(t_id: String) -> bool:
			return registry.element_pfad_fuer(t_id) == element_id)
		for platz in _cluster_plaetze(model, mitte, radius, anzahl, chunk_zufall):
			var welt_pos := Vector2((float(platz.x) + 0.5) * Welt_Model.KACHEL_GROESSE, (float(platz.y) + 0.5) * Welt_Model.KACHEL_GROESSE)
			model.objekt_hinzufuegen(element_id, welt_pos)
			ergebnis["objekt_zahl"] = int(ergebnis["objekt_zahl"]) + 1
			if objekt_ist_tier:
				ergebnis["tier_zahl"] = int(ergebnis["tier_zahl"]) + 1
	return ergebnis

func _cluster_plaetze(model: Welt_Model, mitte: Vector2i, radius: int, anzahl: int, chunk_zufall: Kern_Zufall) -> Array[Vector2i]:
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
