extends Objekt_Basis
class_name Objekt_Ruine
## Datenklasse des Ruinen-Weltobjekts (verfallene Mauerreste vergangener Siedler).

var ruine_id: String = ""
var ruine_name: String = ""
var ruine_kategorie: StringName = &""
var ruine_typ: StringName = &"objekt"
var ruine_textur_pfad: String = ""
var ruine_breite: float = 112.0
var ruine_hoehe: float = 96.0
var ruine_ressource: String = "stein"
var ruine_logik_id: String = ""
var ruine_modifikator_id: String = "normal"
var ruine_faktor: float = 0.9

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	ruine_id = id
	ruine_name = angezeigter_name
	ruine_kategorie = kategorie
	ruine_typ = typ
	ruine_textur_pfad = textur_pfad
	ruine_breite = anzeige_breite
	ruine_hoehe = anzeige_hoehe
	ruine_ressource = arbeits_ressource
	ruine_logik_id = logik_id
	ruine_modifikator_id = modifikator_id
	ruine_faktor = faktor
