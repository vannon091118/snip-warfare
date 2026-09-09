extends Objekt_Basis
class_name Objekt_Steingruppe
## Datenklasse des Steingruppen-Weltobjekts.

var steingruppe_id: String = ""
var steingruppe_name: String = ""
var steingruppe_kategorie: StringName = &""
var steingruppe_typ: StringName = &"objekt"
var steingruppe_textur_pfad: String = ""
var steingruppe_breite: float = 160.0
var steingruppe_hoehe: float = 104.0
var steingruppe_ressource: String = ""
var steingruppe_logik_id: String = ""
var steingruppe_modifikator_id: String = "normal"
var steingruppe_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	steingruppe_id = id
	steingruppe_name = angezeigter_name
	steingruppe_kategorie = kategorie
	steingruppe_typ = typ
	steingruppe_textur_pfad = textur_pfad
	steingruppe_breite = anzeige_breite
	steingruppe_hoehe = anzeige_hoehe
	steingruppe_ressource = arbeits_ressource
	steingruppe_logik_id = logik_id
	steingruppe_modifikator_id = modifikator_id
	steingruppe_faktor = faktor
