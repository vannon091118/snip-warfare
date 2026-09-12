extends RefCounted
class_name Einheit_TaktMaschine
## Ein Takt der Einheiten: Diese Maschine fuehrt die Einheiten-Schleife an der
## Weltuhr — Ziel pruefen, Transportphasen buchen, Status ticken, Bewegung
## nachziehen, Umweltschaden anwenden und das Verhalten gestreut anstossen.
## Sie kennt keine Einheiten-Erzeugung und keine Job-Vergabe.

const GATE_TEILER := 6
const VERHALTEN_STREUUNG := 12

var _kontext: Dictionary = {}


func einrichten(kontext: Dictionary) -> void:
	## Der Kontext traegt Einheitenliste, Maschinen und Zufallsquelle.
	_kontext = kontext


func tick(nummer: int, delta: float) -> void:
	if not _aktive_karte():
		return
	var verhalten: Einheit_VerhaltensMaschine = _kontext["verhalten"]
	var need_registry: Pop_NeedRegistry = _kontext["need_registry"]
	verhalten.cache_erneuern(nummer)
	var takt_ticks := Kern_Weltuhr.ticks_aus_minuten(need_registry.takt_minuten())
	if takt_ticks > 0 and nummer % takt_ticks == 0 and nummer != 0:
		nahrung_verteilen()
		# Einwanderung: Der aktive Zieltyp liefert die Rate, der Spawn laeuft
		# ueber denselben Schnitt wie jede andere Ankunft.
		(_kontext["versorgung_neu"] as Einheit_VersorgungsMaschine).einwanderung_ticken()
	var einheiten: Array[Dictionary] = _kontext["einheiten"]
	for ei: int in einheiten.size():
		_eine_einheit(einheiten[ei], ei, nummer, delta)


func _eine_einheit(einheit: Dictionary, ei: int, nummer: int, delta: float) -> void:
	var status: Einheit_Status = einheit["status"]
	var mood: Pop_MoodMaschine = einheit["mood"]
	var ziel_suche: Einheit_ZielSuche = _kontext["ziel_suche"]
	if _ziel_verloren(status, ziel_suche):
		status.job_abbrechen()
		(einheit["darsteller"] as Einheit_Darsteller).animation_setzen(status.animation())
		return
	_transport_phase(status)
	status.tick(delta)
	_bewegung_nachziehen(einheit, status, mood, nummer, delta, ei)


func _ziel_verloren(status: Einheit_Status, ziel_suche: Einheit_ZielSuche) -> bool:
	## Ein entferntes Ziel beendet die Arbeit sofort.
	var beschaeftigt := status.zustand == Einheit_Status.Zustand.ARBEITEN \
		or status.zustand == Einheit_Status.Zustand.GEHEN
	return beschaeftigt and not ziel_suche.ziel_existiert(status)


func _transport_phase(status: Einheit_Status) -> void:
	## Der Transport-Job bucht seine Ablieferung bei der Trupp-Maschine.
	if status.job == null or status.job.job_id != "transport":
		return
	var transport_job: Job_Transport = status.job as Job_Transport
	if transport_job == null:
		return
	match transport_job.phase():
		Job_Transport.PHASE_GEHE_ZU_LAGER:
			if status.zustand == Einheit_Status.Zustand.ARBEITEN:
				transport_job.phase_wechseln(Job_Transport.PHASE_ABLIEFERN)
				(_kontext["trupp"] as Einheit_TruppMaschine).transport_job_ankommen(transport_job)
				transport_job.phase_wechseln(Job_Transport.PHASE_FERTIG)
		Job_Transport.PHASE_ABLIEFERN:
			pass
		Job_Transport.PHASE_FERTIG:
			status.job_beendet.emit()
			transport_job.zuruecksetzen()


func _bewegung_nachziehen(einheit: Dictionary, status: Einheit_Status, mood: Pop_MoodMaschine, nummer: int, delta: float, ei: int) -> void:
	## Position, Darsteller und Stimmung folgen der Bewegung noch im selben Takt.
	if status.welt_position != einheit["position"]:
		einheit["position"] = status.welt_position
		var darsteller: Einheit_Darsteller = einheit["darsteller"]
		darsteller.position = status.welt_position
		darsteller.animation_setzen(status.animation())
		darsteller.flip_h = not status.blick_richtung_rechts()
		mood.welt_position_setzen(status.welt_position)
	var ziel := mood.auf_tick(nummer, delta)
	var waerme := mood.waerme_wert()
	(status.vital as Einheit_VitalStatus).umgebungsschaden_anwenden(waerme,
		_kontext["mood_mod_registry"], _kontext["zufall"])
	if ziel != Vector2.INF and status.zustand == Einheit_Status.Zustand.IDLE:
		(_kontext["trupp"] as Einheit_TruppMaschine).in_sicherheit_bringen(einheit, ziel)
	# Die Verhaltenspruefung wird ueber die Einheiten gestreut, damit nicht alle
	# im selben Takt rechnen.
	if status.zustand == Einheit_Status.Zustand.IDLE and nummer % VERHALTEN_STREUUNG == ei % VERHALTEN_STREUUNG:
		(_kontext["verhalten"] as Einheit_VerhaltensMaschine).pruefe_verhalten(einheit, ei)


func nahrung_verteilen() -> void:
	## Die Versorgungs-Maschine besitzt die Regel; diese Maschine nur den Takt.
	var versorgung: Einheit_Versorgung = _kontext["versorgung"]
	if versorgung != null:
		versorgung.verteilen(_kontext["einheiten"])


func _aktive_karte() -> bool:
	## Inaktive Karten ticken nur jedes sechste Frame.
	var welt_world: Welt_World = _kontext["welt_world"]
	var model: Welt_Model = _kontext["model"]
	if welt_world == null or model == null:
		return true
	var aktive_map_id := welt_world.aktive_map_id()
	if aktive_map_id != "" and aktive_map_id != model.map_id:
		return Engine.get_process_frames() % GATE_TEILER == 0
	return true
