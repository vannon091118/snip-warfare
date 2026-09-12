extends RefCounted
class_name Welt_FraktionsGenerator
## Fraktions_Generator: Verbindet Keimpunkte mit Welt_Fraktion und NetzwerkPlaner.
## Läuft NACH dem Fraktions_Keimling_Analysator und Rassen_Generator.
## Erzeugt Welt_Fraktion-Instanzen aus jedem Keimpunkt (ERSATZ für statische Einträge in generator_gewichte.json).
## Verwendet deterministische Namen via Pop_NamensGenerator.
## Registriert generierte Fraktionen im NetzwerkPlaner für Wege/Nachbarn-Berechnung.
## KEINE feste Fraktionen-Zahl - Weltstruktur (Keimpunkte) bestimmt die Anzahl.

## Kategorie daten: Referenzen auf Generator-Komponenten.
var keimling_analysator: Welt_FraktionsKeimlingAnalysator = null
var rassen_generator: Pop_RassenGenerator = null
var netzwerk_planer: Welt_NetzwerkPlaner = null
var generator_registry: Welt_GeneratorRegistry = null

## Archetyp zu Farb-Mapping
const ARCHETYP_FARBEN: Dictionary = {
	"wald": Color("#2E7D32"),
	"berg": Color("#5D4037"),
	"wasser": Color("#0277BD"),
	"steppe": Color("#E65100"),
	"tundra": Color("#546E7A")
}

## Archetyp zu Biom-Vorliebe
const ARCHETYP_BIOME: Dictionary = {
	"wald": ["gemaaessigt", "wald"],
	"berg": ["gebirge", "tundra"],
	"wasser": ["ozean", "wasser", "see"],
	"steppe": ["steppe", "gemaaessigt"],
	"tundra": ["tundra", "gebirge"]
}

func _init() -> void:
	pass

func einrichten(p_keimling: Welt_FraktionsKeimlingAnalysator, p_rassen_gen: Pop_RassenGenerator, p_netzwerk: Welt_NetzwerkPlaner, p_registry: Welt_GeneratorRegistry) -> void:
	keimling_analysator = p_keimling
	rassen_generator = p_rassen_gen
	netzwerk_planer = p_netzwerk
	generator_registry = p_registry

func fraktionen_aus_keimpunkten_erzeugen(welt_model: Welt_Model, welt_seed: int) -> Array[Welt_Fraktion]:
	## 1. Keimpunkte vom Analysator holen
	if keimling_analysator == null:
		push_error("FraktionsGenerator: Keimling_Analysator nicht eingerichtet")
		return []
	var keimpunkte := keimling_analysator.get_keimpunkte()
	if keimpunkte.is_empty():
		push_warning("FraktionsGenerator: Keine Keimpunkte gefunden - keine Fraktionen erzeugt")
		return []

	## 2. Rassen für Keimpunkte generieren (füllt Registry)
	if rassen_generator != null:
		rassen_generator.generiere_aus_keimpunkten(keimpunkte, welt_seed)

	## 3. Welt_Fraktion-Instanzen aus Keimpunkten erzeugen
	var generierte_fraktionen: Array[Welt_Fraktion] = []
	for keimpunkt in keimpunkte:
		var fraktion := _keimpunkt_zu_fraktion(keimpunkt, welt_seed, welt_model)
		if fraktion != null:
			generierte_fraktionen.append(fraktion)

	## 4. In NetzwerkPlaner einspeisen (ersetzt statische Registry-IDs)
	if netzwerk_planer != null and not generierte_fraktionen.is_empty():
		_netzwerk_mit_generierten_fuellen(welt_model, generierte_fraktionen)

	return generierte_fraktionen

