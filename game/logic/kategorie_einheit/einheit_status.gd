extends RefCounted
class_name Einheit_Status
## Zustandsmaschine einer Strichmännchen-Einheit.
## Zustände: IDLE und ARBEITEN. Die Einheit bewegt sich in diesen Zuständen
## niemals selbst; Bewegungen legt ausschließlich der Spieler fest.
## Werte kommen aus den zentralen Konfigurationen, nichts ist hart codiert.

signal zustand_geaendert(neuer_zustand: Zustand)
signal arbeitsschritt_erledigt(ressource: String, menge: int)
signal job_beendet()
signal job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int)

enum Zustand {
	IDLE,
	ARBEITEN,
}

var zustand: Zustand = Zustand.IDLE
var job: Job_Basis = null
var aktuelles_ziel_typ: Job_Basis.ZielTyp = Job_Basis.ZielTyp.OBJEKT
var aktuelles_ziel_index: int = -1
var ziel_ressource: String = ""
var _blick_rechts: bool = true
var _loop_fortgesetzt: bool = false

func ist_beschaeftigt() -> bool:
	return zustand == Zustand.ARBEITEN

func animation() -> String:
	# Der Darsteller fragt die passende Animation hier an.
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
	# Wird vom Spieler bzw. von der Auswahl des Job-Objekts festgelegt.
	_blick_rechts = rechts

func job_vergeben(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	# Der Spieler legt den Job durch Auswahl des Job-Objekts fest.
	job = neuer_job
	aktuelles_ziel_typ = ziel_typ
	aktuelles_ziel_index = ziel_index
	ziel_ressource = ressource
	_zu_zustand_wechseln(Zustand.ARBEITEN)
	job.startet_neu()
	job.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	job.job_beendet.connect(_auf_job_beendet)

func job_loopy_fortsetzen(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	# Antwort der Manager-Ebene auf job_loop_gefragt: derselbe Job laeuft
	# mit frischem Ziel weiter, ohne den Zustand zurueckzugeben.
	if job != neuer_job:
		return
	aktuelles_ziel_typ = ziel_typ
	aktuelles_ziel_index = ziel_index
	ziel_ressource = ressource
	_loop_fortgesetzt = true
	job.startet_neu()

func job_abbrechen() -> void:
	# Das Ende des Jobs: alle Zielwerte fallen auf leer, der Zustand geht in den Idle.
	job = null
	aktuelles_ziel_typ = Job_Basis.ZielTyp.OBJEKT
	aktuelles_ziel_index = -1
	ziel_ressource = ""
	_loop_fortgesetzt = false
	_zu_zustand_wechseln(Zustand.IDLE)

func tick(delta: float) -> void:
	match zustand:
		Zustand.IDLE:
			# Idle bewegt sich niemals; es passiert hier nichts.
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
	# Kein logischer Kreislauf nach unten: Das Job-Ende wird einmal nach oben
	# konsumiert. Ein Loop-Job fragt als neuer Zustandsschritt nach dem
	# naechsten Ziel; antwortet der Manager nicht, faellt die Einheit in den Idle.
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
