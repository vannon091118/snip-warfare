extends RefCounted
class_name Welt_MapFabrik
## Map-Fabrik: Erzeugt neue Karten über den bestehenden Generator und trägt
## sie in die World ein. Sie ist die einzige Stelle, die eine Expansion zu
## einer neuen spielbaren Karte macht. Sie besitzt keine eigene Zeit, keinen
## eigenen Zufall und keine eigene Registry: Alles delegiert sie an den
## Generator und Kern_Zufall.
##
## Z-Layer Erweiterung: Stellt lazy chunk_materialisieren für Untergrund-Ebenen
## (z < 0) bereit. Die Generierung erfolgt on-demand beim ersten Zugriff.

## Kategorie daten: die zwei benötigten Zuständigkeiten.
var _generator: Welt_Generator = null

## Kategorie logik: Karten erzeugen und eintragen.

func einrichten(generator: Welt_Generator) -> void:
	_generator = generator

func karte_erzeugen(world: Welt_World, map_id: String, seed_wert: int, biom_id: String, als_basis: bool) -> Welt_Model:
	if _generator == null or world == null:
		return null
	if map_id.strip_edges() == "" or world.map_id_vorhanden(map_id):
		return null
	var neue_karte := Welt_Model.new()
	if not _generator.welt_erzeugen(neue_karte, seed_wert, biom_id):
		return null
	if not world.map_hinzufuegen(neue_karte, map_id, als_basis):
		return null
	return neue_karte

func basis_karte_erzeugen(world: Welt_World, seed_wert: int, biom_id: String) -> Welt_Model:
	# Die erste Karte einer neuen World ist immer die Basis-Karte.
	return karte_erzeugen(world, "karte_0", seed_wert, biom_id, true)

func neue_karte_erzeugen(world: Welt_World, map_id: String, biom_id: String) -> Welt_Model:
	# Expansion: Eine neue Karte wird deterministisch aus dem World-Bestand
	# abgeleitet (kein Zeit-Seed), in die World eingetragen und als neue
	# Basis markiert, damit die Sitzung auf sie zeigt.
	if world == null:
		return null
	var ableitung := Kern_Zufall.abgeleitet_fuer(
		int(hash(world.world_name) & 0x7FFFFFFF), world.map_zahl() + 1)
	var seed_wert := int(ableitung.naechste_zahl() % 1000000000)
	if seed_wert == 0:
		seed_wert = 13371337
	var kandidat_zufall := Kern_Zufall.new()
	kandidat_zufall.start_zustand_setzen(seed_wert)
	for _versuch in range(20):
		var probe := Welt_Model.new()
		if _generator.welt_erzeugen(probe, seed_wert, biom_id) and _generator.verworfene_chunks == 0:
			break
		seed_wert = kandidat_zufall.naechste_zahl() % 1000000000
	var neue_karte := karte_erzeugen(world, map_id, seed_wert, biom_id, true)
	if neue_karte != null:
		world.basis_setzen(map_id)
	return neue_karte

## Z-Layer: Lazy Chunk-Materialisierung für Untergrund-Ebenen
func z_chunk_materialisieren(model: Welt_Model, chunk: Vector2i, z_ebene: int) -> bool:
	# Materialisiert einen einzelnen Chunk auf der angegebenen Z-Ebene.
	# Wird on-demand gerufen, wenn der Spieler in einen noch nicht generierten
	# Untergrund-Chunk gräbt oder Wasser hineinfliest.
	if _generator == null or model == null:
		return false
	if z_ebene >= 0:
		# Oberfläche (z=0) ist bereits bei Welt-Erzeugung generiert
		return true
	if z_ebene < -Welt_Model.MAX_Z_EBENEN + 1:
		return false
	model.z_ebene_setzen(z_ebene)
	return _generator.chunk_materialisieren(model, chunk, z_ebene)

func z_region_materialisieren(model: Welt_Model, region_x: int, region_y: int, z_ebene: int) -> bool:
	# Materialisiert eine gesamte Region auf der angegebenen Z-Ebene.
	if _generator == null or model == null:
		return false
	if z_ebene >= 0:
		return true
	if z_ebene < -Welt_Model.MAX_Z_EBENEN + 1:
		return false
	model.z_ebene_setzen(z_ebene)
	return _generator.region_materialisieren(model, region_x, region_y, z_ebene)

func z_ebene_erzeugen(model: Welt_Model, z_ebene: int, biom_id: String) -> bool:
	# Erzeugt eine komplette Z-Ebene (alle Chunks) - für Debug/Testing.
	# Im Normalfall wird lazy per Chunk generiert.
	if _generator == null or model == null:
		return false
	if z_ebene >= 0 or z_ebene < -Welt_Model.MAX_Z_EBENEN + 1:
		return false
	model.z_ebene_setzen(z_ebene)
	var kacheln := _generator._chunk_groesse * _generator._chunk_groesse
	for chunk_y in ceili(float(model.raster_hoehe) / float(_generator._chunk_groesse)):
		for chunk_x in ceili(float(model.raster_breite) / float(_generator._chunk_groesse)):
			var region := model.region_an_kachel(chunk_x * _generator._chunk_groesse, chunk_y * _generator._chunk_groesse)
			var region_biom := str(region.get("biom_id", biom_id)) if not region.is_empty() else biom_id
			_generator._chunk_fuellen_mit(model, Vector2i(chunk_x, chunk_y), kacheln, region_biom, z_ebene)
	return true