func _keimpunkt_zu_fraktion(keimpunkt: Dictionary, welt_seed: int, welt_model: Welt_Model) -> Welt_Fraktion:
	var archetyp := str(keimpunkt.get("dominante_archetyp", "wald"))
	var keimpunkt_id := str(keimpunkt.get("zellen_id", ""))

	## Deterministischer Name für die Fraktion
	var fraktions_name := Pop_NamensGenerator.generiere_fraktions_name(archetyp, keimpunkt_id, welt_seed)

	## Eindeutige Fraktions-ID
	var fraktion_id := "fraktion_%s_%s" % [archetyp, keimpunkt_id]

	## Welt_Fraktion erstellen und befüllen
	var fraktion := Welt_Fraktion.new()
	fraktion.fraktion_id = fraktion_id
	fraktion.angezeigter_name = fraktions_name
	fraktion.beschreibung = _generiere_beschreibung(archetyp, keimpunkt)
	fraktion.bevorzugte_biome = ARCHETYP_BIOME.get(archetyp, ["gemaaessigt"])
	fraktion.farbe = ARCHETYP_FARBEN.get(archetyp, Color.WHITE)
	fraktion.position_kachel = _welt_pos_zu_kachel(keimpunkt.position, welt_model)
	fraktion.nachbarn = []  # Wird vom NetzwerkPlaner befüllt

	## Zusatzdaten für KI-Config speichern
	fraktion._keimpunkt_daten = keimpunkt.duplicate(true)
	fraktion._archetyp = archetyp

	return fraktion

func _generiere_beschreibung(archetyp: String, keimpunkt: Dictionary) -> String:
	var score: Dictionary = keimpunkt.get("score", {})
	var gesamt := float(keimpunkt.get("gesamt_score", 0.0))
	var dom := str(keimpunkt.get("dominante_archetyp", "wald"))

	var beschreibungen := {
		"wald": "Ein vom Wald geprägtes Volk, das im Einklang mit der Natur lebt. Ihre Siedlungen wachsen organisch zwischen den Bäumen.",
		"berg": "Ein zähes Bergvolk, das in den tiefen Hallen unter den Gipfeln haust. Meister der Steinbearbeitung und Erzförderung.",
		"wasser": "Ein Volk der Flüsse und Seen, dessen Leben sich um das Wasser dreht. Fischer, Händler und Seefahrer.",
		"steppe": "Reiter der weiten Ebenen, schnell und ausdauernd. Ihre Herden ziehen mit den Jahreszeiten.",
		"tundra": "Überlebenskünstler der ewigen Kälte, widerstandsfähig gegen Frost und Schnee. Jäger der großen Herden."
	}

	var basis: String = str(beschreibungen.get(archetyp, "Eine Fraktion unbekannter Herkunft."))
	var score_text := "Dominanz: %s (Score: %.2f)" % [dom, gesamt]
	return "%s %s" % [basis, score_text]

func _welt_pos_zu_kachel(pos: Vector2, welt_model: Welt_Model) -> Vector2i:
	var kachel_x := int(pos.x / welt_model.kachel_groesse)
	var kachel_y := int(pos.y / welt_model.kachel_groesse)
	return Vector2i(clampi(kachel_x, 0, welt_model.raster_breite - 1), clampi(kachel_y, 0, welt_model.raster_hoehe - 1))

func _netzwerk_mit_generierten_fuellen(welt_model: Welt_Model, fraktionen: Array[Welt_Fraktion]) -> void:
	## NetzwerkPlaner öffentliche API nutzen für Integration
	if netzwerk_planer == null:
		push_error("NetzwerkPlaner nicht verfügbar")
		return

	## Wege mit generierten Fraktionen berechnen
	netzwerk_planer._wege_berechnen_mit_fraktionen(welt_model, fraktionen)

func get_generierte_fraktions_ids() -> Array[String]:
	var ids: Array[String] = []
	if keimling_analysator != null:
		for kp in keimling_analysator.get_keimpunkte():
			ids.append("fraktion_%s_%s" % [kp.dominante_archetyp, kp.zellen_id])
	return ids