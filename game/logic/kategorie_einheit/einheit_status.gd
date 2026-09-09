extends RefCounted
class_name Einheit_Status
## Zustandsmaschine einer Strichmännchen-Einheit.
## Zustände: IDLE und ARBEITEN. Die Einheit bewegt sich in diesen Zuständen
## niemals selbst; Bewegungen legt ausschließlich der Spieler fest.
## Werte kommen aus den zentralen Konfigurationen, nichts ist hart codiert.
##
## Phase 3.3: Physische Modifikatoren (Verletzungen, Buffs, Debuffs) + Validierung
## Verwaltet aktive Modifikatoren, berechnet effektive Werte, prüft Job-Fähigkeit.

signal zustand_geaendert(neuer_zustand: Zustand)
signal arbeitsschritt_erledigt(ressource: String, menge: int)
signal job_beendet()
signal job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int)
signal modifikator_geandert(modifikator_id: String, hinzugefuegt: bool)
signal hp_veraendert(aktuell: int, max: int)
signal job_vergeben_fehlgeschlagen(grund: String)

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
var hp: int = 100
var max_hp: int = 100
var _welt_position: Vector2 = Vector2.ZERO

## Physische Basiswerte
var basis_geschwindigkeit: float = 1.0
var basis_tragekraft: int = 10

## Aktive Modifikatoren (Verletzungen, Buffs, Debuffs)
var aktive_modifikatoren: Array[Kern_ModifikatorBasis] = []

## Effektive Werte (nach Modifikator-Berechnung)
var effektive_geschwindigkeit: float = 1.0
var effektive_tragekraft: int = 10

func _ready() -> void:
	_effektive_werte_berechnen()

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

func job_vergeben(neuer_job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	if neuer_job == null:
		job_vergeben_fehlgeschlagen.emit("Kein Job übergeben")
		return

	if _job_blockiert_durch_modifikatoren(neuer_job.job_id):
		var blocker_name := _blockierender_modifikator_name(neuer_job.job_id)
		job_vergeben_fehlgeschlagen.emit("Verletzung blockiert Job: " + blocker_name)
		return

	if not neuer_job.kann_ausgefuehrt_werden_von(self):
		job_vergeben_fehlgeschlagen.emit("Physische Voraussetzungen nicht erfüllt für: " + neuer_job.name())
		return

	job = neuer_job
	aktuelles_ziel_typ = ziel_typ
	aktuelles_ziel_index = ziel_index
	ziel_ressource = ressource
	_zu_zustand_wechseln(Zustand.ARBEITEN)
	job.startet_neu()
	job.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	job.job_beendet.connect(_auf_job_beendet)

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
	_welt_position = pos

func modifikator_hinzufuegen(mod_id: String) -> void:
	var mod := Kern_ModifikatorRegistry.modifikator_erzeugen(mod_id)
	if mod:
		aktive_modifikatoren.append(mod)
		_effektive_werte_berechnen()
		modifikator_geandert.emit(mod_id, true)

func modifikator_entfernen(mod_id: String) -> void:
	aktive_modifikatoren = aktive_modifikatoren.find_all(func(m: Kern_ModifikatorBasis): return m.name != mod_id)
	_effektive_werte_berechnen()
	modifikator_geandert.emit(mod_id, false)

func hat_modifikator(mod_id: String) -> bool:
	for mod in aktive_modifikatoren:
		if mod.name == mod_id:
			return true
	return false

func _effektive_werte_berechnen() -> void:
	effektive_geschwindigkeit = basis_geschwindigkeit
	effektive_tragekraft = basis_tragekraft

	for mod in aktive_modifikatoren:
		effektive_geschwindigkeit *= mod.faktor
		if mod.attribute_modifikation.has("geschwindigkeit"):
			effektive_geschwindigkeit += float(mod.attribute_modifikation["geschwindigkeit"])
		if mod.attribute_modifikation.has("tragekraft"):
			effektive_tragekraft += int(mod.attribute_modifikation["tragekraft"])

	effektive_geschwindigkeit = maxf(effektive_geschwindigkeit, 0.1)
	effektive_tragekraft = maxi(effektive_tragekraft, 0)

func _job_blockiert_durch_modifikatoren(job_id: String) -> bool:
	for mod in aktive_modifikatoren:
		if mod.typ == Kern_ModifikatorBasis.ModifikatorTyp.VERLETZUNG:
			if job_id in mod.job_einschraenkungen:
				return true
	return false

func _blockierender_modifikator_name(job_id: String) -> String:
	for mod in aktive_modifikatoren:
		if mod.typ == Kern_ModifikatorBasis.ModifikatorTyp.VERLETZUNG:
			if job_id in mod.job_einschraenkungen:
				return mod.name
	return "unbekannt"

func schaden_nehmen(schaden: int, art: String = "physisch") -> int:
	if hp <= 0:
		return 0
	var verbraucht := mini(schaden, hp)
	hp -= verbraucht
	Kern_SignalBus.schaden_erhalten.emit(_welt_position, verbraucht, art)
	hp_veraendert.emit(hp, max_hp)

	if art == "sturz" and randf() < 0.3:
		modifikator_hinzufuegen("verletzung_bein")
	elif art == "kampf" and randf() < 0.2:
		modifikator_hinzufuegen("verletzung_arm")
	elif schaden > max_hp * 0.5 and randf() < 0.4:
		modifikator_hinzufuegen("verblutung")

	if hp <= 0:
		_sterben()
	return verbraucht

func heilung_versuchen() -> void:
	var zu_entfernen: Array[String] = []
	for mod in aktive_modifikatoren:
		if mod.heilbar and mod.dauer_ticks <= 0:
			zu_entfernen.append(mod.name)
		elif mod.heilbar and mod.dauer_ticks > 0:
			mod.tick_zaehlen()
			if mod.dauer_ticks <= 0:
				zu_entfernen.append(mod.name)

	for mod_id in zu_entfernen:
		modifikator_entfernen(mod_id)

func tick(delta: float) -> void:
	heilung_versuchen()

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

func _sterben() -> void:
	Kern_SignalBus.gestorben.emit(_welt_position, "einheit", true)
	job_abbrechen()