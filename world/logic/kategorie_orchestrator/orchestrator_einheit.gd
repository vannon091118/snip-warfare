extends RefCounted
class_name Orchestrator_EinheitDerWelt
## Eine normale Einheit mit reserviertem Job_Orchestrieren, der permanent läuft.
## Sie dient als physische Präsenz des Orchestrators auf der Weltkarte und
## im Spielgeschehen. Der Job wird von der Orchestrator_Manager-Logik verwaltet.

## Kategorie daten: Status und Job der Einheit.
var _status: Einheit_Status = null
var _job_orchestrieren: Job_Basis = null
var _konfig_index: int = -1  # Index in der Config, damit der Manager Zugriff hat

## Kategorie logik: Einheit einrichten und Job zuweisen.

func _init() -> void:
	_status = Einheit_Status.new()
	_job_orchestrieren = Job_Orchestrieren.new()

func status_returns() -> Einheit_Status:
	return _status

func job_returns() -> Job_Basis:
	return _job_orchestrieren

## Wird vom Orchestrator_Manager aufgerufen, um diese Einheit mit einer
## Konfigurations-ID zu verknüpfen. Der Manager weist die Einheit zu und
## verwaltet ihre Aktivierung alle 60 Ticks.

func zuweisen(konfig_index: int, einheit_position: Vector2) -> void:
	_konfig_index = konfig_index
	_status.welt_position_setzen(einheit_position)
	# Weise den reservierten Orchestrator-Job zu
	job_vergeben()

func job_vergeben() -> void:
	# Gib den reservierten Job_Orchestrieren am Status der Einheit
	if _job_orchestrieren != null:
		_status.job_vergeben(_job_orchestrieren, Job_Basis.ZielTyp.OWN, -1, "")
	# Setze Animation basierend auf Job
	if _status.job != null:
		_status.animation_setzen(_status.job.animation())

func _auf_tick_einheit(_tick: int, _delta: float) -> void:
	# Wird von der Einheit selbst pro Tick aufgerufen. Da der Job_Orchestrieren
	# permanent läuft, hält diese Methode die Einheit in einem konsistenten Zustand.
	# Die eigentliche Orchestrierungs-Logik (Bedarf prüfen, Jobs zuweisen)
	# erfolgt im Orchestrator_Manager alle 60 Ticks.
	if _status.job == null:
		job_vergeben()