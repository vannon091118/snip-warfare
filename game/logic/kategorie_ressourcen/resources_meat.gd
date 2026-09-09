extends Resource_Basis
class_name Resources_Meat
## Datenklasse der Ressource Fleisch: Ressourcen tragen den englischen Namen
## in der Klasse (Resources_Meat), die Daten selbst bleiben deutsch beschriftet.

var meat_id: String = ""
var meat_name: String = ""
var meat_icon_pfad: String = ""
var meat_farbe: Color = Color.WHITE

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	meat_id = str(eintrag.get("id", "fleisch"))
	meat_name = str(eintrag.get("name", "Fleisch"))
	meat_icon_pfad = str(eintrag.get("icon_pfad", ""))
	meat_farbe = Color(str(eintrag.get("farbe", "#C75B39")))
