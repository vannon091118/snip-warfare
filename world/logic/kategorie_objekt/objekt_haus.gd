extends Objekt_Basis
class_name Objekt_Haus
## Datenklasse des Haus-Weltobjekts.

var haus_id: String = ""
var haus_name: String = ""
var haus_kategorie: StringName = &""
var haus_typ: StringName = &"objekt"
var haus_textur_pfad: String = ""
var haus_breite: float = 160.0
var haus_hoehe: float = 144.0
var haus_logik_id: String = ""
var haus_modifikator_id: String = "normal"
var haus_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	haus_id = id
	haus_name = angezeigter_name
	haus_kategorie = kategorie
	haus_typ = typ
	haus_textur_pfad = textur_pfad
	haus_breite = anzeige_breite
	haus_hoehe = anzeige_hoehe
	haus_logik_id = logik_id
	haus_modifikator_id = modifikator_id
	haus_faktor = faktor
