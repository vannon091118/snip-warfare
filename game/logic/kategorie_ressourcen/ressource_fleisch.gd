extends Ressource_Basis
class_name Ressource_Fleisch
## Datenklasse der Ressource Fleisch. Sie besitzt keine eigenen Felder,
## denn die Katalog-Wahrheit trägt bereits die Ressource_Basis; die
## ehemaligen meat_*-Spiegel sind gefallen.

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	# Eine Wahrheit: super trägt die Katalog-Felder, hier bleibt nichts Eigenes.
	super.aus_konfig_eintrag(eintrag)
	if not eintrag.has("id"):
		ressourcen_id = "fleisch"
	if not eintrag.has("name"):
		ressourcen_name = "Fleisch"
	if not eintrag.has("icon_pfad"):
		icon_pfad = "res://world/assets/ui/ressource_fleisch.svg"
	if not eintrag.has("farbe"):
		farbe = Color("#C75B39")
