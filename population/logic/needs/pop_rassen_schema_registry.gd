extends RefCounted
class_name Pop_RassenSchemaRegistry
## Registry der Rassen-Schemata. Liest population/data/rassen_schemata.json
## und erzeugt je Eintrag ein Pop_RassenSchema. Einzige Quelle für Rassen;
## Erweiterung nur über Datenpool + Registry, keine Streuung.

const QUELLE := "res://population/data/rassen_schemata.json"

## Kategorie daten: Schemata je rasse_id.
var _schemata_nach_id: Dictionary = {}
var _schemata: Array[Pop_RassenSchema] = []

## Kategorie logik: Laden und zentrale Zuordnung.
func _init() -> void:
	laden()

func laden() -> void:
	_schemata_nach_id.clear()
	_schemata.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Rassen-Konfiguration nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Rassen-Konfiguration ungültiges Format: %s" % QUELLE)
		return
	for eintrag_id: String in (gelesen as Dictionary).keys():
		var eintrag: Dictionary = (gelesen as Dictionary)[eintrag_id]
		var schema := Pop_RassenSchema.new()
		schema.aus_eintrag(eintrag_id, eintrag)
		_schemata.append(schema)
		_schemata_nach_id[eintrag_id] = schema

func hat_schema(rasse_id: String) -> bool:
	return _schemata_nach_id.has(rasse_id)

func schema_fuer(rasse_id: String) -> Pop_RassenSchema:
	return _schemata_nach_id.get(rasse_id, null)

func alle_schemata() -> Array[Pop_RassenSchema]:
	return _schemata.duplicate()

func standard_rasse() -> String:
	if _schemata.is_empty():
		return "mensch"
	return _schemata[0].rasse_id