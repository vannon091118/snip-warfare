extends RefCounted
class_name Welt_MakroGenerator
## Makrokarte der Startauswahl. Genau eine Verantwortung: Die Landschaften der
## Weltkarte planen. Sie zieht je Region ein Biom aus den Gewichten und sonst
## nichts; sie materialisiert keine Chunks, keine Objekte und keine Tiere und
## ruft niemals den lokalen Generator. Damit ist die Weltkarte sofort da, ihre
## Größe steht in world/data/weltkarte_definition.json, und die lokale Karte
## bleibt die einzige Stelle mit Inhalt.
## Gleiche Eingabe liefert immer dieselbe Makrokarte.

const KARTE_PFAD := "res://world/data/weltkarte_definition.json"

## Kategorie daten: geladene Makro-Definition und die Verteilungsmaschine.
var definition: Dictionary = {}
var _verteilung := Welt_GeneratorVerteilung.new()

## Kategorie logik: Definition laden und Karte planen.

func laden() -> bool:
	if not FileAccess.file_exists(KARTE_PFAD):
		push_warning("Makrokarte-Definition fehlt: %s" % KARTE_PFAD)
		return false
	var datei := FileAccess.open(KARTE_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) != TYPE_DICTIONARY:
		push_warning("Makrokarte-Definition ungültiges JSON: %s" % KARTE_PFAD)
		return false
	definition = daten
	return true

func regionen_groesse() -> Vector2i:
	if definition.is_empty():
		laden()
	var wort: Dictionary = definition.get("regionen", {"breite": 16, "hoehe": 12})
	return Vector2i(maxi(int(wort.get("breite", 16)), 2), maxi(int(wort.get("hoehe", 12)), 2))

func region_kante() -> int:
	if definition.is_empty():
		laden()
	return maxi(int(definition.get("region_kante_kacheln", 8)), 1)

func start_biom() -> String:
	if definition.is_empty():
		laden()
	return str(definition.get("start_biom", "gemaaessigt"))

func karte_planen(model: Welt_Model, registry: Welt_GeneratorRegistry, seed_wert: int) -> bool:
	if model == null or registry == null:
		return false
	if definition.is_empty() and not laden():
		return false
	var regionen := regionen_groesse()
	var kante := region_kante()
	# Das Modell trägt nur das Makro-Raster: Regionen plus ihre Koordinaten.
	# Die Rastergröße ist Region mal Kante, damit die Regionsmathematik der
	# Beobachter unverändert bleibt.
	model.karte_erzeugen(regionen.x * kante, regionen.y * kante, "boden")
	model.welt_seed = seed_wert
	model.region_kante = kante
	model.regionen_leeren()
	_verteilung.start_zustand_setzen(seed_wert)
	var start_biom_id := start_biom()
	for region_y in regionen.y:
		for region_x in regionen.x:
			var region_zufall := Kern_Zufall.abgeleitet_fuer(seed_wert, _region_identitaet(region_x, region_y))
			# Ebene leer heißt: Alle Landschaften sind erlaubt, auch Gebirge
			# und Ozean. Genau darin unterscheidet sich die Makrokarte von
			# der lokalen Karte.
			var ziehung := _verteilung.ziehe_eintrag_mit(registry, "biome", start_biom_id, region_zufall)
			var biom_wahl := start_biom_id
			if ziehung != "":
				biom_wahl = str(registry.eintrag_wort_fuer(ziehung).get("element_id", ziehung))
			model.region_ergaenzen(region_x, region_y, biom_wahl, region_zufall.naechste_zahl(), kante)
	return true

func _region_identitaet(region_x: int, region_y: int) -> int:
	# Eigener Mix für die Makroebene: Die Region der Weltkarte zieht unabhängig
	# von der gleichnamigen Region der lokalen Karte. Kein zweiter RNG.
	var identitaet := ((int(region_x) & 0xFFFF) << 16) | (int(region_y) & 0xFFFF)
	return (identitaet * 0x85EBCA6B) & 0x7FFFFFFFFFFFFFFF
