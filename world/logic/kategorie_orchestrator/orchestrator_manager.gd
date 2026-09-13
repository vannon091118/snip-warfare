extends Node2D
class_name Orchestrator_Manager
## Manager des Orchestrators: Er verarbeitet die Orchestrator-Zonen alle
## sechzig Ticks, hält die Zuordnung Einheit zu Zone und trägt die Signale.
## Die Obergrenze liest Orchestrator_SpawnCap, die Ziele sucht
## Orchestrator_ZielSuche, die Zonen liest Orchestrator_KonfigLader und die
## Zuteilung rechnet Orchestrator_Verteiler. Der Manager entscheidet nichts
## selbst; er hält den Takt und die Verbindungen.

signal orchestrator_platziert(status: Orchestrator_Status, konfig: Orchestrator_Konfiguration)

## Kategorie daten: die verwalteten Orchestratoren mit Status und Zone.
var _orchestratoren: Array[Dictionary] = []
## Kategorie daten: Zuordnung Einheit-Index -> Orchestrator-Zonen-Index.
var _einheit_zu_zone: Dictionary = {}

## Kategorie logik: Verbindungen zu anderen Domänen und Tick-Intervall.
var _einheit_manager: Einheit_Manager = null
var _welt_modell: Welt_Model = null
var _welt_registry: Welt_Registry = null
var _job_registry: Job_Registry = null
var _ziel_suche := Orchestrator_ZielSuche.new()
var _verteiler := Orchestrator_Verteiler.new()

## Tick-Zähler: Alle 60 Ticks wird die Orchestrierung neu evaluiert.
var _tick_counter: int = 0

## Kategorie daten: Referenz auf die Orchestrator-Konfiguration.
var orchestrator_config: Dictionary = {}
var _rassen_registry: Pop_RassenSchemaRegistry = null

func rassen_registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_rassen_registry = registry

func _enter_tree() -> void:
	# Die Weltuhr wird zur Laufzeit aufgeloest statt ueber den Autoload-Globalnamen,
	# damit der Manager auch in Headless-Testlaeufen ohne Autoloads ladbar bleibt.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func referenzen_setzen(einheit_manager: Einheit_Manager, welt_modell: Welt_Model, welt_registry: Welt_Registry, job_registry: Job_Registry) -> void:
	_einheit_manager = einheit_manager
	_welt_modell = welt_modell
	_welt_registry = welt_registry
	_job_registry = job_registry
	_ziel_suche.einrichten(welt_modell, welt_registry)
	_verteiler.einrichten(einheit_manager, welt_modell, _ziel_suche, job_registry)
	load_orchestrator_config()

func load_orchestrator_config() -> void:
	## Lädt die Orchestrator-Konfiguration aus game/data/orchestrator_config.json.
	orchestrator_config = Orchestrator_KonfigLader.laden()
	if orchestrator_config.is_empty():
		return
	print("Orchestrator-Konfiguration geladen: %d Zonen" % orchestrator_config.size())

func orchestrator_platzieren(konfig: Orchestrator_Konfiguration) -> int:
	var status := Orchestrator_Status.new()
	status.konfigurieren(konfig)
	status.bedarf_pruefen.connect(_auf_bedarf_pruefen)
	var idx := _orchestratoren.size()
	_orchestratoren.append({"status": status, "konfig": konfig, "einheiten": []})
	orchestrator_platziert.emit(status, konfig)
	return idx

func status_fuer(idx: int) -> Orchestrator_Status:
	if idx < 0 or idx >= _orchestratoren.size():
		return null
	return _orchestratoren[idx]["status"]

## Gibt den Orchestrator-Zonen-Index für eine Einheit zurück, oder -1.
func zonen_index_fuer_einheit(einheit_index: int) -> int:
	if _einheit_zu_zone.has(einheit_index):
		return _einheit_zu_zone[einheit_index]
	return -1

## Registriert eine Einheit als Orchestrator für eine bestimmte Zone.
func einheit_als_orchestrator_registrieren(einheit_index: int, zonen_index: int) -> void:
	_einheit_zu_zone[einheit_index] = zonen_index
	if zonen_index >= 0 and zonen_index < _orchestratoren.size():
		var einheiten_array: Array = _orchestratoren[zonen_index].get("einheiten", [])
		if not einheiten_array.has(einheit_index):
			einheiten_array.append(einheit_index)
			_orchestratoren[zonen_index]["einheiten"] = einheiten_array

func _auf_bedarf_pruefen(_konfig: Orchestrator_Konfiguration) -> void:
	pass

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	_tick_counter += 1
	# Alle 60 Ticks Orchestrierung evaluieren.
	if _tick_counter % 60 != 0:
		return
	if _einheit_manager == null or _welt_modell == null or _welt_registry == null:
		return
	# Spawn-Cap: Bei erreichter Obergrenze tickt die Welt weiter, aber es
	# entstehen keine neuen Einheiten mehr.
	var max_einheiten := Orchestrator_SpawnCap.max_einheiten(_rassen_registry)
	if _einheit_manager.einheit_zahl() >= max_einheiten:
		return
	var frei_einheiten: Array = _einheit_manager.idle_einheiten()
	if frei_einheiten.is_empty():
		return
	_verteiler.zuteilen(_orchestratoren, frei_einheiten)
