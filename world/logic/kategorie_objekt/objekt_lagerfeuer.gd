extends Objekt_Basis
class_name Objekt_Lagerfeuer
## Datenklasse des Lagerfeuers. Wärmequelle mit Radius und Stärke.
## Liegt im Pool, Registry erzeugt sie, keine Sonderbehandlung.

var lagerfeuer_id: String = ""
var lagerfeuer_name: String = ""
var lagerfeuer_kategorie: StringName = &"Gebäude"
var lagerfeuer_typ: StringName = &"objekt"
var lagerfeuer_textur_pfad: String = ""
var lagerfeuer_breite: float = 128.0
var lagerfeuer_hoehe: float = 128.0
var lagerfeuer_waerme_radius_kacheln: int = 5
var lagerfeuer_waerme_staerke: float = 1.0

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	lagerfeuer_id = id
	lagerfeuer_name = angezeigter_name
	lagerfeuer_kategorie = kategorie
	lagerfeuer_typ = typ
	lagerfeuer_textur_pfad = textur_pfad
	lagerfeuer_breite = anzeige_breite
	lagerfeuer_hoehe = anzeige_hoehe
	lagerfeuer_waerme_radius_kacheln = int(eintrag.get("waerme_radius_kacheln", 5))
	lagerfeuer_waerme_staerke = float(eintrag.get("waerme_staerke", 1.0))
