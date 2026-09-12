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
## Groessen (Kachel, Chunk, Region) kommen ausschliesslich aus
## world/data/welt_definition.json ueber Welt_DefinitionRegistry.
## FRAKTIONEN: Werden NICHT aus Registry geladen, sondern dynamisch aus
## Keimpunkten (Fraktions_Keimling_Analysator) als letzter Generator-Pass erzeugt.

## RUECKFALL-Werte, falls der Datenpool nicht ladbar ist (Testlaeufe ohne
## Dateisystem): Im Spiel ueberschreibt _definitionen_uebernehmen beide.
const CHUNK_GROESSE := 8
const REGION_KANTE := 4
const DEFINITION_PFAD := "res://world/data/welt_definition.json"
const _GewaesserSkript := preload("res://world/logic/kategorie_generator/generator_gewaesser.gd")
const _FelsmassiveSkript := preload("res://world/logic/kategorie_generator/generator_felsmassive.gd")
const _KeimlingSkript = preload("res://world/logic/kategorie_generator/fraktions_keimling_analysator.gd")
const _FraktionsGenSkript = preload("res://world/logic/kategorie_generator/welt_fraktions_generator.gd")
const _RassenGenSkript := preload("res://population/logic/needs/pop_rassen_generator.gd")

## Kategorie daten: die kombinierten Maschinen und das Protokoll.
var registry: Welt_GeneratorRegistry = null
var verteilung: Welt_GeneratorVerteilung = null
var chunk_pruefer: Welt_GeneratorChunkPruefer = null
var gewaesser: RefCounted = null
var felsmassive: RefCounted = null
var keimling_analysator: Welt_FraktionsKeimlingAnalysator = null
var fraktions_generator: Welt_FraktionsGenerator = null
var rassen_generator: Pop_RassenGenerator = null
var netzwerk_planer: Welt_NetzwerkPlaner = null
var verworfene_chunks: int = 0
var regionen_geplant: int = 0
## Cluster-Stempel und Fliesen-Wahl als eigene Maschinen; der Generator
## reicht nur den Chunk-Zustand durch.
var stempel := Welt_GeneratorObjektStempel.new()
var fliesen_wahl := Welt_GeneratorFliesenWahl.new()
var _chunk_groesse: int = CHUNK_GROESSE
var _region_kante: int = REGION_KANTE
var _def_reg: Welt_DefinitionRegistry = null
## FastNoiseLite-Instanzen für 2D-Weltgenerierung:hoehe, feuchte, temperatur.
## Jede wird deterministisch via Kern_Zufall abgeleitet; nie direkte Randomisierung.
## Alle drei aktivieren domain_warp und lesen die Amplitude aus der Konfiguration.
var height_noise: FastNoiseLite = FastNoiseLite.new()
var moisture_noise: FastNoiseLite = FastNoiseLite.new()
var temperature_noise: FastNoiseLite = FastNoiseLite.new()

## Kategorie logik: Welt aufbauen aus Seed und Registry.

func _init() -> void:
	registry = Welt_GeneratorRegistry.new()
	verteilung = Welt_GeneratorVerteilung.new()
	chunk_pruefer = Welt_GeneratorChunkPruefer.new()
	chunk_pruefer.einrichten(registry)
	gewaesser = _GewaesserSkript.new()
	felsmassive = _FelsmassiveSkript.new()
	keimling_analysator = _KeimlingSkript.new()
	fraktions_generator = _FraktionsGenSkript.new()
	rassen_generator = _RassenGenSkript.new()
	netzwerk_planer = Welt_NetzwerkPlaner.new()
	_def_reg = Welt_DefinitionRegistry.new()
	_def_reg.laden()

	## FraktionsGenerator mit allen Abhängigkeiten verbinden
	fraktions_generator.einrichten(keimling_analysator, rassen_generator, netzwerk_planer, registry)

func rassen_registry_setzen(registry_inst: Pop_RassenSchemaRegistry) -> void:
	rassen_generator.registry_setzen(registry_inst)

