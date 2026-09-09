extends Objekt_Basis
class_name Objekt_Stein
## Datenklasse des Stein-Weltobjekts.

var stein_id: String = ""
var stein_name: String = ""
var stein_kategorie: StringName = &""
var stein_typ: StringName = &"objekt"
var stein_textur_pfad: String = ""
var stein_breite: float = 96.0
var stein_hoehe: float = 88.0
var stein_ressource: String = ""
var stein_logik_id: String = ""
var stein_modifikator_id: String = "normal"
var stein_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	stein_id = id
	stein_name = angezeigter_name
	stein_kategorie = kategorie
	stein_typ = typ
	stein_textur_pfad = textur_pfad
	stein_breite = anzeige_breite
	stein_hoehe = anzeige_hoehe
	stein_ressource = arbeits_ressource
	stein_logik_id = logik_id
	stein_modifikator_id = modifikator_id
	stein_faktor = faktor
