extends RefCounted
class_name Einheit_JobFlussMaschine
## Job-Fluss: Queue-Start, Loop-Neusuche, Arbeitsschritt und Transport-Vormerkung.
## Kategorie daten: Trupp-Wörterbuch.
## Kategorie logik: Fremd-Verbindungen und Weg-Planer-Rückruf.
var _trupp: Einheit_TruppMaschine = null
var _job_registry: Job_Registry = null
var _ziel_suche: Einheit_ZielSuche = null
var _ernte: Einheit_ErnteMaschine = null
var _lager: Lager_Manager = null
var _model: Welt_Model = null
var _tiere: Tier_Manager = null

## Weg-Planer des Managers: Rückruf, der Status und Ziel reichen soll.
var _planner: Callable = Callable()

func einrichten(trupp: Einheit_TruppMaschine, job_registry: Job_Registry, ziel_suche: Einheit_ZielSuche, ernte: Einheit_ErnteMaschine, weg_planung_helfer: Callable) -> void:
	_trupp = trupp
	_job_registry = job_registry
	_ziel_suche = ziel_suche
	_ernte = ernte
	_planner = weg_planung_helfer

func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager

func model_setzen(model: Welt_Model, tiere: Tier_Manager) -> void:
	_model = model
	_tiere = tiere

func _planner_fuer(status: Einheit_Status, ziel_position: Vector2) -> void:
	if _planner.is_valid():
		_planner.call(status, ziel_position)

func auf_naechster_job_aus_queue(_job_id: String, _ziel_typ: Job_Basis.ZielTyp, _ziel_index: int, _ressource: String, status: Einheit_Status) -> void:
	# Queue-Start: Frischen Job erzeugen.
	if status.zustand != Einheit_Status.Zustand.IDLE:
		return
	var eintrag := status.queue_naechster()
	if eintrag.is_empty():
		return
	var job_id := str(eintrag.get("job_id", ""))
	var ziel_typ: Job_Basis.ZielTyp = int(eintrag.get("ziel_typ", 0)) as Job_Basis.ZielTyp
	var ziel_index := int(eintrag.get("ziel_index", -1))
	var ressource := str(eintrag.get("ressource", ""))

	# Transport-Job wird speziell behandelt: Inventar wird übergeben
	if job_id == "transport":
		if _trupp.transport_starten(status, ziel_index, ziel_typ):
			return
		status.queue_vorne_entfernen()
		return

	var folge_job := _job_registry.job_erzeugen(job_id)
	var job: Job_Basis = folge_job
	if job == null:
		status.queue_vorne_entfernen()
		return
	status.queue_vorne_entfernen()
	# G1: Auch aus der Queue startet der Job mit dem Faktor seines Ziels.
	job.ziel_faktor_setzen(_ziel_suche.ziel_faktor_fuer(ziel_typ, ziel_index))
	var ziel_position := _ziel_suche.ziel_position_fuer(ziel_typ, ziel_index)
	status.geh_ziel_setzen(ziel_position)
	_planner_fuer(status, ziel_position)
	status.job_vergeben(job, ziel_typ, ziel_index, ressource)

func auf_job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int, status: Einheit_Status) -> void:
	# Loop: Nächstes Ziel desselben Typs neu setzen.
	if job == null or status.job != job:
		return
	var such_index := -1
	match ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model != null:
				such_index = _ziel_suche.naechstes_objekt(status, alter_ziel_index)
		Job_Basis.ZielTyp.TIER:
			if _tiere != null:
				such_index = _ziel_suche.naechstes_tier(status, alter_ziel_index)
	if such_index < 0:
		return
	var ziel_position := _ziel_suche.ziel_position_fuer(ziel_typ, such_index)
	status.geh_ziel_setzen(ziel_position)
	_planner_fuer(status, ziel_position)
	# G1: Das neue Loop-Ziel bringt seinen eigenen Faktor mit.
	job.ziel_faktor_setzen(_ziel_suche.ziel_faktor_fuer(ziel_typ, such_index))
	status.job_loopy_fortsetzen(job, ziel_typ, such_index, job.ressource())

func auf_arbeitsschritt(ressource: String, menge: int, status: Einheit_Status) -> void:
	if _ernte == null or status == null:
		return
	_ernte.arbeitsschritt_verarbeiten(ressource, menge, status)

func auf_inventar_voll(einheit_index: int) -> void:
	if _lager == null or _lager.lager_zahl() == 0:
		return
	var status: Einheit_Status = _trupp.status_bei(einheit_index)
	if status == null:
		return
	var inventar: Einheit_Inventar = _trupp.inventar_bei(einheit_index)
	if inventar == null or inventar.ist_leer():
		return
	var lager_index := _lager.naechstes_lager_fuer(status.welt_position)
	if lager_index < 0:
		return
	status.job_vormerken("transport", Job_Basis.ZielTyp.OBJEKT, lager_index, "")
	status.naechster_job_aus_queue.emit("transport", Job_Basis.ZielTyp.OBJEKT, lager_index, "")

func auf_beute_erlegt(status: Einheit_Status) -> void:
	_trupp.beute_darstellen(status)

func auf_zustand_geaendert(_neu: int, status: Einheit_Status, mood: Pop_MoodMaschine) -> void:
	var vorher := _trupp.zustand_vorher(status)
	var von_str := "idle" if vorher == Einheit_Status.Zustand.IDLE else "arbeiten"
	var nach_str := "idle" if status.zustand == Einheit_Status.Zustand.IDLE else "arbeiten"
	var job_id := status.job.job_id if status.job != null else ""
	mood.auf_jobwechsel(von_str, nach_str, job_id)
