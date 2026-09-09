extends Objekt_Basis
class_name Objekt_Kadaver
## Datenklasse des Kadaver-Weltobjekts: Ernteziel des Jägers am
## toten Tier. Sie liest ihre Werte selbst aus dem Element-Katalog
## und trägt sonst keine Logik.

var kadaver_id: String = ""
var kadaver_name: String = ""
var kadaver_kategorie: StringName = &""
var kadaver_typ: StringName = &"objekt"
var kadaver_textur_pfad: String = ""
var kadaver_breite: float = 96.0
var kadaver_hoehe: float = 88.0
var kadaver_logik_id: String = ""
var kadaver_modifikator_id: String = "normal"
var kadaver_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	kadaver_id = id
	kadaver_name = angezeigter_name
	kadaver_kategorie = kategorie
	kadaver_typ = typ
	kadaver_textur_pfad = textur_pfad
	kadaver_breite = anzeige_breite
	kadaver_hoehe = anzeige_hoehe
	kadaver_logik_id = logik_id
	kadaver_modifikator_id = modifikator_id
	kadaver_faktor = faktor
