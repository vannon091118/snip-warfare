extends Resource_Basis
class_name Resources_Stone
## Datenklasse der Ressource Stein (englischer Ressourcenname, Singular).

var stone_id: String = ""
var stone_name: String = ""
var stone_icon_pfad: String = ""
var stone_farbe: Color = Color.WHITE

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	stone_id = str(eintrag.get("id", "stein"))
	stone_name = str(eintrag.get("name", "Stein"))
	stone_icon_pfad = str(eintrag.get("icon_pfad", ""))
	stone_farbe = Color(str(eintrag.get("farbe", "#B9B2A2")))
