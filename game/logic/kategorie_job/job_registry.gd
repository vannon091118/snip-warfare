extends RefCounted
class_name Job_Registry
## Registry aller Jobs. Die Konfiguration kommt zentral aus
## game/data/job_config.json, jeder Job liegt als eigenes Skript vor.
## Plugin-Grenze: Ein neuer Job braucht kein Berühren dieser Klasse mehr,
## er registriert sich über das Feld script in job_config.json; die
## zentrale Zuordnung dient nur noch als Übergangs-Fallback für Einträge
## ohne script-Feld.

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
	# Plugin-Zuordnung: Das script-Feld aus der Konfiguration bestimmt die
	# Klasse; nur Einträge ohne script-Feld fallen auf die zentrale Zuordnung
	# zurück. ResourceLoader.exists verhindert Halluzinationen bei Tippfehlern.
	var konfig: Dictionary = job_konfigurationen.get(job_id, {})
	var skript_pfad := str(konfig.get("script", ""))
	if skript_pfad != "":
		if not ResourceLoader.exists(skript_pfad):
			push_warning("Job-Skript fehlt: %s" % skript_pfad)
			return null
		var skript: GDScript = load(skript_pfad)
		if skript != null:
			var objekt: Variant = skript.new()
			if objekt is Job_Basis:
				return objekt as Job_Basis
			push_warning("Job-Skript ist kein Job_Basis: %s" % skript_pfad)
			return null
	# Übergangs-Fallback: zentrale Zuordnung für Einträge ohne script-Feld.
	match job_id:
		"holzfaeller":
			return Job_Holzfaeller.new()
		"steinmetz":
			return Job_Steinmetz.new()
		"jaeger":
			return Job_Jaeger.new()
		"holzfaeller_stumpf":
			return Job_HolzfaellerStumpf.new()
		"jaeger_kadaver":
			return Job_JaegerKadaver.new()
		"heiler":
			return Job_Heiler.new()
		"beeren_sammler":
			return Job_BeerenSammler.new()
	return null