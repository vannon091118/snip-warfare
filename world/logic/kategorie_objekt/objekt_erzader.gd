extends Objekt_Basis
class_name Objekt_Erzader
## Datenklasse des Erzader-Weltobjekts (mineralreiche Ader im Fels).

var erzader_id: String = ""
var erzader_name: String = ""
var erzader_kategorie: StringName = &""
var erzader_typ: StringName = &"objekt"
var erzader_textur_pfad: String = ""
var erzader_breite: float = 96.0
var erzader_hoehe: float = 88.0
var erzader_ressource: String = "stein"
var erzader_logik_id: String = ""
var erzader_modifikator_id: String = "normal"
var erzader_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	erzader_id = id
	erzader_name = angezeigter_name
	erzader_kategorie = kategorie
	erzader_typ = typ
	erzader_textur_pfad = textur_pfad
	erzader_breite = anzeige_breite
	erzader_hoehe = anzeige_hoehe
	erzader_ressource = arbeits_ressource
	erzader_logik_id = logik_id
	erzader_modifikator_id = modifikator_id
	erzader_faktor = faktor
