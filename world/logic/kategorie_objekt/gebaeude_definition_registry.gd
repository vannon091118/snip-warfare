extends RefCounted
class_name Gebaeude_DefinitionRegistry
## Registry aller Gebäude-Definitionen. Einzige Quelle für Baukosten,
## Bauzeiten und Produktionsrezepte (world/data/gebaeude.json).
## Neue Gebäude entstehen ausschließlich über diese Datenquelle; die
## Produktions- und Baumaschinen ändern sich dabei nicht.

const QUELLE := "res://world/data/gebaeude.json"

## Kategorie daten: Definitionen je Gebäude-ID.
var _definitionen_nach_id: Dictionary = {}
var _definitionen: Array[Gebaeude_Definition] = []

## Kategorie logik: Laden und zentrale Ausgabe.

func _init() -> void:
	laden()

func laden() -> void:
	_definitionen_nach_id.clear()
	_definitionen.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Gebäude-Konfiguration nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_ARRAY:
		push_warning("Gebäude-Konfiguration ungültiges Format: %s" % QUELLE)
		return
	for eintrag: Variant in gelesen:
		if typeof(eintrag) != TYPE_DICTIONARY or not (eintrag as Dictionary).has("id"):
			continue
		var wort := eintrag as Dictionary
		var gebaeude_id := str(wort["id"])
		var definition := Gebaeude_Definition.new()
		definition.aus_konfig_eintrag(wort)
		_definitionen.append(definition)
		_definitionen_nach_id[gebaeude_id] = definition

func hat_gebaeude(gebaeude_id: String) -> bool:
	return _definitionen_nach_id.has(gebaeude_id)

func definition_fuer(gebaeude_id: String) -> Gebaeude_Definition:
	return _definitionen_nach_id.get(gebaeude_id, null)

func gebaeude_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: Gebaeude_Definition in _definitionen:
		ids.append(definition.id)
	ids.sort()
	return ids

func alle_definitionen() -> Array[Gebaeude_Definition]:
	return _definitionen.duplicate()
