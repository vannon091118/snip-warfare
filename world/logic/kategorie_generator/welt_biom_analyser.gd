extends RefCounted
class_name Welt_BiomAnalyser
## Analysiert drei Noise-Werte (height, moisture, temperature) pro Tile
## und leitet daraus einen biom_id nach den Schwellenwerten der Biome.
## Erkenntnis: gleiche Struktur, separates Dictionary — wie biom_raster/raster im Welt_Model.
## Dieses Klasse ist verantwortlich fur die Zuordnung von Noise zu Biome,
## nicht fur die Speicherung in der Welt (die uebernimmt Welt_Model).
## Schwellenwerte werden aus biome.json geladen; Fallback auf Konstante.

## Kategorie daten: Geladene Schwellenwerte pro Biom aus biome.json.
var _schwellenwerte: Dictionary = {}

const BIOME_PFAD := "res://world/data/biome.json"

## Fallback-Schwellenwerte (0.0 bis 1.0 normalisiert), falls JSON nicht ladbar.
## RUECKFALL: Im Spiel gilt biome.json als einzige Quelle.
const SCHWELLE_OZEAN_HEIGHT := 0.15  # RUECKFALL
const SCHWELLE_GEBIRGE_HEIGHT := 0.6  # RUECKFALL
const SCHWELLE_TUNDRA_TEMPERATUR := 0.3  # RUECKFALL
const SCHWELLE_STEPPE_FEUCHT := 0.3  # RUECKFALL

func _init() -> void:
	_schwellenwerte_laden()

func _schwellenwerte_laden() -> void:
	# Lade Schwellenwerte aus biome.json unter "thresholds" pro Biom.
	# Struktur erwartet: thresholds: { "ozean": {"height_max": 0.15}, ... }
	var datei := FileAccess.open(BIOME_PFAD, FileAccess.READ)
	if datei == null:
		push_warning("Biome-JSON nicht gefunden: %s, nutze Fallback-Werte" % BIOME_PFAD)
		_schwellenwerte = _fallback_schwellenwerte()
		return
	var text := datei.get_as_text()
	datei.close()
	var daten: Variant = JSON.parse_string(text)
	if typeof(daten) != TYPE_DICTIONARY:
		push_warning("Biome-JSON hat ungueltiges Format, nutze Fallback-Werte")
		_schwellenwerte = _fallback_schwellenwerte()
		return
	var thresholds: Variant = (daten as Dictionary).get("thresholds", {})
	if typeof(thresholds) == TYPE_DICTIONARY:
		_schwellenwerte = thresholds as Dictionary
	else:
		push_warning("Keine thresholds in biome.json, nutze Fallback-Werte")
		_schwellenwerte = _fallback_schwellenwerte()

func _fallback_schwellenwerte() -> Dictionary:
	# Fallback als Dictionary, damit der Zugriffscode identisch bleibt.
	return {
		"ozean": {"height_max": SCHWELLE_OZEAN_HEIGHT},
		"gebirge": {"height_min": SCHWELLE_GEBIRGE_HEIGHT},
		"tundra": {"temperature_max": SCHWELLE_TUNDRA_TEMPERATUR},
		"steppe": {"moisture_max": SCHWELLE_STEPPE_FEUCHT, "height_min": SCHWELLE_OZEAN_HEIGHT, "height_max": SCHWELLE_GEBIRGE_HEIGHT},
		"gemaaessigt": {}
	}

## Haubtanalyse: gibt biom_id zuruck basierend auf height, moisture, temperature
func analysiere_biom(height: float, moisture: float, temperature: float) -> String:
	# Noise-Werte liegen in [-1, 1], normalisieren auf [0, 1] fuer Schwellenwerte.
	var h_norm := (height + 1.0) * 0.5  # RUECKFALL
	var m_norm := (moisture + 1.0) * 0.5  # RUECKFALL
	var t_norm := (temperature + 1.0) * 0.5  # RUECKFALL

	# 1. Ozean: sehr niedrige Hoehe (Meereshohle)
	var ozean_max := float(_schwellenwerte.get("ozean", {}).get("height_max", SCHWELLE_OZEAN_HEIGHT))
	if h_norm < ozean_max:
		return "ozean"

	# 2. Gebirge: sehr hohe Hoehe (Berge)
	var gebirge_min := float(_schwellenwerte.get("gebirge", {}).get("height_min", SCHWELLE_GEBIRGE_HEIGHT))
	if h_norm > gebirge_min:
		return "gebirge"

	# 3. Tundra: kalte Temperatur
	var tundra_max := float(_schwellenwerte.get("tundra", {}).get("temperature_max", SCHWELLE_TUNDRA_TEMPERATUR))
	if t_norm < tundra_max:
		return "tundra"

	# 4. Steppe: niedrige Feuchte (trocken) bei mittlerer Hoehe
	var steppe_conf: Dictionary = _schwellenwerte.get("steppe", {})
	var steppe_moisture_max := float(steppe_conf.get("moisture_max", SCHWELLE_STEPPE_FEUCHT))
	var steppe_height_min := float(steppe_conf.get("height_min", SCHWELLE_OZEAN_HEIGHT))
	var steppe_height_max := float(steppe_conf.get("height_max", SCHWELLE_GEBIRGE_HEIGHT))
	if m_norm < steppe_moisture_max and h_norm > steppe_height_min and h_norm < steppe_height_max:
		return "steppe"

	# 5. Gemäßigt: Standardfall (alles andere)
	return "gemaaessigt"

## Hilfsfunktion: pruft, ob ein Tile biomechnisch barrierefrei ist
func hat_barriere(biom_id: String) -> bool:
	var biome_eintrag := find_biom_eintrag(biom_id)
	if biome_eintrag == null:
		return false
	return biome_eintrag.has("barriere")

func find_biom_eintrag(biom_id: String) -> Dictionary:
	# Lade biome.json einmal und suche den Eintrag (RUECKFALL-Lesung, wenn die
	# Biom-Registry nicht erreichbar ist).
	var biome_pfad := "res://world/data/biome.json"
	var biome_daten: Variant = {}
	var datei := FileAccess.open(biome_pfad, FileAccess.READ)
	if datei == null:
		push_warning("Biome-JSON konnte nicht geladen werden: %s" % biome_pfad)
		return {}
	biome_daten = JSON.parse_string(datei.get_as_text())
	datei.close()
	if typeof(biome_daten) != TYPE_DICTIONARY:
		return {}
	for eintrag: Dictionary in biome_daten.get("biome", []):
		if str(eintrag.get("id", "")) == biom_id:
			return eintrag
	return {}

## Konvertiert Koordinaten zu Dictionary-Key format ("x:y:z")
func key_fuer_kachel(x: int, y: int, z: int = 0) -> String:
	return "%d:%d:%d" % [x, y, z]

## Analysiert eine einzelne Kachel und gibt biom_id zuruck
func biom_fuer_kachel(height: float, moisture: float, temperature: float) -> String:
	return analysiere_biom(height, moisture, temperature)
