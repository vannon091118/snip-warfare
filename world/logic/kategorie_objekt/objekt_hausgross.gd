extends Objekt_Basis
class_name Objekt_Hausgross
## Datenklasse des großen Haus-Weltobjekts.

var hausgross_id: String = ""
var hausgross_name: String = ""
var hausgross_kategorie: StringName = &""
var hausgross_typ: StringName = &"objekt"
var hausgross_textur_pfad: String = ""
var hausgross_breite: float = 208.0
var hausgross_hoehe: float = 160.0
var hausgross_logik_id: String = ""
var hausgross_modifikator_id: String = "normal"
var hausgross_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	hausgross_id = id
	hausgross_name = angezeigter_name
	hausgross_kategorie = kategorie
	hausgross_typ = typ
	hausgross_textur_pfad = textur_pfad
	hausgross_breite = anzeige_breite
	hausgross_hoehe = anzeige_hoehe
	hausgross_logik_id = logik_id
	hausgross_modifikator_id = modifikator_id
	hausgross_faktor = faktor
