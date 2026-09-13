extends RefCounted
class_name Orchestrator_ZielSuche
## Zielsuche des Orchestrators: das nächste Objekt mit passender
## Arbeitsressource innerhalb des Zonen-Radius. Reine Suche über Modell und
## Registry; sie schreibt nichts, tickt nichts und kennt keine Einheit.

var _modell: Welt_Model = null
var _registry: Welt_Registry = null

func einrichten(modell: Welt_Model, registry: Welt_Registry) -> void:
	_modell = modell
	_registry = registry

func modell_setzen(modell: Welt_Model) -> void:
	_modell = modell

func naechstes_objekt(ressource: String, zentrum: Vector2, radius: float) -> int:
	if _modell == null or _registry == null:
		return -1
	var bester_index := -1
	var beste_distanz := 1e9
	for index in _modell.objekt_anzahl():
		var element_id := _modell.objekt_element_id(index)
		if element_id == "":
			continue
		var objekt := _registry.finde_objekt(element_id)
		if objekt == null or objekt.arbeits_ressource != ressource:
			continue
		var distanz := _modell.objekt_position(index).distance_to(zentrum)
		if distanz <= radius and distanz < beste_distanz:
			beste_distanz = distanz
			bester_index = index
	return bester_index