func init_fast_noise(seed_wert: int, generator_gewichte: Dictionary) -> void:
	# Deterministische Seed-Ableitung für jede Noise-Instanz via Kern_Zufall.
	# Pattern: Kern_Zufall.abgeleitet_fuer("hoehe", welt_seed) etc.
	# Das zweite Parameter ist ein integer-Identifikator für die Noise-Art.
	var height_id := int(Kern_Hash.wort("hoehe") & 0x7FFFFFFFFFFFFFFF)
	var moisture_id := int(Kern_Hash.wort("feuchte") & 0x7FFFFFFFFFFFFFFF)
	var temperature_id := int(Kern_Hash.wort("temperatur") & 0x7FFFFFFFFFFFFFFF)

	var height_kern := Kern_Zufall.abgeleitet_fuer(seed_wert, height_id)
	var moisture_kern := Kern_Zufall.abgeleitet_fuer(seed_wert, moisture_id)
	var temperature_kern := Kern_Zufall.abgeleitet_fuer(seed_wert, temperature_id)

	# Nutze die erste generierte Zahl jeder Folge als FastNoiseLite Seed.
	height_noise.seed = height_kern.naechste_zahl()
	moisture_noise.seed = moisture_kern.naechste_zahl()
	temperature_noise.seed = temperature_kern.naechste_zahl()

	# Domain Warp aktivieren und Amplitude aus Konfiguration lesen.
	var domain_warp_amplitude := 1.0
	if generator_gewichte.has("domain_warp_amplitude"):
		domain_warp_amplitude = generator_gewichte["domain_warp_amplitude"]

	height_noise.domain_warp_enabled = true
	height_noise.domain_warp_amplitude = domain_warp_amplitude

	moisture_noise.domain_warp_enabled = true
	moisture_noise.domain_warp_amplitude = domain_warp_amplitude

	temperature_noise.domain_warp_enabled = true
	temperature_noise.domain_warp_amplitude = domain_warp_amplitude

func get_noise_2d(x: int, y: int, noise_type: String) -> float:
	# Gebe einen normalisierten Noise-Wert (-1 bis 1) für die gegebene Tile-Position zurück.
	match noise_type:
		"height":
			return height_noise.get_noise_2d(x, y)
		"moisture":
			return moisture_noise.get_noise_2d(x, y)
		"temperature":
			return temperature_noise.get_noise_2d(x, y)
		_:
			return 0.0

func generate_noise_map(breite: int, hoehe: int, noise_type: String) -> Array[float]:
	# Erzeuge ein flaches Array mit Noise-Werten für jede Kachel der gegebenen Größe.
	var map_array: Array[float] = []
	for y in range(hoehe):
		for x in range(breite):
			map_array.append(get_noise_2d(x, y, noise_type))
	return map_array

func get_biom_from_noise(height_value: float, moisture_value: float, temperature_value: float) -> String:
	# Einfache Biom-Zuordnung basierend auf den drei Noise-Werten.
	# Dies kann später durch die biome.json-Thresholds ersetzt werden.
	var height_norm := clampf(height_value, -1.0, 1.0)
	var moisture_norm := clampf(moisture_value, -1.0, 1.0)
	var temperature_norm := clampf(temperature_value, -1.0, 1.0)

	# Height-basierte Biome: Berge bei hoher Höhe, Täler unten
	if height_norm > 0.7:
		return "gebirge"
	elif height_norm < -0.3:
		# Feuchtes/Temperatur entscheiden für Ozean vs. Land
		if moisture_norm < -0.5:
			return "ozean"
		elif temperature_norm < -0.5:
			return "tundra"
		else:
			return "steppe"
	else:
		# Gemäßigte Zone: Kombination aus Feuchtigkeit und Temperatur
		if moisture_norm > 0.5 and temperature_norm > -0.5:
			return "gemaaessigt"  # Wald/Grün
		elif moisture_norm < -0.3:
			return "steppe"  # Trocken
		elif temperature_norm < -0.5:
			return "tundra"  # Kalt
		else:
			return "gemaaessigt"  # Standard

func _definitionen_uebernehmen(model: Welt_Model) -> void:
	# Einziger Ort, der die Weltgroessen aus dem Datenpool in das Modell
	# schreibt: Kachel, Chunk und Region haben damit genau eine Quelle.
	if _def_reg == null:
		_def_reg = Welt_DefinitionRegistry.new()
		_def_reg.laden()
	_chunk_groesse = maxi(_def_reg.chunk_groesse(), 1)
	stempel.einrichten(registry, _chunk_groesse)
	_region_kante = maxi(_def_reg.region_kante(), 1)
	if model != null:
		model.kachel_groesse_setzen(_def_reg.kachel_groesse())
		model.chunk_groesse_setzen(_chunk_groesse)
		model.region_kante = _region_kante

