extends RefCounted
class_name Kern_LogikBasis
## Datenklasse einer Logik. Eine Logik ist generisch, objektunabhängig und
## wiederverwendbar. PLUGIN-GRENZE (noch nicht aktiv): Objekte und Tiere
## verweisen bisher nirgends auf eine Logik über logik_id; der Verbraucher
## kommt mit dem Plugin-Auftrag. Sie trägt nur Identität und Beschreibung, kein Objekt
## kennt sie durch harte Verdrahtung, sondern nur über ihre logik_id in der
## Registry-Zuordnung. Die Registry lädt sie zentral aus kern_logik.json.

var logik_id: String = ""
var angezeigter_name: String = ""
var beschreibung: String = ""
var verhalten: String = ""
var ressource: String = ""
var basis_faktor: float = 1.0

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	logik_id = eintrag_id
	angezeigter_name = str(eintrag.get("name", eintrag_id))
	beschreibung = str(eintrag.get("beschreibung", ""))
	verhalten = str(eintrag.get("verhalten", ""))
	ressource = str(eintrag.get("ressource", ""))
	basis_faktor = float(eintrag.get("basis_faktor", 1.0))
