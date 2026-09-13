extends RefCounted
class_name Welt_FortschrittsMaschine
signal stufe_erreicht(stufe: Dictionary)
signal ziel_erreicht(stufe: Dictionary)
signal orchestrator_gespawnt(position: Vector2)
var stufe_index: int = 0
var abgeschlossen: Dictionary = {}
var _einheit_manager: Einheit_Manager = null
var _orchestrator_manager: Orchestrator_Manager = null
var _rassen_registry: Pop_RassenSchemaRegistry = null

func _init() -> void:
	abgeschlossen = {}

func registry_setzen(registry: Welt_FortschrittsRegistry) -> void:
	_registry = registry

func einheit_manager_setzen(manager: Einheit_Manager) -> void:
	_einheit_manager = manager
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("produktionsraum_entstanden") and not bus.produktionsraum_entstanden.is_connected(_auf_produktionsraum_entstanden):
		bus.produktionsraum_entstanden.connect(_auf_produktionsraum_entstanden)

func orchestrator_manager_setzen(manager: Orchestrator_Manager) -> void:
	_orchestrator_manager = manager

func rassen_registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_rassen_registry = registry

func aktive_stufe() -> Dictionary:
	if _registry == null:
		return {}
	return _registry.stufe_an(stufe_index)

func ziel_zeile() -> String:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return "Alle Ziele erreicht."
	return "Ziel: %s" % str(stufe.get("beschreibung", ""))

func gebaeude_fertiggestellt(gebaeude_id: String) -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	if str(stufe.get("ziel_typ", "")) != "gebaeude_bauen":
		return
	if str(stufe.get("gebaeude_id", "")) != gebaeude_id:
		return
	_fortschalten()

func einwanderer_angekommen() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	if str(stufe.get("ziel_typ", "")) != "einwanderung":
		return
	_fortschalten()

func _auf_produktionsraum_entstanden(_raum_id: String, profil: String) -> void:
	if profil != "rathaus":
		return
	if _einheit_manager == null:
		push_warning("Welt_FortschrittsMaschine: Einheit_Manager nicht gesetzt")
		return
	var spawn_position := Vector2(500, 300)
	if _spawn_cap_erreicht("mensch"):
		push_warning("Spawn-Cap erreicht")
		return
	var einheit_index := _einheit_manager.einheit_hinzufuegen(spawn_position, "mensch")
	# Registriere die Einheit als Orchestrator für die erste Zone (Index 0)
	if _orchestrator_manager != null:
		_orchestrator_manager.einheit_als_orchestrator_registrieren(einheit_index, 0)
	orchestrator_gespawnt.emit(spawn_position)

func _spawn_cap_erreicht(rasse_id: String) -> bool:
	if _einheit_manager == null:
		return false
	if _rassen_registry == null:
		return _einheit_manager.einheit_zahl() >= 20
	var schema := _rassen_registry.schema_fuer(rasse_id)
	if schema == null:
		return false
	return _einheit_manager.einheit_zahl() >= schema.max_einheiten

func _fortschalten() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	abgeschlossen[str(stufe.get("id", ""))] = true
	ziel_erreicht.emit(stufe)
	if stufe_index + 1 < _registry.stufen_zahl():
		stufe_index += 1
		stufe_erreicht.emit(aktive_stufe())

func stufe_frei(gesperrt_ab_stufe: int) -> bool:
	return stufe_index >= gesperrt_ab_stufe

func freigeschaltete_gebaeude() -> Array[String]:
	var frei: Array[String] = []
	if _registry == null:
		return frei
	for index in stufe_index + 1:
		var stufe := _registry.stufe_an(index)
		for gebaeude_id: Variant in (stufe.get("schaltet_frei", {}).get("gebaeude", []) as Array):
			frei.append(str(gebaeude_id))
	return frei

var _registry: Welt_FortschrittsRegistry = null
