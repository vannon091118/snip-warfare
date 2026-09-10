extends Ressource_Basis
class_name Ressource_Werkzeug
## Datenklasse der Ressource Werkzeug. Erzeugt ausschließlich durch die
## zentrale Zuordnung in Einheit_Ressourcen aus game/data/ressourcen.json.
## Sie besitzt keine eigenen Felder; die Katalog-Wahrheit trägt die Basis.

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	# super trägt die Katalog-Felder; Vorgabewerte nur bei fehlendem Eintrag.
	super.aus_konfig_eintrag(eintrag)
	if not eintrag.has("id"):
		ressourcen_id = "werkzeug"
	if not eintrag.has("name"):
		ressourcen_name = "Werkzeug"
	if not eintrag.has("icon_pfad"):
		icon_pfad = "res://world/assets/ui/ressource_werkzeug.svg"
	if not eintrag.has("farbe"):
		farbe = Color("#5A7A9A")
