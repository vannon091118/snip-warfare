extends Resource_Basis
class_name Resources_Werkzeug
## Datenklasse der Ressource Werkzeug. Erzeugt ausschließlich durch die
## zentrale Zuordnung in Einheit_Ressourcen aus game/data/ressourcen.json.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	ressourcen_id = str(eintrag.get("id", "werkzeug"))
	ressourcen_name = str(eintrag.get("name", "Werkzeug"))
	icon_pfad = str(eintrag.get("icon_pfad", ""))
	farbe = Color(str(eintrag.get("farbe", "#5A7A9A")))