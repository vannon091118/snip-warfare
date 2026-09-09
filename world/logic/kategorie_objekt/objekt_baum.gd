extends Objekt_Basis
class_name Objekt_Baum
## Datenklasse des Baum-Weltobjekts. Liest ihre Werte selbst aus dem
## Element-Katalog-Eintrag mit der id "baum".

var baum_id: String = ""
var baum_name: String = ""
var baum_kategorie: StringName = &""
var baum_typ: StringName = &"objekt"
var baum_textur_pfad: String = ""
var baum_breite: float = 128.0
var baum_hoehe: float = 128.0
var baum_ressource: String = ""
var baum_logik_id: String = ""
var baum_modifikator_id: String = "normal"
var baum_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	baum_id = id
	baum_name = angezeigter_name
	baum_kategorie = kategorie
	baum_typ = typ
	baum_textur_pfad = textur_pfad
	baum_breite = anzeige_breite
	baum_hoehe = anzeige_hoehe
	baum_ressource = arbeits_ressource
	baum_logik_id = logik_id
	baum_modifikator_id = modifikator_id
	baum_faktor = faktor
