extends RefCounted
class_name Tier_FeldAbfrage
## Feldwissen ueber Tiere an genau einer Stelle: welcher Schluessel welchen
## Wert traegt, welcher Standard gilt und wann ein Schluessel ueberhaupt
## vorhanden ist. Die Registry laedt und ordnet, diese Klasse antwortet.


static func wert(tier: Tier_Basis, schluessel: String, standard: float) -> float:
	## Der Wert eines Feldes; ohne Tier oder ohne Feld gilt der Standard.
	if tier == null:
		return standard
	match schluessel:
		"trigger_radius":
			return tier.trigger_radius
		"flucht_geschwindigkeit":
			return tier.flucht_geschwindigkeit
		"flug_geschwindigkeit":
			return tier.flug_geschwindigkeit
		"gehe_geschwindigkeit":
			return tier.gehe_geschwindigkeit
		"aufhalte_abstand":
			return tier.aufhalte_abstand
		"steig_anteil_ticks":
			return float(tier.steig_anteil_ticks)
		"fade_dauer_ticks":
			return float(tier.fade_dauer_ticks)
	return standard


static func hat_schluessel(tier: Tier_Basis, schluessel: String) -> bool:
	## Meldet, ob ein Feld bei dieser Art wirklich gesetzt ist.
	if tier == null:
		return false
	match schluessel:
		"flug_geschwindigkeit":
			return tier.flug_geschwindigkeit > 0.0
		"steig_anteil_ticks":
			return tier.steig_anteil_ticks > 0
	return tier.ausloeser != ""
