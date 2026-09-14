extends RefCounted
class_name Welt_FortschrittVerdrahtung
## Verdrahtung der Fortschritts-Domäne: Sie verbindet die Welt_FortschrittsMaschine
## mit dem Kern_SignalBus und trägt den Vorarbeiter-Spawn. Sie hört auf echte
## Welt-Ereignisse (Raum, Lagerzone, Einlagerung, Produktionsraum) und ruft
## die Maschine nur über ihre öffentliche Auftragsschnittstelle auf. Keine
## Stufen-Logik, kein Gating, keine Persistenz: Maschine entscheidet, Brücke
## liefert Ereignisse und stellt Einheiten auf.
##
## Verantwortlichkeit: Bus-Verbindungen und Vorarbeiter-Spawn.

static var _aktive: Welt_FortschrittVerdrahtung = null

## Statischer Zugriffspunkt: Die Maschine kennt keinen Bus und keinen Manager;
## für den Rathaus-Spawn fragt sie die aktive Verdrahtung ihrer Domäne.
static func aktive() -> Welt_FortschrittVerdrahtung:
	return _aktive

var _maschine = null
var _einheit_manager: Einheit_Manager = null
var _orchestrator_manager: Orchestrator_Manager = null
var _rassen_registry: Pop_RassenSchemaRegistry = null

## Kategorie daten: Referenzen auf Maschine, Einheiten, Orchestrator, Rassen.

## Kategorie logik: Verbinden, Ereignisse deuten, Spawn aufstellen.

func _init() -> void:
	_aktive = self

func _notification(was: int) -> void:
	if was == NOTIFICATION_PREDELETE and _aktive == self:
		_aktive = null

func einrichten(maschine) -> void:
	_maschine = maschine

func einheit_manager_setzen(manager: Einheit_Manager) -> void:
	_einheit_manager = manager
	_bus_verbinden()

func orchestrator_manager_setzen(manager: Orchestrator_Manager) -> void:
	_orchestrator_manager = manager

func rassen_registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_rassen_registry = registry

func _bus_verbinden() -> void:
	var bus := Kern_SignalBus.bus()
	if bus == null:
		return
	if bus.has_signal("produktionsraum_entstanden") and not bus.produktionsraum_entstanden.is_connected(_auf_produktionsraum_entstanden):
		bus.produktionsraum_entstanden.connect(_auf_produktionsraum_entstanden)
	if bus.has_signal("ressource_eingelagert") and not bus.ressource_eingelagert.is_connected(_auf_ressource_eingelagert):
		bus.ressource_eingelagert.connect(_auf_ressource_eingelagert)
	if bus.has_signal("raum_entstanden") and not bus.raum_entstanden.is_connected(_auf_raum_entstanden):
		bus.raum_entstanden.connect(_auf_raum_entstanden)
	if bus.has_signal("lagerzone_registriert") and not bus.lagerzone_registriert.is_connected(_auf_lagerzone_registriert):
		bus.lagerzone_registriert.connect(_auf_lagerzone_registriert)

func _auf_produktionsraum_entstanden(_raum_id: String, profil: String) -> void:
	if profil != "rathaus":
		return
	vorarbeiter_aufstellen()

func _auf_ressource_eingelagert(ressource: String, _menge: int, _welt_position: Vector2) -> void:
	if _maschine == null:
		return
	_maschine.ressource_eingelagert(ressource)

func _auf_raum_entstanden(raum_id: String, innen_flaeche: int, hat_tuer: bool, geschlossen: bool) -> void:
	if _maschine == null:
		return
	_maschine.raum_entstanden(raum_id, innen_flaeche, hat_tuer, geschlossen)

func _auf_lagerzone_registriert(_welt_position: Vector2) -> void:
	if _maschine == null:
		return
	_maschine.lagerzone_registriert()
	# Der Schritt davor schaltete rathaus als Belohnung frei. Das Signal
	# allein genuegt nicht: Der Vorarbeiter gehört zum selben Ereignis.
	# Ob er sofort oder beim Aufstellen des rathaus spawnt, entscheidet
	# die nächste Stufe (gebaeude_bauen rathaus). Kein stiller Spawn.

func vorarbeiter_aufstellen() -> void:
	if _einheit_manager == null:
		push_warning("Welt_FortschrittVerdrahtung: Einheit_Manager nicht gesetzt")
		return
	var spawn_position := _einheit_manager.ankunftsort()
	if _spawn_cap_erreicht("mensch"):
		push_warning("Spawn-Cap erreicht")
		return
	var einheit_index := _einheit_manager.einheit_hinzufuegen(spawn_position, "mensch")
	if _orchestrator_manager != null:
		_orchestrator_manager.einheit_als_orchestrator_registrieren(einheit_index, 0)
	if _maschine != null:
		_maschine.orchestrator_gespawnt.emit(spawn_position)

func _spawn_cap_erreicht(rasse_id: String) -> bool:
	if _einheit_manager == null:
		return false
	if _rassen_registry == null:
		return _einheit_manager.einheit_zahl() >= 20
	var schema := _rassen_registry.schema_fuer(rasse_id)
	if schema == null:
		return false
	return _einheit_manager.einheit_zahl() >= schema.max_einheiten