func welt_erzeugen(model: Welt_Model, seed_wert: int, biom_id: String, z_ebene: int = 0) -> bool:
	if model == null or registry == null:
		return false
	verteilung.start_zustand_setzen(seed_wert)
	_definitionen_uebernehmen(model)
	var ziel_groesse := _def_reg.lokalkarten_groesse_fuer(seed_wert)
	model.karte_erzeugen(ziel_groesse.x, ziel_groesse.y, "boden")
	model.aktive_z_ebene = z_ebene
	model.welt_seed = seed_wert
	verworfene_chunks = 0
	_regionen_planen(model, biom_id)
	var kacheln := _chunk_groesse * _chunk_groesse
	for chunk_y in ceili(float(model.raster_hoehe) / float(_chunk_groesse)):
		for chunk_x in ceili(float(model.raster_breite) / float(_chunk_groesse)):
			var region := model.region_an_kachel(chunk_x * _chunk_groesse, chunk_y * _chunk_groesse)
			var region_biom := str(region.get("biom_id", biom_id)) if not region.is_empty() else biom_id
			_chunk_fuellen_mit(model, Vector2i(chunk_x, chunk_y), kacheln, region_biom, z_ebene)
	var landschaft_zufall := Kern_Zufall.abgeleitet_fuer(seed_wert, 0x5EED1A9D)
	if gewaesser != null:
		gewaesser.erzeugen(model, biom_id, landschaft_zufall, z_ebene)
	if felsmassive != null:
		felsmassive.erzeugen(model, biom_id, landschaft_zufall, z_ebene)

	## LETZTER GENERATOR-PASS: Fraktionen aus Keimpunkten erzeugen
	## Dies ersetzt die statischen Fraktionen-Einträge in generator_gewichte.json
	_fraktionen_generieren(model, seed_wert)

	return true

func _fraktionen_generieren(model: Welt_Model, seed_wert: int) -> void:
	## 1. Fraktions_Keimling_Analysator: Welt analysieren, Keimpunkte finden
	if keimling_analysator != null:
		## Lade fraktions_ki_config.json für Schwellenwert
		var ki_config_pfad := "res://world/data/fraktions_ki_config.json"
		var ki_config := {}
		if FileAccess.file_exists(ki_config_pfad):
			var text := FileAccess.open(ki_config_pfad, FileAccess.READ).get_as_text()
			ki_config = JSON.parse_string(text)
		else:
			push_warning("fraktions_ki_config.json nicht gefunden, nutze Standardwerte")
			ki_config = {"keimling_schwellenwert": 0.35, "archetyp_gewichtung": {}}

		keimling_analysator.analyse_ausfuehren(model, ki_config)

	## 2. FraktionsGenerator: Fraktionen aus Keimpunkten erzeugen und in NetzwerkPlaner einspeisen
	if fraktions_generator != null:
		fraktions_generator.fraktionen_aus_keimpunkten_erzeugen(model, seed_wert)

	## 3. NetzwerkPlaner ist nun mit generierten Fraktionen befüllt und Wege berechnet
	## Die Fraktionen sind über netzwerk_planer.fraktionen() abrufbar

