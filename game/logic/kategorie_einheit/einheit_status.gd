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
signal naechster_job_aus_queue(job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String)
signal gestorben(welt_position: Vector2)

enum Zustand {
	IDLE,
	GEHEN,
	ARBEITEN,
}

## Kategorie daten: Job-Zustand, eigene Warteschlange und die Vital-Maschine.
var zustand: Zustand = Zustand.IDLE
var job: Job_Basis = null
var aktuelles_ziel_typ: Job_Basis.ZielTyp = Job_Basis.ZielTyp.OBJEKT
var aktuelles_ziel_index: int = -1
var ziel_ressource: String = ""
var _blick_rechts: bool = true
var _loop_fortgesetzt: bool = false
var vital: Einheit_VitalStatus = Einheit_VitalStatus.new()

## Eigene Job-Queue: Jeder Stickman sammelt seine Aufträge selbst und führt
## sie nacheinander aus. Ein Eintrag ist eine Vormerkung, der Job selbst wird
## erst beim Start über die Registry erzeugt.
var _job_queue: Array[Dictionary] = []

## Bewegung: Der GEHEN-Zustand bewegt die Einheit in der Welt (kein Teleport),
## die Geschwindigkeit kommt aus der zentralen Steuerungskonfiguration.
var welt_position := Vector2.ZERO
var _geh_ziel := Vector2.ZERO
var _geh_geschwindigkeit := 70.0
var _geh_reichweite := 24.0

## Kategorie logik: Jobvergabe mit Vitalprüfung, Arbeitsloop und Vitaltick.

func ist_beschaeftigt() -> bool:
	return zustand == Zustand.ARBEITEN or zustand == Zustand.GEHEN

func animation() -> String:
	match zustand:
		Zustand.IDLE:
			return "idle"
		Zustand.GEHEN:
			return "laufen"
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
	if zustand == Zustand.ARBEITEN or zustand == Zustand.GEHEN:
		# Einheit beschäftigt: Auftrag wird hinten an die eigene Queue gehängt
		# und erst nach dem aktiven Job gestartet.
		job_vormerken(neuer_job.job_id, ziel_typ, ziel_index, ressource)
		return true
	job = neuer_job
	aktuelles_ziel_typ = ziel_typ
	aktuelles_ziel_index = ziel_index
	ziel_ressource = ressource
	job.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	job.job_beendet.connect(_auf_job_beendet)
	job.startet_neu()
	_arbeit_oder_gehen()
	return true

func job_vormerken(job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	# Nur eine Vormerkung pro Auftrag: Wer denselben Job und dasselbe Ziel
	# schon in der Queue hat, bekommt keinen doppelten Eintrag.
	for eintrag: Dictionary in _job_queue:
		if str(eintrag.get("job_id", "")) == job_id \
				and int(eintrag.get("ziel_typ", -1)) == int(ziel_typ) \
				and int(eintrag.get("ziel_index", -1)) == ziel_index:
			return
	_job_queue.append({
		"job_id": job_id,
		"ziel_typ": int(ziel_typ),
		"ziel_index": ziel_index,
		"ressource": ressource,
	})

func queue_laenge() -> int:
	return _job_queue.size()

func queue_naechster() -> Dictionary:
	# Holt die älteste Vormerkung, ohne sie zu entfernen; der Aufrufer
	# (Manager) erzeugt den Job und startet ihn über job_vergeben.
	if _job_queue.is_empty():
		return {}
	return _job_queue[0].duplicate(true)

func queue_vorne_entfernen() -> void:
	# Entfernt die älteste Vormerkung, nachdem der Manager den Job erzeugt
	# und gestartet hat. Die Queue ist Eigentum der Einheit.
	if not _job_queue.is_empty():
		_job_queue.remove_at(0)

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
	welt_position = pos
	vital.welt_position_setzen(pos)

func geh_ziel_setzen(ziel: Vector2) -> void:
	_geh_ziel = ziel

func tick(delta: float) -> void:
	vital.heilung_versuchen()
	match zustand:
		Zustand.IDLE:
			pass
		Zustand.GEHEN:
			_geh_tick(delta)
		Zustand.ARBEITEN:
			_arbeit_tick(delta)

func ziel_welt_position() -> Vector2:
	# Zielposition für die Bewegung: Objekt oder Tier; ohne Modellzugriff
	# bleibt der zuletzt gesetzte Punkt.
	return _geh_ziel

func _arbeit_oder_gehen() -> void:
	# Direkte Auswirkung des Befehls: Zu weit entfernte Ziele laufen die
	# Einheiten an, statt den Befehl mit einer Meldung abzulehnen.
	if job == null:
		return
	if welt_position.distance_to(_geh_ziel) > _geh_reichweite:
		_zu_zustand_wechseln(Zustand.GEHEN)
	else:
		_zu_zustand_wechseln(Zustand.ARBEITEN)

func _geh_tick(delta: float) -> void:
	# Bewegung in der Welt: Schritt Richtung Ziel, dann Zustandsübergang.
	var richtung := _geh_ziel - welt_position
	var distanz := richtung.length()
	if distanz <= _geh_reichweite or distanz <= 0.001:
		_zu_zustand_wechseln(Zustand.ARBEITEN)
		return
	welt_position += richtung.normalized() * _geh_geschwindigkeit * delta
	_blick_rechts = richtung.x >= 0.0

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
	# Eigene Queue: Der nächste vorgemerkte Auftrag wird dem Manager gemeldet
	# und startet, sobald er ihn erzeugt hat. Leere Queue heißt Idle.
	if not _job_queue.is_empty():
		var naechster := queue_naechster()
		naechster_job_aus_queue.emit(str(naechster.get("job_id", "")),
			int(naechster.get("ziel_typ", 0)),
			int(naechster.get("ziel_index", -1)),
			str(naechster.get("ressource", "")))

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
