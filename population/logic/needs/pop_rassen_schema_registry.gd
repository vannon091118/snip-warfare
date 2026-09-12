extends RefCounted
class_name Pop_RassenSchemaRegistry
## Registry der Rassen-Schemata. Liest population/data/rassen_schemata.json
## und erzeugt je Eintrag ein Pop_RassenSchema. Einzige Quelle für Rassen;
## Erweiterung nur über Datenpool + Registry, keine Streuung.
## Unterstützt Runtime-Registrierung generierter Rassen via registriere_generiert().

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

## Kategorie logik: Runtime-Registrierung generierter Rassen.
## Wird vom Rassen_Generator aufgerufen nach Generierung aus Keimpunkten.
## Generierte Schemata sind bereits finalisiert (immutabel).

func registriere_generiert(rasse_id: String, schema: Pop_RassenSchema) -> void:
	if not schema.ist_finalisiert():
		push_error("Versuch, nicht-finalisiertes Schema zu registrieren: %s" % rasse_id)
		return
	if _schemata_nach_id.has(rasse_id):
		push_warning("Rassen-ID '%s' bereits registriert, wird überschrieben" % rasse_id)
		## Alten Eintrag aus Array entfernen
		var alter_index := _schemata.find(schema_fuer(rasse_id))
		if alter_index >= 0:
			_schemata.remove_at(alter_index)

	_schemata.append(schema)
	_schemata_nach_id[rasse_id] = schema
	print("Generiertes Rassen-Schema registriert: %s (%s)" % [rasse_id, schema.angezeigter_name])

## Kategorie logik: Entfernen generierter Schemata (z.B. bei Welt-Neugenerierung).

func entferne_generiert(rasse_id: String) -> void:
	if _schemata_nach_id.has(rasse_id):
		var schema: Pop_RassenSchema = _schemata_nach_id[rasse_id]
		var index: int = _schemata.find(schema)
		if index >= 0:
			_schemata.remove_at(index)
		_schemata_nach_id.erase(rasse_id)
		print("Generiertes Rassen-Schema entfernt: %s" % rasse_id)

func entferne_alle_generierten() -> void:
	## Entfernt alle Schemata, die nicht aus der Basis-JSON stammen
	## Basis-IDs sind bekannt: mensch, elf, ork
	var basis_ids := ["mensch", "elf", "ork"]
	var zu_entfernen: Array[String] = []
	for id in _schemata_nach_id.keys():
		if not basis_ids.has(id):
			zu_entfernen.append(id)
	for id in zu_entfernen:
		entferne_generiert(id)

func ist_basis_rasse(rasse_id: String) -> bool:
	return rasse_id in ["mensch", "elf", "ork"]

func anzahl_registriert() -> int:
	return _schemata.size()

func anzahl_basis() -> int:
	var count := 0
	for s in _schemata:
		if ist_basis_rasse(s.rasse_id):
			count += 1
	return count

func anzahl_generiert() -> int:
	return _schemata.size() - anzahl_basis()