func _regionen_planen(model: Welt_Model, weltraum_biom: String) -> void:
	# REGION-Ebene: Jede Region wird aus einer ortsfesten Ableitung des
	# Welt-Seeds gezogen. Gleiche Welt plus gleiche Region-Koordinate ergibt
	# immer dasselbe Biom und denselben Seed-Beitrag, egal in welcher
	# Reihenfolge Regionen oder Chunks später materialisiert werden.
	model.regionen_leeren()
	model.region_kante = _region_kante
	# Nur lokale Biome: Gebirge und Ozean sind Makro-Landschaften und werden
	# hier nie gezogen, sonst stünde mitten im Spielgebiet eine unbewohnbare
	# Barriere ohne Inhalt.
	var biome_pool: Array[String] = [weltraum_biom]
	for eintrag_id: String in registry.ids_mit_gewicht("biome"):
		var wort := registry.eintrag_wort_fuer(eintrag_id)
		if str(wort.get("ebene", "lokal")) != "lokal":
			continue
		var biom_id_aus_pool := str(wort.get("element_id", eintrag_id))
		if not biome_pool.has(biom_id_aus_pool):
			biome_pool.append(biom_id_aus_pool)
	var regionen_x := ceili(float(model.raster_breite) / float(_region_kante))
	var regionen_y := ceili(float(model.raster_hoehe) / float(_region_kante))
	for region_y in regionen_y:
		for region_x in regionen_x:
			var region_id := _region_identitaet(region_x, region_y)
			var region_zufall := Kern_Zufall.abgeleitet_fuer(model.welt_seed, region_id)
			var ziehung := verteilung.ziehe_eintrag_mit(registry, "biome", weltraum_biom, region_zufall, "lokal")
			var biom_wahl := weltraum_biom
			if ziehung != "":
				biom_wahl = str(registry.eintrag_wort_fuer(ziehung).get("element_id", ziehung))
			model.region_ergaenzen(region_x, region_y, biom_wahl, region_zufall.naechste_zahl(), _chunk_groesse)
	regionen_geplant = regionen_x * regionen_y

func _region_identitaet(region_x: int, region_y: int) -> int:
	# 64-Bit-Mix der Region-Koordinate: innerhalb der signierten 63 Bit,
	# damit er als Kern_Zufall-Start taugt. Kein zweiter RNG.
	var identitaet := ((int(region_x) & 0xFFFF) << 16) | (int(region_y) & 0xFFFF)
	return (identitaet * 0x9E3779B1) & 0x7FFFFFFFFFFFFFFF

func welt_seed() -> int:
	return verteilung.zufall.zufallsstaende[0] if verteilung != null else 0

func region_materialisieren(model: Welt_Model, region_x: int, region_y: int, z_ebene: int = 0) -> bool:
	# Einzelne Region reproduzierbar erzeugen: Liest ihr Biom, baut nur ihre
	# Chunks aus derselben ortsfesten Ableitung neu. Gleicht der Region aus
	# einer vollständigen Welt.
	_definitionen_uebernehmen(model)
	var region := _finde_region(model, region_x, region_y)
	if region.is_empty():
		return false
	var biom_wahl := str(region.get("biom_id", "gemaaessigt"))
	var kacheln := _chunk_groesse * _chunk_groesse
	var chunk_pro_region := int(float(_region_kante) / float(_chunk_groesse))
	for dy in chunk_pro_region:
		for dx in chunk_pro_region:
			var chunk := Vector2i(region_x * chunk_pro_region + dx, region_y * chunk_pro_region + dy)
			_chunk_fuellen_mit(model, chunk, kacheln, biom_wahl, z_ebene)
	return true

func chunk_materialisieren(model: Welt_Model, chunk: Vector2i, z_ebene: int = 0) -> bool:
	_definitionen_uebernehmen(model)
	var region := model.region_an_kachel(chunk.x * _chunk_groesse, chunk.y * _chunk_groesse)
	var biom_wahl := str(region.get("biom_id", model.biom_id)) if not region.is_empty() else model.biom_id
	var kacheln := _chunk_groesse * _chunk_groesse
	_chunk_fuellen_mit(model, chunk, kacheln, biom_wahl, z_ebene)
	return true

func _finde_region(model: Welt_Model, region_x: int, region_y: int) -> Dictionary:
	for region: Dictionary in model.regionen:
		if int(region.get("region_x", -1)) == region_x and int(region.get("region_y", -1)) == region_y:
			return region
	return {}

func _chunk_fuellen(model: Welt_Model, chunk: Vector2i, kacheln: int, biom_id: String, z_ebene: int = 0) -> void:
	# Kompatibilität: delegiert an die ortsfeste Ableitung.
	_chunk_fuellen_mit(model, chunk, kacheln, biom_id, z_ebene)

