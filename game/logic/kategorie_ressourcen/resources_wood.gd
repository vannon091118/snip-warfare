extends Resource_Basis
class_name Resources_Wood
## Datenklasse der Ressource Holz. Dateiname und Klasse folgen dem Muster
## Resources_Meat (englischer Ressourcenname, Singular).

var wood_id: String = ""
var wood_name: String = ""
var wood_icon_pfad: String = ""
var wood_farbe: Color = Color.WHITE

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	wood_id = str(eintrag.get("id", "holz"))
	wood_name = str(eintrag.get("name", "Holz"))
	wood_icon_pfad = str(eintrag.get("icon_pfad", ""))
	wood_farbe = Color(str(eintrag.get("farbe", "#8B5A2B")))
