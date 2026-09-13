extends RefCounted
class_name Orchestrator_Verteiler
## Verteiler der Orchestrator-Bedarfe: Er nimmt die freien Einheiten und die
## Bedarfslisten der Zonen und vergibt Jobs in der Reihenfolge der Priorität.
## Er kennt den Takt nicht, er zählt keine Stunden; er teilt nur zu, was
## ihm gereicht wird. Findet ein Bedarf kein Ziel, gibt er die Einheit frei.

var _einheit_manager: Einheit_Manager = null
var _welt_modell: Welt_Model = null
var _ziel_suche: Orchestrator_ZielSuche = null
var _job_registry: Job_Registry = null

func einrichten(einheit_manager: Einheit_Manager, welt_modell: Welt_Model, ziel_suche: Orchestrator_ZielSuche, job_registry: Job_Registry) -> void:
	_einheit_manager = einheit_manager
	_welt_modell = welt_modell
	_ziel_suche = ziel_suche
	_job_registry = job_registry

func zuteilen(zonen: Array[Dictionary], frei_einheiten: Array) -> void:
	for eintrag: Dictionary in zonen:
		var konfig: Orchestrator_Konfiguration = eintrag["konfig"]
		for bedarf: Dictionary in konfig.sortierte_bedarfe():
			if frei_einheiten.is_empty():
				break
			_bedarf_zuweisen(bedarf, konfig, frei_einheiten)

func _bedarf_zuweisen(bedarf: Dictionary, konfig: Orchestrator_Konfiguration, frei_einheiten: Array) -> void:
	var ressource := str(bedarf.get("ressource", ""))
	var job_id := str(bedarf.get("job_id", ""))
	if job_id == "" or ressource == "":
		return
	var job := _job_registry.job_erzeugen(job_id)
	if job == null:
		return
	var job_ressource := job.ressource()
	if job_ressource != "" and job_ressource != ressource:
		return
	var menge_bedarf := int(bedarf.get("menge", 0))
	var zu_weisende := frei_einheiten.size()
	if menge_bedarf > 0:
		zu_weisende = mini(zu_weisende, menge_bedarf)
	for _i in range(zu_weisende):
		if frei_einheiten.is_empty():
			break
		var einheit_idx: int = frei_einheiten.pop_front()
		var ziel_index := _ziel_suche.naechstes_objekt(ressource, konfig.position, konfig.radius)
		if ziel_index < 0:
			# Ziel nicht gefunden: Die Einheit bleibt frei für den nächsten Bedarf.
			frei_einheiten.append(einheit_idx)
			continue
		_einheit_manager.job_vergeben(einheit_idx, job_id, Job_Basis.ZielTyp.OBJEKT, ziel_index, _welt_modell.objekt_position(ziel_index))
