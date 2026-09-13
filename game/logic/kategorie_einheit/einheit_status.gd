extends RefCounted
class_name Einheit_Status
## Zustandsmaschine einer Einheit: IDLE, GEHEN und ARBEITEN. Sie hält Zustand,
## Position, Vital und Blick; Weg, Warteschlange und Regie tragen eigene Klassen.

signal zustand_geaendert(neuer_zustand: Zustand)
signal gestorben(welt_position: Vector2)

## Meldungen sind bewusst Vertrags-Signale: verbunden an der Einwanderungs-Maschine, emittiert in der Auftrags-Regie.
signal arbeitsschritt_erledigt(ressource: String, menge: int)
signal job_beendet()
signal job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int)
## Ebenso bewusst: dieser Ruf gehört der Domäne und wird von außen bedient.
signal job_vergeben_fehlgeschlagen(grund: String)
signal naechster_job_aus_queue(job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String)

enum Zustand {
	IDLE,
	GEHEN,
	ARBEITEN,
}

var zustand: Zustand = Zustand.IDLE
var job: Job_Basis = null
var aktuelles_ziel_typ: Job_Basis.ZielTyp = Job_Basis.ZielTyp.OBJEKT
var aktuelles_ziel_index: int = -1
var ziel_ressource: String = ""
var welt_position := Vector2.ZERO
var vital: Einheit_VitalStatus = Einheit_VitalStatus.new()
var queue := Einheit_JobQueue.new()
var bewegung := Einheit_Bewegung.new()
var _blick_rechts: bool = true
var _loop_fortgesetzt: bool = false
var _regie: Einheit_JobRegie = null

func _init() -> void:
	_regie = Einheit_JobRegie.new(self)
	vital.gestorben.connect(_auf_eigenen_tod)

func ist_beschaeftigt() -> bool:
	return zustand == Zustand.ARBEITEN or zustand == Zustand.GEHEN

func animation() -> String:
	if zustand == Zustand.IDLE:
		return "idle"
	if zustand == Zustand.GEHEN:
		return "laufen"
	return job.animation() if job != null else "idle"

func blick_richtung_rechts() -> bool:
	return _blick_rechts

func blick_richtung_setzen(rechts: bool) -> void:
	_blick_rechts = rechts

func welt_position_setzen(pos: Vector2) -> void:
	welt_position = pos
	vital.welt_position_setzen(pos)

func geh_ziel_setzen(ziel: Vector2) -> void:
	bewegung.ziel_setzen(ziel)

func weg_ziele_uebernehmen(le_ziele: PackedVector2Array) -> void:
	bewegung.wegpunkte_uebernehmen(le_ziele)

func tick(delta: float) -> void:
	vital.heilung_versuchen()
	if zustand == Zustand.GEHEN:
		_geh_tick(delta)
	elif zustand == Zustand.ARBEITEN:
		_regie.arbeit_tick()

func _geh_tick(delta: float) -> void:
	# Bewegung in der Welt: Erst die Wegpunkte der Planung, dann der Endschritt.
	bewegung.wegpunkte_ablaufen(welt_position)
	if bewegung.am_ziel(welt_position):
		_zu_zustand_wechseln(Zustand.ARBEITEN if job != null else Zustand.IDLE)
		return
	var richtung := bewegung.richtung(welt_position)
	welt_position += richtung * bewegung.tempo() * delta
	_blick_rechts = richtung.x >= 0.0

func geh_befehl(ziel: Vector2) -> void:
	# Marschbefehl: Laufender Job wird abgebrochen, das Geh-Ziel gesetzt.
	_auftrag_loeschen()
	bewegung.ziel_setzen(ziel)
	_zu_zustand_wechseln(Zustand.IDLE if bewegung.am_ziel(welt_position) else Zustand.GEHEN)

func job_vergeben(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> bool:
	return _regie.vergeben(neuer_job, ziel_typ, ziel_index, ressource)

func job_loopy_fortsetzen(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	_regie.loopy_fortsetzen(neuer_job, ziel_typ, ziel_index, ressource)

func job_abbrechen() -> void:
	_auftrag_loeschen()
	bewegung.wegpunkte_loeschen()
	_zu_zustand_wechseln(Zustand.IDLE)

func _auftrag_loeschen() -> void:
	job = null
	aktuelles_ziel_typ = Job_Basis.ZielTyp.OBJEKT
	aktuelles_ziel_index = -1
	ziel_ressource = ""
	_loop_fortgesetzt = false

func _zu_zustand_wechseln(neuer_zustand: Zustand) -> void:
	if zustand == neuer_zustand:
		return
	zustand = neuer_zustand
	zustand_geaendert.emit(neuer_zustand)

func _auf_eigenen_tod(tod_position: Vector2) -> void:
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_gestorben(tod_position, "einheit", true)
	gestorben.emit(tod_position)
	job_abbrechen()
