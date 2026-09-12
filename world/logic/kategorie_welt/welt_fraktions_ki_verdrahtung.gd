extends RefCounted
class_name Welt_FraktionsKiVerdrahtung
## Verdrahtungs-Spitze der Fraktions-KI-Domäne: Lädt die Konfiguration, plant
## das Fraktions-Netzwerk, analysiert Keimpunkte, generiert Rassen-Schemata
## und baut je Fraktion eine KI-Maschine, die an der Weltuhr tickt. Die Welt-
## Szene hängt nur diese Spitze an und reicht die Domänen-Referenzen hinein;
## keine Fachlogik bleibt mehr in der Szene.

const KI_CONFIG_PFAD := "res://world/data/fraktions_ki_config.json"
const RASSEN_VORLAGEN_PFAD := "res://population/data/rassen_schemata.json"
const STANDARD_CONFIG := {"expansion": 0.6, "handel": 0.4, "konflikt": 0.7, "aggressions_basis": 1.0}

## Kategorie daten: KI-Maschinen und Konfiguration als Domänen-Zustand.
var _fraktions_ki_config: Dictionary = {}
var _ki_maschinen: Array[Welt_FraktionsKiMaschine] = []
var _netzwerk_planer := Welt_NetzwerkPlaner.new()

## Kategorie logik: Aufbau der Fraktions-KI aus den gereichten Referenzen.

func initialisieren(p: Dictionary) -> void:
	## Fraktions-KI initialisieren: Netzwerk planen und KI-Maschinen pro Fraktion starten.
	var model: Welt_Model = p.get("model")
	var biome: Welt_BiomRegistry = p.get("biome")
	var rassen_registry: Pop_RassenSchemaRegistry = p.get("rassen_registry")
	var map_fabrik: Welt_MapFabrik = p.get("map_fabrik")
	var lager: Lager_Manager = p.get("lager")
	_fraktions_ki_config_laden()
	if not _netzwerk_planer.netzwerk_planen(model, Welt_GeneratorRegistry.new(), 0, biome):
		push_warning("Fraktions-Netzwerk konnte nicht geplant werden")
		return
	# Rassen-Schemata für jede Fraktion generieren (aus Keimpunkten)
	var keimling_analysator := Welt_FraktionsKeimlingAnalysator.new()
	keimling_analysator.analyse_ausfuehren(model, _fraktions_ki_config)
	var keimpunkte := keimling_analysator.get_keimpunkte()
	# Rassen-Generator für Keimpunkte
	var rassen_generator := Pop_RassenGenerator.new()
	rassen_generator.registry_setzen(rassen_registry)
	rassen_generator.generiere_aus_keimpunkten(keimpunkte, model.welt_seed)
	for fraktion in _netzwerk_planer.fraktionen():
		var rassen_id := str(fraktion.fraktion_id)  # Vereinfacht: Fraktion-ID als Rassen-ID
		var rassen_schema := _rassen_schema_fuer(rassen_id, rassen_registry)
		var ki := Welt_FraktionsKiMaschine.new()
		ki.einrichten(fraktion, model, WeltSitzung.world, map_fabrik, lager, rassen_schema, _fraktions_ki_config)
		_ki_maschinen.append(ki)
	_weltuhr_verbinden()

func maschinen() -> Array[Welt_FraktionsKiMaschine]:
	return _ki_maschinen

func config() -> Dictionary:
	return _fraktions_ki_config

func modell_aktualisieren(neues_modell: Welt_Model) -> void:
	## Bei Kartenwechsel (Expansion) die KI-Maschinen auf das neue Modell umstellen.
	for ki in _ki_maschinen:
		ki.modell_aktualisieren(neues_modell)

func _fraktions_ki_config_laden() -> void:
	if FileAccess.file_exists(KI_CONFIG_PFAD):
		var text := FileAccess.open(KI_CONFIG_PFAD, FileAccess.READ).get_as_text()
		_fraktions_ki_config = JSON.parse_string(text) as Dictionary
	else:
		push_warning("fraktions_ki_config.json nicht gefunden, nutze Standardwerte")
		_fraktions_ki_config = STANDARD_CONFIG.duplicate()

func _rassen_schema_fuer(rassen_id: String, rassen_registry: Pop_RassenSchemaRegistry) -> Pop_RassenSchema:
	var rassen_schema: Pop_RassenSchema = rassen_registry.schema_fuer(rassen_id)
	if rassen_schema != null:
		return rassen_schema
	# Fallback: Mensch-Schema aus rassen_schemata.json
	var schema := Pop_RassenSchema.new()
	if FileAccess.file_exists(RASSEN_VORLAGEN_PFAD):
		var vorlagen_text := FileAccess.open(RASSEN_VORLAGEN_PFAD, FileAccess.READ).get_as_text()
		var daten: Variant = JSON.parse_string(vorlagen_text)
		if typeof(daten) == TYPE_DICTIONARY and (daten as Dictionary).has("mensch"):
			schema.aus_eintrag("mensch", (daten as Dictionary)["mensch"])
	return schema

func _weltuhr_verbinden() -> void:
	var weltuhr := get_weltuhr()
	if weltuhr == null or not weltuhr.has_signal("tick"):
		return
	for ki in _ki_maschinen:
		if not weltuhr.tick.is_connected(ki.tick):
			weltuhr.tick.connect(ki.tick)

func get_weltuhr() -> Node:
	## Die Uhr wird zur Laufzeit aufgelöst, damit Headless-Testläufe ohne
	## Autoloads kompilierbar bleiben.
	var szene := Engine.get_main_loop() as SceneTree
	if szene == null:
		return null
	return szene.root.get_node_or_null("/root/Weltuhr")
