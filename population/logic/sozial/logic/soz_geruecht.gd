extends RefCounted
class_name Soz_Geruecht
## Kategorie daten: Ein wanderndes Gerücht mit Art, Träger und Eskalationsstufe.
## Kategorie logik: Nur Zustand und Farben-Lieferung; die Wanderung regelt die Maschine.
## Stufe 0 (fluestern) bleibt beim Zeugen; ab Stufe 1 wandert es an Nachbarn.

## Kategorie daten: Wer das Gerücht trägt und über wen es spricht.
var ziel_id: int = -1
var urheber_id: int = -1
var art: String = "tratsch"
var glaube: float = 0.0

## Kategorie daten: Der Gerücht-Block aus sozial_regeln.json (Farben, Wirkung).
var _regel: Dictionary = {}

func einrichten(p_ziel: int, p_urheber: int, p_art: String, p_glaube: float, geruecht_regeln: Dictionary) -> void:
	ziel_id = p_ziel
	urheber_id = p_urheber
	art = p_art
	glaube = p_glaube
	_regel = geruecht_regeln.get("art", {}).get(art, {}) as Dictionary

func farbe() -> Color:
	var f: Array = _regel.get("farbe", [1.0, 1.0, 1.0])
	return Color(float(f[0]), float(f[1]), float(f[2]))

func eskalation() -> int:
	return int(_regel.get("eskalation", 0))

func image_wirkung() -> float:
	return float(_regel.get("image_wirkung", 0.0))

## Kategorie logik: Die Blase erzählt je Stufe anders, damit man Eskalation sieht.

func erzaehlung() -> String:
	var stufen: Array = ["flüstert", "erzählt", "wetert", "schreit"]
	return "%s über %d" % [stufen[clampi(eskalation(), 0, 3)], ziel_id]
