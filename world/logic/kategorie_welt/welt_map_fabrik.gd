extends RefCounted
class_name Welt_MapFabrik
## Map-Fabrik: Erzeugt neue Karten über den bestehenden Generator und trägt
## sie in die World ein. Sie ist die einzige Stelle, die eine Expansion zu
## einer neuen spielbaren Karte macht. Sie besitzt keine eigene Zeit, keinen
## eigenen Zufall und keine eigene Registry: Alles delegiert sie an den
## Generator und Kern_Zufall.

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