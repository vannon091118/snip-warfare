extends RefCounted
class_name Welt_FortschrittHelfer
## Entkoppelter Signal- und Spawn-Helfer der Einstiegs-Progression.
## Er kennt Bus und Einheit-Orchestrierung, aber nichts vom Welt_Model.

var _maschine: Welt_FortschrittsMaschine = null
var _einheit_manager: Einheit_Manager = null
var _orchestrator_manager: Orchestrator_Manager = null
var _rassen_registry: Pop_RassenSchemaRegistry = null

func maschine_setzen(maschine: Welt_FortschrittsMaschine) -> void:
	_maschine = maschine

func einheit_setzen(manager: Einheit_Manager) -> void:
	_einheit_manager = manager

func orchestrator_setzen(manager: Orchestrator_Manager) -> void:
	_orchestrator_manager = manager

func rassen_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_rassen_registry = registry

func manager_setzen(einheit: Einheit_Manager, orchestrator: Orchestrator_Manager, rassen: Pop_RassenSchemaRegistry) -> void:
	_einheit_manager = einheit
	_orchestrator_manager = orchestrator
	_rassen_registry = rassen

func bus_verbinden() -> void:
	var bus := Kern_SignalBus.bus()
	if bus == null:
		return
	if bus.has_signal("produktionsraum_entstanden") and not bus.produktionsraum_entstanden.is_connected(_auf_produktionsraum):
		bus.produktionsraum_entstanden.connect(_auf_produktionsraum)
	if bus.has_signal("ressource_eingelagert") and not bus.ressource_eingelagert.is_connected(_auf_ressource):
		bus.ressource_eingelagert.connect(_auf_ressource)
	if bus.has_signal("raum_entstanden") and not bus.raum_entstanden.is_connected(_auf_raum):
		bus.raum_entstanden.connect(_auf_raum)
	if bus.has_signal("lagerzone_registriert") and not bus.lagerzone_registriert.is_connected(_auf_lagerzone):
		bus.lagerzone_registriert.connect(_auf_lagerzone)

func spawn_vorarbeiter() -> Vector2:
	if _einheit_manager == null:
		return Vector2.INF
	if _spawn_cap_erreicht("mensch"):
		return Vector2.INF
	var pos := _einheit_manager.ankunftsort()
	var idx := _einheit_manager.einheit_hinzufuegen(pos, "mensch")
	if _orchestrator_manager != null:
		_orchestrator_manager.einheit_als_orchestrator_registrieren(idx, 0)
	return pos

func _auf_produktionsraum(_raum_id: String, profil: String) -> void:
	if profil != "rathaus":
		return
	var p := spawn_vorarbeiter()
	if p != Vector2.INF and _maschine != null:
		_maschine.orchestrator_gespawnt.emit(p)

func _auf_ressource(ressource: String, _menge: int, _pos: Vector2) -> void:
	if _maschine == null:
		return
	var stufe := _maschine.aktive_stufe()
	if stufe.is_empty() or str(stufe.get("ziel_typ", "")) != "ressource_einlagern":
		return
	if str(stufe.get("ressource", "")) != ressource:
		return
	_maschine.fortschalten()

func _auf_raum(_raum_id: String, innen_flaeche: int, hat_tuer: bool, geschlossen: bool) -> void:
	if _maschine == null:
		return
	var stufe := _maschine.aktive_stufe()
	if stufe.is_empty() or str(stufe.get("ziel_typ", "")) != "raum":
		return
	if innen_flaeche < int(stufe.get("innen_mindest_flaeche", 16)):
		return
	if bool(stufe.get("braucht_tuer", true)) and not hat_tuer:
		return
	if not geschlossen:
		return
	_maschine.fortschalten()

func _auf_lagerzone(_welt_pos: Vector2) -> void:
	if _maschine == null:
		return
	var stufe := _maschine.aktive_stufe()
	if stufe.is_empty() or str(stufe.get("ziel_typ", "")) != "lagerzone":
		return
	_maschine.fortschalten()

func _spawn_cap_erreicht(rasse_id: String) -> bool:
	if _einheit_manager == null:
		return false
	if _rassen_registry == null:
		return _einheit_manager.einheit_zahl() >= 20
	var schema := _rassen_registry.schema_fuer(rasse_id)
	if schema == null:
		return false
	return _einheit_manager.einheit_zahl() >= schema.max_einheiten
