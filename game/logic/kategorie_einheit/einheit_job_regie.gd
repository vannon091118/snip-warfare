extends RefCounted
class_name Einheit_JobRegie
## Auftrags-Regie einer Einheit: Sie vergibt Jobs samt Vitalprüfung, treibt den
## Arbeitsfortschritt, beendet Aufträge samt Loop-Neustart und meldet die
## eigene Warteschlange nach oben. Sie liest und schreibt den Auftragszustand
## ihrer Einheit, kennt aber weder Takt noch Darstellung.

var _status: Einheit_Status = null

func _init(status: Einheit_Status) -> void:
	_status = status

func vergeben(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> bool:
	# Die Vergabe prüft die Aussagen der Vital-Maschine und der Job-Konfig;
	# scheitert sie, bleibt der alte Zustand unberührt und es wird gemeldet.
	if neuer_job == null:
		_status.job_vergeben_fehlgeschlagen.emit("Kein Job übergeben")
		return false
	var blocker := _status.vital.blockiert_job(neuer_job.job_id)
	if blocker != "":
		_status.job_vergeben_fehlgeschlagen.emit("Verletzung blockiert Job: " + blocker)
		return false
	if not neuer_job.kann_ausgefuehrt_werden_von(_status.vital):
		_status.job_vergeben_fehlgeschlagen.emit("Physische Voraussetzungen nicht erfüllt für: " + neuer_job.name())
		return false
	if _status.ist_beschaeftigt():
		# Beschäftigt: Der Auftrag wandert hinten an die eigene Queue und
		# startet erst nach dem aktiven Job.
		_status.job_vormerken(neuer_job.job_id, ziel_typ, ziel_index, ressource)
		return true
	uebernehmen(neuer_job, ziel_typ, ziel_index, ressource)
	return true

func uebernehmen(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	_status.job = neuer_job
	_status.aktuelles_ziel_typ = ziel_typ
	_status.aktuelles_ziel_index = ziel_index
	_status.ziel_ressource = ressource
	neuer_job.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	neuer_job.job_beendet.connect(_auf_job_beendet)
	neuer_job.startet_neu()
	arbeit_oder_gehen()

func loopy_fortsetzen(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	if _status.job != neuer_job:
		return
	_status.aktuelles_ziel_typ = ziel_typ
	_status.aktuelles_ziel_index = ziel_index
	_status.ziel_ressource = ressource
	_status._loop_fortgesetzt = true
	neuer_job.startet_neu()
	# Die fehlende Zustandstransition des Arbeitsloops: Liegt das neue Ziel
	# außerhalb der Reichweite, läuft die Einheit erst hin (GEHEN).
	arbeit_oder_gehen()

func arbeit_tick() -> void:
	if _status.job == null:
		_status._zu_zustand_wechseln(Einheit_Status.Zustand.IDLE)
		return
	if _status.job.schritt_vorruecken():
		_status.job.arbeitsschritt(_status.ziel_ressource)
		# Ein abgeschlossener Arbeitsschritt beendet Erntejobs: Bei Loop-Jobs
		# sucht der Manager das nächste Ziel, sonst fällt die Einheit in den Idle.
		if _status.job != null and _status.job.ziel_typ() == Job_Basis.ZielTyp.OBJEKT \
				and _status.job.ressource() != "":
			_status.job.job_beendet.emit()

func arbeit_oder_gehen() -> void:
	# Zu weit entfernte Ziele laufen die Einheiten an, statt den Befehl mit
	# einer Meldung abzulehnen.
	if _status.job == null:
		return
	if _status.bewegung.am_ziel(_status.welt_position):
		_status._zu_zustand_wechseln(Einheit_Status.Zustand.ARBEITEN)
	else:
		_status._zu_zustand_wechseln(Einheit_Status.Zustand.GEHEN)

func _auf_arbeitsschritt(ressource: String, menge: int) -> void:
	_status.arbeitsschritt_erledigt.emit(ressource, menge)

func _auf_job_beendet() -> void:
	if _status.job != null and _status.job.ist_loop():
		_status._loop_fortgesetzt = false
		_status.job_loop_gefragt.emit(_status.job, _status.aktuelles_ziel_typ,
			_status.aktuelles_ziel_index)
		if _status._loop_fortgesetzt:
			return
	_status.job_beendet.emit()
	_status.job_abbrechen()
	# Eigene Queue: Der nächste vorgemerkte Auftrag wird nach oben gemeldet
	# und startet, sobald der Manager ihn erzeugt hat.
	if not _status.queue.leer():
		var naechster := _status.queue.naechster()
		_status.naechster_job_aus_queue.emit(str(naechster.get("job_id", "")),
			int(naechster.get("ziel_typ", 0)),
			int(naechster.get("ziel_index", -1)),
			str(naechster.get("ressource", "")))
