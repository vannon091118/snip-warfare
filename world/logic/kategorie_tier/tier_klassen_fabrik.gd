extends RefCounted
class_name Tier_KlassenFabrik
## Erzeugung der Tier-Datenklassen. Eine Zuständigkeit: die Zuordnung von der
## Tier-id aus den Daten auf die passende Datenklasse. Eine neue Tierart ist
## hier ein neuer Zweig und sonst nirgends.


static func klasse_fuer(tier_id: String) -> Tier_Basis:
	## Liefert die Datenklasse einer Tierart; ohne eigene Klasse die Basis.
	match tier_id:
		"baer":
			return Tier_Baer.new()
		"eisbaer":
			return Tier_Eisbaer.new()
		"hase":
			return Tier_Hase.new()
		"vogel":
			return Tier_Vogel.new()
		"vogelgruppe":
			return Tier_Vogelgruppe.new()
	return Tier_Basis.new()
