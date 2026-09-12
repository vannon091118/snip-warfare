extends RefCounted
class_name Einheit_TruppMaschine
## Trupp-Maschine: Beschreibungen, Transport-Start/Ablieferung, Sicherheit.
## Kategorie daten: Geteilter Trupp-Bestand.
var _einheiten: Array[Dictionary] = []
## Kategorie logik: Fremd-Verbindungen und Weg-Planer-Rueckruf.
var _lager: Lager_Manager = null
var _job_registry: Job_Registry = null
var _planner: Callable = Callable()
func einrichten(einheiten: Array[Dictionary]) -> void:
	_einheiten = einheiten
func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager
func job_registry_setzen(registry: Job_Registry) -> void:
	_job_registry = registry
func weg_planer_setzen(planner: Callable) -> void:
	_planner = planner
func status_bei(index: int) -> Einheit_Status:
	if index < 0 or index >= _einheiten.size():
		return null
	return _einheiten[index]["status"] as Einheit_Status
func inventar_bei(index: int) -> Einheit_Inventar:
	if index < 0 or index >= _einheiten.size():
		return null
	return _einheiten[index].get("inventar", null) as Einheit_Inventar
func beschreibung_fuer(index: int, rasse: String) -> Dictionary:
	var st := status_bei(index)
	if st == null:
		return {}
	return {"position": st.welt_position, "rasse": rasse, "zustand": st.zustand, "job_id": st.job.job_id if st.job != null else "", "ziel_index": st.aktuelles_ziel_index, "hp": st.vital.hp if st.vital != null else 0.0, "queue": st.queue_laenge()}
func auswahl_markierung_erneuern(aktiver_index: int, auswahl_liste: Array[int] = []) -> void:
	for idx in _einheiten.size():
		var d: Variant = _einheiten[idx].get("darsteller")
		if d != null and d.has_method("markierung_setzen"):
			d.markierung_setzen(idx == aktiver_index or auswahl_liste.has(idx))
func einheit_bewegen_nach(einheit_index: int, ziel_position: Vector2) -> bool:
	var status := status_bei(einheit_index)
	if status == null:
		return false
	status.geh_befehl(ziel_position)
	if _planner.is_valid():
		_planner.call(status, ziel_position)
	status.blick_richtung_setzen(ziel_position.x >= status.welt_position.x)
	var d: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	d.animation_setzen(status.animation())
	d.flip_h = not status.blick_richtung_rechts()
	return true
func transport_starten(status: Einheit_Status, lager_index: int, ziel_typ: Job_Basis.ZielTyp) -> bool:
	if _job_registry == null or _lager == null or lager_index < 0 or lager_index >= _lager.lager_zahl():
		return false
	var ei := index_von_status(status)
	if ei < 0:
		return false
	var inv: Einheit_Inventar = _einheiten[ei].get("inventar", null) as Einheit_Inventar
	if inv == null or inv.ist_leer():
		return false
	var pos: Vector2 = _lager.lager_position(lager_index)
	var job := _job_registry.job_erzeugen("transport") as Job_Transport
	if job == null:
		return false
	job.lager_index_setzen(lager_index)
	job.lager_position_setzen(pos)
	job.inventar_vorher_setzen(inv.alles_abgeben())
	status.queue_vorne_entfernen()
	status.geh_ziel_setzen(pos)
	if _planner.is_valid():
		_planner.call(status, pos)
	status.job_vergeben(job, ziel_typ, lager_index, "")
	return true
func transport_job_ankommen(job: Job_Transport) -> void:
	var pakete: Dictionary = job.inventar_vorher()
	for k: String in pakete:
		var m: int = int(pakete[k])
		if m > 0 and _lager != null:
			_lager.einlagern(k, m, job.lager_index())
func transport_fuer_idle(einheit_index: int) -> bool:
	var m: Pop_MoodMaschine = _einheiten[einheit_index].get("mood", null) if einheit_index >= 0 and einheit_index < _einheiten.size() else null
	if m == null:
		return false
	m.auf_jobwechsel("idle", "transport", "transport")
	return true
func in_sicherheit_bringen(einheit: Dictionary, ziel: Vector2) -> void:
	einheit["position"] = ziel
	(einheit["darsteller"] as Einheit_Darsteller).position = ziel
	(einheit["mood"] as Pop_MoodMaschine).welt_position_setzen(ziel)
	(einheit["status"] as Einheit_Status).welt_position_setzen(ziel)
func beute_darstellen(status: Einheit_Status) -> void:
	for e: Dictionary in _einheiten:
		if e["status"] == status:
			(e["darsteller"] as Einheit_Darsteller).animation_setzen(status.animation())
func zustand_vorher(status: Einheit_Status) -> int:
	var ei := index_von_status(status)
	return int(_einheiten[ei].get("_letzter_zustand", 0)) if ei >= 0 else 0
func zustand_merken(status: Einheit_Status) -> void:
	var ei := index_von_status(status)
	if ei >= 0:
		_einheiten[ei]["_letzter_zustand"] = status.zustand
func index_von_status(status: Einheit_Status) -> int:
	for idx in _einheiten.size():
		if _einheiten[idx]["status"] == status:
			return idx
	return -1
