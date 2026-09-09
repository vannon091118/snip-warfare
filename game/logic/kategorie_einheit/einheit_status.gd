extends RefCounted
class_name Einheit_Status
## Zustandsmaschine einer Strichmännchen-Einheit.
## Zustände: IDLE und ARBEITEN. Die Einheit bewegt sich in diesen Zuständen
## niemals selbst; Bewegungen legt ausschließlich der Spieler fest.
## Werte kommen aus den zentralen Konfigurationen, nichts ist hart codiert.
## Lebenspunkte und physische Modifikatoren liegen in der eigenen
## Einheit_VitalStatus-Maschine; diese Maschine prüft bei der Jobvergabe
## nur deren Aussagen und führt sonst keine Vitallogik.

signal zustand_geaendert(neuer_zustand: Zustand)
signal arbeitsschritt_erledigt(ressource: String, menge: int)
signal job_beendet()
signal job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int)
signal job_vergeben_fehlgeschlagen(grund: String)
signal gestorben(welt_position: Vector2)

enum Zustand {
	IDLE,
	ARBEITEN,
}

## Kategorie daten: Job-Zustand und die eigene Vital-Maschine.
var zustand: Zustand = Zustand.IDLE
var job: Job_Basis = null
var aktuelles_ziel_typ: Job_Basis.ZielTyp = Job_Basis.ZielTyp.OBJEKT
var aktuelles_ziel_index: int = -1
var ziel_ressource: String = ""
var _blick_rechts: bool = true
var _loop_fortgesetzt: bool = false
var vital: Einheit_VitalStatus = Einheit_VitalStatus.new()

## Kategorie logik: Jobvergabe mit Vitalprüfung, Arbeitsloop und Vitaltick.

func ist_beschaeftigt() -> bool:
	return zustand == Zustand.ARBEITEN

func animation() -> String:
	match zustand:
		Zustand.IDLE:
			return "idle"
		Zustand.ARBEITEN:
			if job != null:
				return job.animation()
	return "idle"

func blick_richtung_rechts() -> bool:
	return _blick_rechts

func blick_richtung_setzen(rechts: bool) -> void:
	_blick_rechts = rechts

func job_vergeben(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> bool:
	# Die Vergabe prüft die Aussagen der Vital-Maschine und der Job-Konfig;
	# scheitert sie, bleibt der alte Zustand unberührt und es wird gemeldet.
	if neuer_job == null:
		job_vergeben_fehlgeschlagen.emit("Kein Job übergeben")
		return false
	var blocker := vital.blockiert_job(neuer_job.job_id)
	if blocker != "":
		job_vergeben_fehlgeschlagen.emit("Verletzung blockiert Job: " + blocker)
		return false
	if not neuer_job.kann_ausgefuehrt_werden_von(vital):
		job_vergeben_fehlgeschlagen.emit("Physische Voraussetzungen nicht erfüllt für: " + neuer_job.name())
		return false
	job = neuer_job
	aktuelles_ziel_typ = ziel_typ
	aktuelles_ziel_index = ziel_index
	ziel_ressource = ressource
	_zu_zustand_wechseln(Zustand.ARBEITEN)
	job.startet_neu()
	job.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	job.job_beendet.connect(_auf_job_beendet)
	return true

func job_loopy_fortsetzen(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	if job != neuer_job:
		return
	aktuelles_ziel_typ = ziel_typ
	aktuelles_ziel_index = ziel_index
	ziel_ressource = ressource
	_loop_fortgesetzt = true
	job.startet_neu()

func job_abbrechen() -> void:
	job = null
	aktuelles_ziel_typ = Job_Basis.ZielTyp.OBJEKT
	aktuelles_ziel_index = -1
	ziel_ressource = ""
	_loop_fortgesetzt = false
	_zu_zustand_wechseln(Zustand.IDLE)

func welt_position_setzen(pos: Vector2) -> void:
	vital.welt_position_setzen(pos)

func tick(delta: float) -> void:
	vital.heilung_versuchen()
	match zustand:
		Zustand.IDLE:
			pass
		Zustand.ARBEITEN:
			_arbeit_tick(delta)

func _arbeit_tick(_delta: float) -> void:
	if job == null:
		_zu_zustand_wechseln(Zustand.IDLE)
		return
	if job.schritt_vorruecken():
		job.arbeitsschritt(ziel_ressource)

func _auf_arbeitsschritt(ressource: String, menge: int) -> void:
	arbeitsschritt_erledigt.emit(ressource, menge)

func _auf_job_beendet() -> void:
	if job != null and job.ist_loop():
		_loop_fortgesetzt = false
		job_loop_gefragt.emit(job, aktuelles_ziel_typ, aktuelles_ziel_index)
		if _loop_fortgesetzt:
			return
	job_beendet.emit()
	job_abbrechen()

func _zu_zustand_wechseln(neuer_zustand: Zustand) -> void:
	if zustand == neuer_zustand:
		return
	zustand = neuer_zustand
	zustand_geaendert.emit(neuer_zustand)

func _init() -> void:
	# Der Tod der Vital-Maschine endet den Job und meldet nach oben.
	vital.gestorben.connect(_auf_eigenen_tod)

func _auf_eigenen_tod(welt_position: Vector2) -> void:
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus.gestorben.emit(welt_position, "einheit", true)
	gestorben.emit(welt_position)
	job_abbrechen()
