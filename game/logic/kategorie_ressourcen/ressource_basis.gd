extends RefCounted
class_name Ressource_Basis
## Datenklasse einer Ressource. Enthält ausschließlich Daten; das Einlesen
## aus ressourcen.json ist ein reiner Zuweisungsschritt ohne Berechnung.
## Bestandsverwaltung und Ernte bleiben in den State Machines der Game-Domäne.

## Kategorie daten: die vier Katalog-Felder jeder Ressource.
var ressourcen_id: String = ""
var ressourcen_name: String = ""
var icon_pfad: String = ""
var farbe: Color = Color.WHITE

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	ressourcen_id = str(eintrag.get("id", ""))
	ressourcen_name = str(eintrag.get("name", ressourcen_id))
	icon_pfad = str(eintrag.get("icon_pfad", ""))
	farbe = Color(str(eintrag.get("farbe", "#FFFFFF")))
