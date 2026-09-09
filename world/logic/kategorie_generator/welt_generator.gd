extends RefCounted
class_name Welt_Generator
## Spitze des Generator-Moduls. Er kombiniert die finale Registry (was darf
## existieren), die Verteilungsmaschine (wo zieht der Seed was) und den
## Chunk-Prüfer (welcher Chunk wird angenommen). Er schreibt ausschließlich
## über Welt_Model Mutationen und liefert die fertige Welt als Zustand.
## Neue Objekte, Tiere, Fraktionen oder Biome kommen nur per Registry-Eintrag
## hinzu; dieser Generator ändert sich dabei nicht.

const CHUNK_GROESSE := 8

## Kategorie daten: die drei kombinierten Maschinen und das Protokoll.
var registry: Welt_GeneratorRegistry = null
var verteilung: Welt_GeneratorVerteilung = null
var chunk_pruefer: Welt_GeneratorChunkPruefer = null
var verworfene_chunks: int = 0

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
	var kacheln := CHUNK_GROESSE * CHUNK_GROESSE
	for chunk_y in ceili(float(model.raster_hoehe) / float(CHUNK_GROESSE)):
		for chunk_x in ceili(float(model.raster_breite) / float(CHUNK_GROESSE)):
			_chunk_fuellen(model, Vector2i(chunk_x, chunk_y), kacheln, biom_id)
	return true

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