func _chunk_fuellen_mit(model: Welt_Model, chunk: Vector2i, kacheln: int, biom_id: String, z_ebene: int = 0) -> void:
	# Deterministisch je Chunk: dieselbe Welt plus derselbe Chunk liefert
	# immer dieselben Objekte, unabhängig von der Reihenfolge anderer Chunks.
	var chunk_zufall := Kern_Zufall.abgeleitet_fuer_chunk(model.welt_seed, chunk.x, chunk.y)
	# Merker für den Rückruf: Verwürfe entfernen alles ab diesem Index,
	# damit ein verworfener Chunk keine Geisterobjekte hinterlässt.
	var start_index := model.objekt_anzahl()
	# Cluster zuerst: Sie stempeln dichte Gruppen (Wälder, Steinfields,
	# Tier-Bauten) als Weltzustand; die Streuung danach nutzt den Rest.
	var gestempelt := stempel.stempeln(model, chunk, biom_id, chunk_zufall)
	var objekt_zahl := int(gestempelt["objekt_zahl"])
	var tier_zahl := int(gestempelt["tier_zahl"])
	var versuche := 0
	var plaetze: Array[Vector2i] = []
	var start_x := chunk.x * _chunk_groesse
	var start_y := chunk.y * _chunk_groesse
	for dy in _chunk_groesse:
			for dx in _chunk_groesse:
				var x := start_x + dx
				var y := start_y + dy
				if x < model.raster_breite and y < model.raster_hoehe:
					plaetze.append(Vector2i(x, y))
					model.fliese_setzen(x, y, fliesen_wahl.ziehe_fliese(biom_id, chunk_zufall, z_ebene), z_ebene)
	# Nach Fliesen-Setzen: Tile-Leben für Fels/Geröll initialisieren
	_tile_leben_initialisieren_chunk(model, chunk, z_ebene)
	while versuche < kacheln * 3:
		versuche += 1
		if plaetze.is_empty():
			break
		var platz_index := chunk_zufall.naechste_zahl() % plaetze.size()
		var platz: Vector2i = plaetze[platz_index]
		var ziehung := verteilung.ziehe_eintrag_mit(registry, "objekte", biom_id, chunk_zufall)
		if ziehung != "":
			var welt_pos := _kachel_mitte(model, platz)
			model.objekt_hinzufuegen(registry.element_pfad_fuer(ziehung), welt_pos)
			objekt_zahl += 1
			plaetze.remove_at(platz_index)
			if plaetze.is_empty():
				break
		var tier_ziehung := verteilung.ziehe_eintrag_mit(registry, "tiere", biom_id, chunk_zufall)
		if tier_ziehung != "":
			var tier_pos := _kachel_mitte(model, platz)
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

func _tile_leben_initialisieren_chunk(model: Welt_Model, chunk: Vector2i, z_ebene: int) -> void:
	# Initialisiert Tile-Leben für alle Fels/Geröll Tiles im Chunk
	var start_x := chunk.x * _chunk_groesse
	var start_y := chunk.y * _chunk_groesse
	var lokale_registry := Welt_Registry.new()
	for dy in _chunk_groesse:
		for dx in _chunk_groesse:
			var x := start_x + dx
			var y := start_y + dy
			if x < model.raster_breite and y < model.raster_hoehe:
				var tile_id := model.fliese(x, y, z_ebene)
				if tile_id == "fels" or tile_id == "geroell":
					var kachel_eintrag := lokale_registry.finde_objekt(tile_id)
					var max_leben := 100
					if kachel_eintrag != null and kachel_eintrag.schluessel_daten.has("leben"):
						max_leben = int(kachel_eintrag.schluessel_daten["leben"])
					model.tile_leben_initialisieren(x, y, z_ebene, max_leben)

func _kachel_mitte(model: Welt_Model, kachel: Vector2i) -> Vector2:
	# Kachelmitte in Weltkoordinaten aus der einen Kachelgroesse des Modells.
	var kante := float(model.kachel_groesse)
	return Vector2((float(kachel.x) + 0.5) * kante, (float(kachel.y) + 0.5) * kante)

func _chunk_verwerfen(model: Welt_Model, start_index: int) -> void:
	# Ein verworfener Chunk verlässt die Welt nicht: Alle Objekte, die
	# dieser Versuch hinterlassen hat, werden entfernt; der Weltzustand
	# bleibt auf dem Stand vor dem Chunk. Keine Geisterobjekte.
	var letzte := model.objekt_anzahl() - 1
	while letzte >= start_index:
		model.objekt_entfernen(letzte)
		letzte -= 1
