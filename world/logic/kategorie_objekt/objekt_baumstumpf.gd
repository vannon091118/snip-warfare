extends Objekt_Basis
class_name Objekt_Baumstumpf
## Datenklasse des Baumstumpf-Weltobjekts.

var baumstumpf_id: String = ""
var baumstumpf_name: String = ""
var baumstumpf_kategorie: StringName = &""
var baumstumpf_typ: StringName = &"objekt"
var baumstumpf_textur_pfad: String = ""
var baumstumpf_breite: float = 96.0
var baumstumpf_hoehe: float = 88.0
var baumstumpf_logik_id: String = ""
var baumstumpf_modifikator_id: String = "normal"
var baumstumpf_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	baumstumpf_id = id
	baumstumpf_name = angezeigter_name
	baumstumpf_kategorie = kategorie
	baumstumpf_typ = typ
	baumstumpf_textur_pfad = textur_pfad
	baumstumpf_breite = anzeige_breite
	baumstumpf_hoehe = anzeige_hoehe
	baumstumpf_logik_id = logik_id
	baumstumpf_modifikator_id = modifikator_id
	baumstumpf_faktor = faktor
