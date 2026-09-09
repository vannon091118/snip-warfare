extends Node2D
class_name Orchestrator_Manager
## Manager des Orchestrators: Er hält die Zustandsmaschinen der Zonen,
## tickt sie über die globale Weltuhr und weist auf gemeldeten Bedarf
## freie Einheiten zu. Er greift nur über die Schnittstellen des
## Einheit_Managers zu und ändert keine fremden Zustände direkt.

signal orchestrator_platziert(status: Orchestrator_Status, konfig: Orchestrator_Konfiguration)

## Kategorie daten: die verwalteten Orchestratoren mit Status und Zone.
var _orchestratoren: Array[Dictionary] = []

## Kategorie logik: Verbindungen zu anderen Domänen und Tick.
var _einheit_manager: Einheit_Manager = null
var _welt_modell: Welt_Model = null
var _welt_registry: Welt_Registry = null
var _job_registry: Job_Registry = null

func _ready() -> void:
	Weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	if Weltuhr.tick.is_connected(_auf_tick):
		Weltuhr.tick.disconnect(_auf_tick)

func referenzen_setzen(einheit_manager: Einheit_Manager, welt_modell: Welt_Model, welt_registry: Welt_Registry, job_registry: Job_Registry) -> void:
	_einheit_manager = einheit_manager
	_welt_modell = welt_modell
	_welt_registry = welt_registry
	_job_registry = job_registry

func orchestrator_platzieren(konfig: Orchestrator_Konfiguration) -> int:
	var status := Orchestrator_Status.new()
	status.konfigurieren(konfig)
	status.bedarf_pruefen.connect(_auf_bedarf_pruefen)
	var idx := _orchestratoren.size()
	_orchestratoren.append({"status": status, "konfig": konfig})
	orchestrator_platziert.emit(status, konfig)
	return idx

func status_fuer(idx: int) -> Orchestrator_Status:
	if idx < 0 or idx >= _orchestratoren.size():
		return null
	return _orchestratoren[idx]["status"]

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	for eintrag: Dictionary in _orchestratoren:
		var status: Orchestrator_Status = eintrag["status"]
		status.tick()

func _auf_bedarf_pruefen(konfig: Orchestrator_Konfiguration) -> void:
	# Bedarf der Zone in Prioritätsreihenfolge abarbeiten; jeder freien
	# Einheit im Radius fällt das nächste passende Objekt zu.
	if _einheit_manager == null or _welt_modell == null or _welt_registry == null:
		return
	var freie_einheiten := _einheiten_im_radius(konfig)
	if freie_einheiten.is_empty():
		return
	for bedarf: Dictionary in konfig.sortierte_bedarfe():
		if freie_einheiten.is_empty():
			return
		var ressource := str(bedarf.get("ressource", ""))
		var job_id := str(bedarf.get("job_id", ""))
		if job_id == "" or ressource == "":
			continue
		var objekt_idx := _naechstes_objekt_fuer_ressource(ressource, konfig.position, konfig.radius)
		if objekt_idx < 0:
			continue
		var einheit_idx: int = freie_einheiten.pop_front()
		var ziel_position := _welt_modell.objekt_position(objekt_idx)
		_einheit_manager.job_vergeben(
			einheit_idx,
			job_id,
			Job_Basis.ZielTyp.OBJEKT,
			objekt_idx,
			ziel_position
		)

func _einheiten_im_radius(konfig: Orchestrator_Konfiguration) -> Array[int]:
	# Freie Einheiten im Zone-Radius; die Reihenfolge bleibt stabil.
	var gefundene: Array[int] = []
	if _einheit_manager == null:
		return gefundene
	for index in _einheit_manager.einheit_zahl():
		var einheit_position := _einheit_manager.einheit_position(index)
		var im_radius := einheit_position.distance_to(konfig.position) <= konfig.radius
		if im_radius and _einheit_manager.job_id_einheit(index) == "":
			gefundene.append(index)
	return gefundene

func _naechstes_objekt_fuer_ressource(ressource: String, zentrum: Vector2, radius: float) -> int:
	# Nächstes Objekt mit passender Arbeitsressource innerhalb des Radius.
	if _welt_modell == null or _welt_registry == null:
		return -1
	var bester_index := -1
	var beste_distanz := INF
	for index in _welt_modell.objekt_anzahl():
		var element_id := _welt_modell.objekt_element_id(index)
		if element_id == "":
			continue
		var objekt := _welt_registry.finde_objekt(element_id)
		if objekt == null or objekt.arbeits_ressource != ressource:
			continue
		var objekt_position := _welt_modell.objekt_position(index)
		var distanz := objekt_position.distance_to(zentrum)
		if distanz <= radius and distanz < beste_distanz:
			beste_distanz = distanz
			bester_index = index
	return bester_index
