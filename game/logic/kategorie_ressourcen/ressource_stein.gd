extends Ressource_Basis
class_name Ressource_Stein
## Datenklasse der Ressource Stein. Sie besitzt keine eigenen Felder,
## denn die Katalog-Wahrheit trägt bereits die Ressource_Basis; die
## ehemaligen stone_*-Spiegel sind gefallen.

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	# Eine Wahrheit: super trägt die Katalog-Felder, hier bleibt nichts Eigenes.
	super.aus_konfig_eintrag(eintrag)
	if not eintrag.has("id"):
		ressourcen_id = "stein"
	if not eintrag.has("name"):
		ressourcen_name = "Stein"
	if not eintrag.has("icon_pfad"):
		icon_pfad = "res://world/assets/ui/ressource_stein.svg"
	if not eintrag.has("farbe"):
		farbe = Color("#B9B2A2")
