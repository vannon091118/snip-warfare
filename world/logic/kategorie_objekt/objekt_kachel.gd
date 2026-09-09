extends Objekt_Basis
class_name Objekt_Kachel
## Datenklasse einer Terrain-Kachel (Boden, Wiese). Kacheln sind Weltobjekte
## der Kategorie Terrain und werden im Raster platziert.

var kachel_id: String = ""
var kachel_name: String = ""
var kachel_kategorie: StringName = &""
var kachel_typ: StringName = &"kachel"
var kachel_textur_pfad: String = ""
var kachel_groesse: float = 512.0
var kachel_logik_id: String = ""
var kachel_modifikator_id: String = "normal"
var kachel_faktor: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	kachel_id = id
	kachel_name = angezeigter_name
	kachel_kategorie = kategorie
	kachel_typ = typ
	kachel_textur_pfad = textur_pfad
	kachel_groesse = anzeige_breite
	kachel_logik_id = logik_id
	kachel_modifikator_id = modifikator_id
	kachel_faktor = faktor
	kachel_groesse = anzeige_breite
