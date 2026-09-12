extends Objekt_Basis
class_name Objekt_Berg
## Datenklasse des Berg-Weltobjekts (großes Felsmassiv).

var berg_id: String = ""
var berg_name: String = ""
var berg_kategorie: StringName = &""
var berg_typ: StringName = &"objekt"
var berg_textur_pfad: String = ""
var berg_breite: float = 128.0
var berg_hoehe: float = 128.0
var berg_ressource: String = "stein"
var berg_logik_id: String = ""
var berg_modifikator_id: String = "normal"
var berg_faktor: float = 1.5

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	berg_id = id
	berg_name = angezeigter_name
	berg_kategorie = kategorie
	berg_typ = typ
	berg_textur_pfad = textur_pfad
	berg_breite = anzeige_breite
	berg_hoehe = anzeige_hoehe
	berg_ressource = arbeits_ressource
	berg_logik_id = logik_id
	berg_modifikator_id = modifikator_id
	berg_faktor = faktor
