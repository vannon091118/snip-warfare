extends Objekt_Basis
class_name Objekt_Steinkreis
## Datenklasse des Steinkreis-Weltobjekts (mystische Megalithen-Anordnung).

var steinkreis_id: String = ""
var steinkreis_name: String = ""
var steinkreis_kategorie: StringName = &""
var steinkreis_typ: StringName = &"objekt"
var steinkreis_textur_pfad: String = ""
var steinkreis_breite: float = 112.0
var steinkreis_hoehe: float = 96.0
var steinkreis_ressource: String = "stein"
var steinkreis_logik_id: String = ""
var steinkreis_modifikator_id: String = "normal"
var steinkreis_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	steinkreis_id = id
	steinkreis_name = angezeigter_name
	steinkreis_kategorie = kategorie
	steinkreis_typ = typ
	steinkreis_textur_pfad = textur_pfad
	steinkreis_breite = anzeige_breite
	steinkreis_hoehe = anzeige_hoehe
	steinkreis_ressource = arbeits_ressource
	steinkreis_logik_id = logik_id
	steinkreis_modifikator_id = modifikator_id
	steinkreis_faktor = faktor
