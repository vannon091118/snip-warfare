extends RefCounted
class_name Orchestrator_SpawnCap
## Spawn-Obergrenze des Orchestrators: Sie liest das max_einheiten der
## Standardrasse aus dem Rassen-Registry. Ohne Registry bleibt der Rückfall
## aus population/data/rassen_schemata.json; eine eigene Zahl daneben gibt es
## nicht. Reines Lesen, kein Tick.

const RASSEN_PFAD := "res://population/data/rassen_schemata.json"
const STANDARD_RASSE := "mensch"
const RUECKFALL := 20

static func max_einheiten(registry: Pop_RassenSchemaRegistry) -> int:
	if registry != null:
		var schema := registry.schema_fuer(STANDARD_RASSE)
		if schema != null:
			return schema.max_einheiten
	return _aus_datei()

static func _aus_datei() -> int:
	if not FileAccess.file_exists(RASSEN_PFAD):
		return RUECKFALL
	var datei := FileAccess.open(RASSEN_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		return RUECKFALL
	var rassen := gelesen as Dictionary
	if not rassen.has(STANDARD_RASSE):
		return RUECKFALL
	return int(rassen[STANDARD_RASSE].get("max_einheiten", RUECKFALL))
