extends RefCounted
class_name Tier_Sichtung
## Was ein Tier wahrnimmt und was daraus folgt: Sichtweite, Reaktion auf
## Annaeherung, Steigverhalten der Voegel und der Halteabstand beim Verfolgen.
## Reine Auswertung der Tierdaten, kein Zustand, kein Tick.

const STANDARD_TRIGGER := 400.0
const STANDARD_AUFHALTE := 120.0
const STANDARD_STEIG := 40
const SCHRECK_TICKS := 8


static func nah_genug(verhalten: Tier_Registry, tier_id: String, eigene_position: Vector2, spieler_position: Vector2) -> bool:
	## Meldet, ob der Spieler in die Sichtweite des Tieres geraten ist.
	if verhalten == null:
		return false
	return spieler_position.distance_to(eigene_position) <= verhalten.wert(tier_id, "trigger_radius", STANDARD_TRIGGER)


static func verfolgt(verhalten: Tier_Registry, tier_id: String) -> bool:
	## Der Ausloeser in den Tierdaten entscheidet zwischen Jagen und Fliehen.
	var ausloeser := daten_wert(verhalten, tier_id, "ausloeser")
	return ausloeser == "verfolgen"


static func ist_vogel(verhalten: Tier_Registry, tier_id: String) -> bool:
	## Voegel erkennt man am Ausloeser oder an ihrer Logik-Kennung.
	var daten := tier_daten(verhalten, tier_id)
	if daten == null:
		return false
	return daten.ausloeser == "wegfliegen" or daten.logik_id.begins_with("vogel")


static func steigt_jetzt(verhalten: Tier_Registry, tier_id: String, tick_in_zustand: int) -> bool:
	## Nur Voegel steigen beim Wegfliegen, und nur fuer die Dauer aus den Daten.
	if not ist_vogel(verhalten, tier_id):
		return false
	return tick_in_zustand <= steig_anteil(verhalten, tier_id)


static func steig_anteil(verhalten: Tier_Registry, tier_id: String) -> int:
	## Wie lange ein Vogel beim Wegfliegen steigt.
	if verhalten == null:
		return STANDARD_STEIG
	return int(verhalten.wert(tier_id, "steig_anteil_ticks", STANDARD_STEIG))


static func aufhalte_abstand(verhalten: Tier_Registry, tier_id: String) -> float:
	## Der Abstand, den ein verfolgendes Tier nicht unterschreitet.
	if verhalten == null:
		return STANDARD_AUFHALTE
	return verhalten.wert(tier_id, "aufhalte_abstand", STANDARD_AUFHALTE)


static func tier_daten(verhalten: Tier_Registry, tier_id: String) -> Tier_Basis:
	## Die Datenklasse einer Tierart, ohne Umweg ueber die Maschine.
	if verhalten == null:
		return null
	return verhalten.tier_daten(tier_id)


static func daten_wert(verhalten: Tier_Registry, tier_id: String, feld: String) -> String:
	## Ein Textfeld aus den Tierdaten; ohne Treffer ein leerer Text.
	var daten := tier_daten(verhalten, tier_id)
	if daten == null:
		return ""
	return str(daten.get(feld))
