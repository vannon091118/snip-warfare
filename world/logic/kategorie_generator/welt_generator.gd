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
	model.karte_erzeugen(model.RASTER_BREITE, model.RASTER_HOEHE, "boden")
	model.welt_seed = seed_wert
	model.region_kante = REGION_KANTE
	_regionen_planen(model, biom_id)
	var kacheln := CHUNK_GROESSE * CHUNK_GROESSE
	for chunk_y in ceili(float(model.raster_hoehe) / float(CHUNK_GROESSE)):
		for chunk_x in ceili(float(model.raster_breite) / float(CHUNK_GROESSE)):
			var region := model.region_an_kachel(chunk_x * CHUNK_GROESSE, chunk_y * CHUNK_GROESSE)
			var region_biom := str(region.get("biom_id", biom_id)) if not region.is_empty() else biom_id
			_chunk_fuellen(model, Vector2i(chunk_x, chunk_y), kacheln, region_biom)
	return true

func _regionen_planen(model: Welt_Model, weltraum_biom: String) -> void:
	# REGION-Ebene: Aus dem Seed deterministisch Biome zu Region-Blöcken ziehen.
	# Die Biom-Liste kommt aus der Gewichte-Registry, damit die Erweiterung
	# weiterhin nur über den Pool läuft; die Basis-Biom-ID ist Fallback.
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
			var ziehung := verteilung.ziehe_eintrag(registry, "biome", weltraum_biom)
			var biom_wahl := weltraum_biom
			if ziehung != "":
				biom_wahl = str(registry.eintrag_wort_fuer(ziehung).get("element_id", ziehung))
			model.region_ergaenzen(region_x, region_y, biom_wahl, verteilung.zufall.naechste_zahl(), CHUNK_GROESSE)
	regionen_geplant = regionen_x * regionen_y

func _chunk_fuellen(model: Welt_Model, chunk: Vector2i, kacheln: int, biom_id: String) -> void:
	# Ein Chunk wird vorsimuliert: Objekte und Tiere werden gezählt, die
	# Boundary-Simulation entscheidet, solange bis die Grenzen gehalten sind.
	var objekt_zahl := 0
	var tier_zahl := 0
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
		var platz_index := verteilung.zufall.naechste_zahl() % plaetze.size()
		var platz: Vector2i = plaetze[platz_index]
		var ziehung := verteilung.ziehe_eintrag(registry, "objekte", biom_id)
		if ziehung != "":
			var welt_pos := Vector2((float(platz.x) + 0.5) * Welt_Model.KACHEL_GROESSE, (float(platz.y) + 0.5) * Welt_Model.KACHEL_GROESSE)
			model.objekt_hinzufuegen(registry.element_pfad_fuer(ziehung), welt_pos)
			objekt_zahl += 1
			plaetze.remove_at(platz_index)
		var tier_ziehung := verteilung.ziehe_eintrag(registry, "tiere", biom_id)
		if tier_ziehung != "":
			var tier_pos := Vector2((float(platz.x) + 0.5) * Welt_Model.KACHEL_GROESSE, (float(platz.y) + 0.5) * Welt_Model.KACHEL_GROESSE)
			model.objekt_hinzufuegen(registry.element_pfad_fuer(tier_ziehung), tier_pos)
			tier_zahl += 1
			plaetze.remove_at(platz_index)
		var pruefung := chunk_pruefer.chunk_pruefen(objekt_zahl, tier_zahl, plaetze.size(), kacheln)
		if bool(pruefung.get("angenommen", false)):
			return
		if versuche >= kacheln * 2:
			# Chunk verworfen: Grenzen unerreichbar, Zähler fürs Protokoll.
			verworfene_chunks += 1
			return
	verworfene_chunks += 1
