extends RefCounted
class_name Einheit_JobVergabeMaschine
## Vergabe-Maschine der Einheiten-Domäne: Setzt einen neuen Job auf eine
## Einheit oder merkt ihn an ihrer eigenen Queue vor, wenn sie beschäftigt
## ist. Genau eine Verantwortung: Der Übergang von Spieler-Auftrag zu
## Status-Zustand. Kein Tick, keine Ernte, kein Weg; der Manager reicht
## nur die Beteiligten herein.

## Kategorie daten: die Beteiligten der Vergabe.
var _einheiten: Array[Dictionary] = []
var _job_registry: Job_Registry = null
var _ziel_suche: Einheit_ZielSuche = null
var _planner: Callable = Callable()

func einrichten(einheiten: Array[Dictionary], job_registry: Job_Registry, ziel_suche: Einheit_ZielSuche, planner: Callable) -> void:
	_einheiten = einheiten
	_job_registry = job_registry
	_ziel_suche = ziel_suche
	_planner = planner

## Kategorie logik: Vergabe und Queue-Vormerkung.

func vergeben(einheit_index: int, job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ziel_position: Vector2) -> bool:
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return false
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	var job := _job_registry.job_erzeugen(job_id)
	if job == null:
		return false
	# G1: Der effektive Faktor des Ziels skaliert die Arbeitszeit des Jobs.
	job.ziel_faktor_setzen(_ziel_suche.ziel_faktor_fuer(ziel_typ, ziel_index))
	var ressource := job.ressource()
	if status.zustand == Einheit_Status.Zustand.ARBEITEN or status.zustand == Einheit_Status.Zustand.GEHEN:
		# Beschäftigt: Auftrag wird an die eigene Queue der Einheit gehängt;
		# der Job wird erst beim Start über die Registry erzeugt.
		status.queue.vormerken(job_id, ziel_typ, ziel_index, ressource)
		return true
	status.geh_ziel_setzen(ziel_position)
	if _planner.is_valid():
		_planner.call(status, ziel_position)
	status.job_vergeben(job, ziel_typ, ziel_index, ressource)
	return true

func blick_richtung_tragen(einheit_index: int, ziel_position: Vector2) -> void:
	# Die Blickrichtung zeigt zum gewählten Job-Objekt; der Manager trägt
	# den Rest (Animation und Darsteller-Flips) nach dem Vergabe-Ruf.
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	status.blick_richtung_setzen(ziel_position.x >= _einheiten[einheit_index].get("position", Vector2.ZERO).x)
