extends RefCounted
class_name Job_Basis
## Basisklasse aller Jobs. Ein Job beschreibt, woran eine Einheit arbeitet,
## welche Animation dabei läuft und was nach Ablauf der Harvest-Zeit passiert.
## Alle konkreten Werte (Harvest-Zeit, Menge, Reichweite) stehen zentral in
## game/data/job_config.json; die Unterklassen entscheiden nur über das Ziel.
##
## Erweiterbar: Neue Jobs erben von Job_Basis, überschreiben ziel_typ() und
## melden sich in der Job_Registry an. Diese Klasse ändert sich dabei nicht.
##
## Physische Fähigkeit: Jeder Job liest seine Anforderungen aus der zentralen
## Konfiguration und prüft sie gegen die Aussagen der Vital-Maschine.
##
## Phase 3.3: Validierung ob Einheit physisch fähig ist, Job auszuführen.

signal arbeitsschritt_erledigt(ressource: String, menge: int)
# Wird von Unterklassen und dem Status verbunden, in dieser Klasse selbst
# nicht emittiert: bewusst als Vertrag markiert statt versteckt.
@warning_ignore("unused_signal")
signal job_beendet()

enum ZielTyp {
	OBJEKT,
	TIER,
}

## Kategorie daten: Job-Konfiguration und Ziel-Listen aus der Registry.
var job_id: String = ""
var konfiguration: Dictionary = {}
var fortlaufende_ticks: int = 0
var _logik_id: String = ""
var _modifikator_id: String = "normal"
var _faktor: float = 1.0
var _loop: bool = false
var _ziel_objekte: Array[String] = []
var _ziel_tiere: Array[String] = []

## Kategorie logik: Einrichten, Ziel-Prüfung und Zeit-Umrechnung.
func einrichten(neue_job_id: String, neue_konfiguration: Dictionary) -> void:
	job_id = neue_job_id
	konfiguration = neue_konfiguration
	_logik_id = str(konfiguration.get("logik_id", ""))
	_modifikator_id = str(konfiguration.get("modifikator_id", "normal"))
	_faktor = float(konfiguration.get("faktor", 1.0))
	_loop = bool(konfiguration.get("loop", false))
	_ziel_objekte = _lese_ziel_array("ziel_objekte", "ziel_element_ids")
	_ziel_tiere = _lese_ziel_array("ziel_tiere", "ziel_tier_ids")

func _lese_ziel_array(haupt: String, fallback: String) -> Array[String]:
	var roh: Variant = konfiguration.get(haupt, konfiguration.get(fallback, []))
	var typisiert: Array[String] = []
	if typeof(roh) == TYPE_ARRAY:
		for wert: Variant in roh as Array:
			typisiert.append(str(wert))
	return typisiert

func name() -> String:
	return str(konfiguration.get("name", job_id.capitalize()))

func ziel_typ() -> ZielTyp:
	# Unterklassen geben an, ob sie ein Weltobjekt oder ein Tier bearbeiten.
	return ZielTyp.OBJEKT

func ist_loop() -> bool:
	# Ein Loop-Job ist eine automatische Folge: Der Status sucht nach jedem
	# Abschluss das naechste gueltige Ziel desselben Typs, kein Einmal-Job.
	return _loop

func passt_zu_objekt(element_id: String) -> bool:
	if not _ziel_objekte.is_empty():
		return _ziel_objekte.has(element_id)
	return _passt_zu_objekt_fallback(element_id)

func _passt_zu_objekt_fallback(_element_id: String) -> bool:
	return false

func passt_zu_tier(tier_id: String) -> bool:
	if not _ziel_tiere.is_empty():
		return _ziel_tiere.has(tier_id)
	return _passt_zu_tier_fallback(tier_id)

func _passt_zu_tier_fallback(_tier_id: String) -> bool:
	return false

func ressource() -> String:
	return str(konfiguration.get("ressource", ""))

func animation() -> String:
	return str(konfiguration.get("animation", "hacken"))

func logik_id() -> String:
	return _logik_id

func modifikator_id() -> String:
	return _modifikator_id

func faktor() -> float:
	return clampf(_faktor, 0.1, 10.0)

func ticks_fuer_faktor() -> int:
	return Kern_Weltuhr.ticks_aus_faktor(faktor())

func harvest_zeit_ticks() -> int:
	# Falls faktor gesetzt ist und keine feste harvest_zeit_ticks gewünscht wird,
	# leitet sich die Zeit aus dem Faktor ab; andernfalls gilt der feste Wert.
	if konfiguration.has("faktor") and not konfiguration.has("harvest_zeit_ticks"):
		return ticks_fuer_faktor()
	# Wenn beides gesetzt ist, skaliert der Modifikator die Basiszeit.
	var basis := int(konfiguration.get("harvest_zeit_ticks", 24))
	if konfiguration.has("faktor"):
		# Faktor > 1 bedeutet schneller, also kürzere Zeit.
		var skaliert := int(round(float(basis) / faktor()))
		return maxi(skaliert, 1)
	return maxi(basis, 1)

func reichweite() -> float:
	return float(konfiguration.get("reichweite", 140.0))

func startet_neu() -> void:
	fortlaufende_ticks = 0

func schritt_vorruecken() -> bool:
	# Zählt einen Arbeitstick hoch; liefert true, wenn ein Arbeitsschritt fertig ist.
	fortlaufende_ticks += 1
	if fortlaufende_ticks >= harvest_zeit_ticks():
		startet_neu()
		return true
	return false

func arbeitsschritt(ziel_ressource: String) -> void:
	# Ein vollständiger Arbeitsschritt ist vergangen; der Status meldet
	# das Ergebnis und ein Signal gibt es an die Domäne weiter.
	var menge := int(konfiguration.get("harvest_menge", 1))
	arbeitsschritt_erledigt.emit(ziel_ressource, menge)

func kann_ausgefuehrt_werden_von(vital: Einheit_VitalStatus) -> bool:
	# Prüft die physischen Voraussetzungen gegen die Vital-Maschine;
	# Verletzungen blockieren den Job, alle Grenzwerte stehen zentral
	# in der Job-Konfiguration.
	if vital == null:
		return false
	for mod in vital.aktive_modifikatoren:
		if mod.blockiert_job(job_id):
			return false
	var mindest_tragekraft := int(konfiguration.get("mindest_tragekraft", 0))
	if vital.effektive_tragekraft(int(konfiguration.get("basis_tragekraft", 10))) < mindest_tragekraft:
		return false
	return true