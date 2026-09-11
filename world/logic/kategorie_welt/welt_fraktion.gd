extends RefCounted
class_name Welt_Fraktion
## Datenklasse einer Fraktion auf der World Map.
## Hält Identität, Vorlieben, Farbe und Position im Makro-Netzwerk der Welt.
## Enthält keine Simulationslogik; reines Einlesen aus generator_gewichte.json.

## Kategorie daten: Eigenschaften der Fraktion und Netzwerk-Knoten.
var fraktion_id: String = ""
var angezeigter_name: String = ""
var beschreibung: String = ""
var bevorzugte_biome: Array[String] = []
var farbe: Color = Color.WHITE
var position_kachel: Vector2i = Vector2i.ZERO
var nachbarn: Array[String] = []

## Kategorie logik: Einlesen aus Konfigurationseintrag und Wörterbuch-Konvertierung.

func aus_konfig_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	fraktion_id = eintrag_id
	angezeigter_name = str(eintrag.get("name", eintrag_id.capitalize()))
	beschreibung = str(eintrag.get("beschreibung", ""))
	bevorzugte_biome.clear()
	var biome_roh: Variant = eintrag.get("biome", [])
	if typeof(biome_roh) == TYPE_ARRAY:
		for b: Variant in biome_roh as Array:
			bevorzugte_biome.append(str(b))
	var farb_str := str(eintrag.get("farbe", "#FFFFFF"))
	farbe = Color.from_string(farb_str, Color.WHITE)

func nach_woerterbuch() -> Dictionary:
	return {
		"fraktion_id": fraktion_id,
		"name": angezeigter_name,
		"beschreibung": beschreibung,
		"bevorzugte_biome": bevorzugte_biome,
		"farbe": farbe.to_html(),
		"position_kachel": [position_kachel.x, position_kachel.y],
		"nachbarn": nachbarn,
	}

func aus_woerterbuch(daten: Dictionary) -> void:
	fraktion_id = str(daten.get("fraktion_id", ""))
	angezeigter_name = str(daten.get("name", fraktion_id))
	beschreibung = str(daten.get("beschreibung", ""))
	bevorzugte_biome.clear()
	var biome_roh: Variant = daten.get("bevorzugte_biome", [])
	if typeof(biome_roh) == TYPE_ARRAY:
		for b: Variant in biome_roh as Array:
			bevorzugte_biome.append(str(b))
	farbe = Color.from_string(str(daten.get("farbe", "#FFFFFF")), Color.WHITE)
	var pos_roh: Variant = daten.get("position_kachel", [0, 0])
	if typeof(pos_roh) == TYPE_ARRAY and (pos_roh as Array).size() >= 2:
		position_kachel = Vector2i(int((pos_roh as Array)[0]), int((pos_roh as Array)[1]))
	nachbarn.clear()
	var nachbarn_roh: Variant = daten.get("nachbarn", [])
	if typeof(nachbarn_roh) == TYPE_ARRAY:
		for n: Variant in nachbarn_roh as Array:
			nachbarn.append(str(n))
