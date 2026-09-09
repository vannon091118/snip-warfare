extends RefCounted
class_name Lager_Basis
## Datenklasse eines lokalen Lagers: rein verortete Speicherplaetze fuer Ressourcen.
## Kein globales Konto: Jede Holz- oder Fleischmenge liegt in genau einem Lager.

## Kategorie daten: Identität und Kapazität dieses Lager-Typs.

var lager_id: String = ""
var lager_name: String = ""
var kapazitaet: int = 100
var icon_pfad: String = ""
var welt_objekt_id: String = ""

## Kategorie logik: reines Einlesen eines JSON-Eintrags, keine Berechnung.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	lager_id = str(eintrag.get("id", ""))
	lager_name = str(eintrag.get("name", lager_id))
	kapazitaet = int(eintrag.get("kapazitaet", 100))
	icon_pfad = str(eintrag.get("icon_pfad", ""))
	welt_objekt_id = str(eintrag.get("welt_objekt_id", ""))
