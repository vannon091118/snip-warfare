extends RefCounted
class_name Job_Registry
## Registry aller Jobs. Die Konfiguration kommt zentral aus
## game/data/job_config.json, jeder Job liegt als eigenes Skript vor.
## Neue Jobs werden hier nur in _job_erzeugen registriert.

const KONFIG_PFAD := "res://game/data/job_config.json"

## Kategorie daten: die geladene Konfiguration, ausschließlich gelesen.
var job_konfigurationen: Dictionary = {}

## Kategorie logik: Erzeugung und Zugriff auf die Job-Objekte.

func _init() -> void:
	if FileAccess.file_exists(KONFIG_PFAD):
		var datei := FileAccess.open(KONFIG_PFAD, FileAccess.READ)
		var gelesen: Variant = JSON.parse_string(datei.get_as_text())
		if typeof(gelesen) == TYPE_DICTIONARY:
			job_konfigurationen = gelesen
	else:
		push_warning("Job-Konfiguration nicht gefunden: %s" % KONFIG_PFAD)

func job_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in job_konfigurationen.keys():
		ids.append(id)
	return ids

func job_name(job_id: String) -> String:
	if not job_konfigurationen.has(job_id):
		return job_id
	return str(job_konfigurationen[job_id].get("name", job_id))

func ressource_fuer_job(job_id: String) -> String:
	if not job_konfigurationen.has(job_id):
		return ""
	return str(job_konfigurationen[job_id].get("ressource", ""))

func job_erzeugen(job_id: String) -> Job_Basis:
	var job := _job_erzeugen(job_id)
	if job == null:
		push_warning("Unbekannter Job: %s" % job_id)
		return null
	job.einrichten(job_id, job_konfigurationen.get(job_id, {}))
	return job

func _job_erzeugen(job_id: String) -> Job_Basis:
	# Zentrale Anlaufstelle: hier wird jeder neue Job registriert.
	match job_id:
		"holzfaeller":
			return Job_Holzfaeller.new()
		"steinmetz":
			return Job_Steinmetz.new()
		"jaeger":
			return Job_Jaeger.new()
	return null
