extends Objekt_Basis
class_name Objekt_Felswand
## Datenklasse des Felswand-Weltobjekts (zusammenhängende Klippe).

var felswand_id: String = ""
var felswand_name: String = ""
var felswand_kategorie: StringName = &""
var felswand_typ: StringName = &"objekt"
var felswand_textur_pfad: String = ""
var felswand_breite: float = 96.0
var felswand_hoehe: float = 96.0
var felswand_ressource: String = "stein"
var felswand_logik_id: String = ""
var felswand_modifikator_id: String = "normal"
var felswand_faktor: float = 1.2

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	felswand_id = id
	felswand_name = angezeigter_name
	felswand_kategorie = kategorie
	felswand_typ = typ
	felswand_textur_pfad = textur_pfad
	felswand_breite = anzeige_breite
	felswand_hoehe = anzeige_hoehe
	felswand_ressource = arbeits_ressource
	felswand_logik_id = logik_id
	felswand_modifikator_id = modifikator_id
	felswand_faktor = faktor
