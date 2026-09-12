extends RefCounted
class_name Job_Basis
## Basisklasse aller Jobs: Sie haelt Kennung, Konfiguration, Fortschritt und Ziel-Listen.

signal arbeitsschritt_erledigt(ressource: String, menge: int)
# Wird von Unterklassen und dem Status verbunden, hier selbst nicht emittiert:
# bewusst als Vertrag markiert statt versteckt.
@warning_ignore("unused_signal")
signal job_beendet()

enum ZielTyp { OBJEKT, TIER, OWN }

## Kategorie daten: Job-Konfiguration, Fortschritt und Ziel-Listen.
var job_id: String = ""
var konfiguration: Dictionary = {}
var fortlaufende_ticks: int = 0
var _ziel_faktor: float = 1.0
var _ziel_objekte: Array[String] = []
var _ziel_tiere: Array[String] = []

## Kategorie logik: Einrichten, Ziel-Pruefung und Weiterreichen der Rechnungen.
func einrichten(neue_job_id: String, neue_konfiguration: Dictionary) -> void:
	job_id = neue_job_id
	konfiguration = neue_konfiguration
	_ziel_objekte = Job_Konfiguration.ziel_array(konfiguration, "ziel_objekte", "ziel_element_ids")
	_ziel_tiere = Job_Konfiguration.ziel_array(konfiguration, "ziel_tiere", "ziel_tier_ids")

func name() -> String:
	return Job_Konfiguration.name(konfiguration, job_id)
func ist_loop() -> bool:
	return Job_Konfiguration.ist_loop(konfiguration)
func ressource() -> String:
	return Job_Konfiguration.ressource(konfiguration)
func animation() -> String:
	return Job_Konfiguration.animation(konfiguration)
func reichweite() -> float:
	return Job_Konfiguration.reichweite(konfiguration)
func logik_id() -> String:
	return Job_Konfiguration.logik_id(konfiguration)
func modifikator_id() -> String:
	return Job_Konfiguration.modifikator_id(konfiguration)
func faktor() -> float:
	return clampf(Job_Konfiguration.faktor(konfiguration), 0.1, 10.0)
func ziel_typ() -> ZielTyp:
	# Unterklassen melden, ob sie Objekt, Tier oder Artgenossen bearbeiten.
	return ZielTyp.OBJEKT
func passt_zu_objekt(element_id: String) -> bool:
	return Job_ZielPruefung.passt_objekt(_ziel_objekte, element_id, self)
func _passt_zu_objekt_fallback(_element_id: String) -> bool:
	return false
func passt_zu_tier(tier_id: String) -> bool:
	return Job_ZielPruefung.passt_tier(_ziel_tiere, tier_id, self)
func _passt_zu_tier_fallback(_tier_id: String) -> bool:
	return false
func ziel_faktor_setzen(neuer_zielfaktor: float) -> void:
	# G1: Der Faktor des Ziels teilt die Arbeitszeit; ueber eins heisst schneller.
	_ziel_faktor = clampf(neuer_zielfaktor, 0.1, 10.0)
func ticks_fuer_faktor() -> int:
	return Job_ZeitRechnung.ticks_fuer_faktor(faktor())
func harvest_zeit_ticks() -> int:
	return Job_ZeitRechnung.harvest_zeit_ticks(konfiguration, faktor(), _ziel_faktor)
func startet_neu() -> void:
	fortlaufende_ticks = 0
func schritt_vorruecken() -> bool:
	# Zaehlt einen Arbeitstick hoch; true heisst, ein Arbeitsschritt ist fertig.
	fortlaufende_ticks += 1
	if fortlaufende_ticks >= harvest_zeit_ticks():
		startet_neu()
		return true
	return false
func arbeitsschritt(ziel_ressource: String) -> void:
	arbeitsschritt_erledigt.emit(ziel_ressource, Job_Konfiguration.harvest_menge(konfiguration))
func kann_ausgefuehrt_werden_von(vital: Einheit_VitalStatus) -> bool:
	return Job_FaehigkeitsPruefung.kann(konfiguration, job_id, vital)
