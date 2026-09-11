extends Ressource_Basis
class_name Ressource_Beeren
## Datenklasse der Ressource Beeren. Gesammelt vom Busch, direkt
## als Nahrungsergaenzung neben Fleisch verwendbar.
## Keine eigenen Felder: Katalog-Wahrheit traegt bereits Ressource_Basis.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	super.aus_konfig_eintrag(eintrag)
	if not eintrag.has("id"):
		ressourcen_id = "beeren"
	if not eintrag.has("name"):
		ressourcen_name = "Beeren"
	if not eintrag.has("icon_pfad"):
		icon_pfad = "res://world/assets/ui/ressource_beeren.svg"
	if not eintrag.has("farbe"):
		farbe = Color("#7B2D8B")
