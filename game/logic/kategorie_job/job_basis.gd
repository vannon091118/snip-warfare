extends RefCounted
class_name Job_Basis
## Basisklasse aller Jobs. Ein Job beschreibt, woran eine Einheit arbeitet,
## welche Animation dabei läuft und was nach Ablauf der Harvest-Zeit passiert.
## Alle konkreten Werte (Harvest-Zeit, Menge, Reichweite) stehen zentral in
## game/data/job_config.json; die Unterklassen entscheiden nur über das Ziel.
##
## Erweiterbar: Neue Jobs erben von Job_Basis, überschreiben ziel_typ() und
## melden sich in der Job_Registry an. Diese Klasse ändert sich dabei nicht.

signal arbeitsschritt_erledigt(ressource: String, menge: int)
signal job_beendet()

enum ZielTyp {
	OBJEKT,
	TIER,
}

var job_id: String = ""
var konfiguration: Dictionary = {}
var fortlaufende_ticks: int = 0
var _logik_id: String = ""
var _modifikator_id: String = "normal"
var _faktor: float = 1.0

func einrichten(neue_job_id: String, neue_konfiguration: Dictionary) -> void:
	job_id = neue_job_id
	konfiguration = neue_konfiguration
	_logik_id = str(konfiguration.get("logik_id", ""))
	_modifikator_id = str(konfiguration.get("modifikator_id", "normal"))
	_faktor = float(konfiguration.get("faktor", 1.0))

func name() -> String:
	return str(konfiguration.get("name", job_id.capitalize()))

func ziel_typ() -> ZielTyp:
	# Unterklassen geben an, ob sie ein Weltobjekt oder ein Tier bearbeiten.
	return ZielTyp.OBJEKT

func passt_zu_objekt(element_id: String) -> bool:
	# Unterklassen prüfen, ob das Weltobjekt zu diesem Job passt.
	return false

func passt_zu_tier(tier_id: String) -> bool:
	# Unterklassen prüfen, ob das Tier zu diesem Job passt.
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
	# 1.0 bedeutet zehn Sekunden; die Weltuhr übersetzt in Ticks.
	return maxi(int(round(faktor() * 10.0 * Kern_Weltuhr.TICK_RATE_HZ)), 1)

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
