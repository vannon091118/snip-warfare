extends RefCounted
class_name Welt_World
## World-Objekt: Der Anker über allen Karten einer Partie. Eine World hält
## die Liste ihrer Maps (Welt_Model-Instanzen), markiert genau eine Map als
## Basis und verwaltet die Zuordnung über map_id. Sie besitzt keine eigene
## Zeit, keinen Zufall und keine Generierung: Der globale Tick bleibt bei
## Kern_Weltuhr, der Zufall bei Kern_Zufall, die Erzeugung beim Generator.
## Maps werden über die eigene Schnittstelle eingetragen und gelesen, nie
## über fremde Arrays.

## Kategorie daten: Map-Liste mit Zuordnung und Basis-Markierung.
var _maps: Array[Dictionary] = []
var _basis_map_id: String = ""
var world_name: String = ""

const SPEICHER_VERSION := 1

## Kategorie logik: Eintragen, Suchen und Abfragen der Maps.

func map_hinzufuegen(model: Welt_Model, map_id: String, ist_basis: bool) -> bool:
	if model == null or map_id.strip_edges() == "":
		return false
	if map_id_vorhanden(map_id):
		return false
	model.map_id = map_id
	_maps.append({"map_id": map_id, "model": model})
	if ist_basis or _basis_map_id == "":
		_basis_map_id = map_id
	return true

func map_entfernen(map_id: String) -> bool:
	for index in _maps.size():
		if str(_maps[index].get("map_id", "")) == map_id:
			_maps.remove_at(index)
			if _basis_map_id == map_id:
				_basis_map_id = _maps[0].get("map_id", "") if not _maps.is_empty() else ""
			return true
	return false

func map_id_vorhanden(map_id: String) -> bool:
	for eintrag: Dictionary in _maps:
		if str(eintrag.get("map_id", "")) == map_id:
			return true
	return false

func basis_setzen(map_id: String) -> bool:
	if not map_id_vorhanden(map_id):
		return false
	_basis_map_id = map_id
	return true

func basis_map_id() -> String:
	return _basis_map_id

func basis_model() -> Welt_Model:
	for eintrag: Dictionary in _maps:
		if str(eintrag.get("map_id", "")) == _basis_map_id:
			return eintrag.get("model", null)
	return null

func map_model(map_id: String) -> Welt_Model:
	for eintrag: Dictionary in _maps:
		if str(eintrag.get("map_id", "")) == map_id:
			return eintrag.get("model", null)
	return null

func map_ids() -> Array[String]:
	var ids: Array[String] = []
	for eintrag: Dictionary in _maps:
		ids.append(str(eintrag.get("map_id", "")))
	return ids

func map_zahl() -> int:
	return _maps.size()

func aktive_map_id() -> String:
	return _basis_map_id if _basis_map_id != "" else (map_ids()[0] if not _maps.is_empty() else "")

func nach_woerterbuch() -> Dictionary:
	# Persistenz der World: Nur die Map-Daten wandern in den Speicher, die
	# Model-Instanzen werden beim Laden neu erzeugt.
	var map_daten: Array[Dictionary] = []
	for eintrag: Dictionary in _maps:
		var model: Welt_Model = eintrag.get("model", null)
		if model != null:
			map_daten.append(model.nach_woerterbuch())
	return {
		"version": SPEICHER_VERSION,
		"world_name": world_name,
		"basis_map_id": _basis_map_id,
		"maps": map_daten,
	}

func aus_woerterbuch(daten: Dictionary) -> bool:
	if daten.is_empty() or int(daten.get("version", 0)) != SPEICHER_VERSION:
		return false
	world_name = str(daten.get("world_name", ""))
	_maps.clear()
	_basis_map_id = ""
	var neue_maps: Variant = daten.get("maps", [])
	if typeof(neue_maps) != TYPE_ARRAY:
		return false
	for eintrag: Variant in neue_maps:
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		var model := Welt_Model.new()
		if not model.aus_woerterbuch(eintrag):
			continue
		map_hinzufuegen(model, model.map_id, false)
	basis_setzen(str(daten.get("basis_map_id", "")))
	return not _maps.is_empty()