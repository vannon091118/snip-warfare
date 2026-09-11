extends RefCounted
class_name Welt_StufenBilder
## Uebersetzt den sichtbaren Ressourcen-Stadiumszustand in eine Textur: Das
## passende Blatt des Progressions-Sheets wird als AtlasTexture geschnitten.
## Der Renderer kennt nur diese Spitze, keine Sheet-Geometrie.

## Kategorie daten: die Sheet-Raster der Progressions-Sheets.
const BAUM_SHEET := "res://world/assets/progression/baum_stufe.svg"
const STEIN_SHEET := "res://world/assets/progression/stein_stufe.svg"
const BUSCH_SHEET := "res://world/assets/progression/busch_stufe.svg"

var _cache: Dictionary = {}

## Kategorie logik: Textur fuer Stadium und Element.

func _blatt_fuer(element_id: String, stadium_index: int) -> Texture2D:
	var sheet_pfad := _sheet_pfad_fuer(element_id)
	var cache_schluessel := "%s_%d" % [sheet_pfad, stadium_index]
	if _cache.has(cache_schluessel):
		return _cache[cache_schluessel] as Texture2D
	if not ResourceLoader.exists(sheet_pfad):
		return null
	var textur: Texture2D = load(sheet_pfad)
	var atlas := AtlasTexture.new()
	atlas.atlas = textur
	atlas.region = Rect2(float(stadium_index * 512.0), 0.0, 512.0, 512.0)
	_cache[cache_schluessel] = atlas
	return atlas

func _sheet_pfad_fuer(element_id: String) -> String:
	match element_id:
		"baum", "baum_stumpf":
			return BAUM_SHEET
		"stein", "steine_gruppe":
			return STEIN_SHEET
		"busch":
			return BUSCH_SHEET
	return ""

## Der sichtbare Stadiums-Blattindex: Wachsende Objekte zeigen das kleinere
## von Wachstums- und Schadens-Stadium, begrenzte Objekte nur den Schaden.
func stadien_index_fuer(kategorie: String, stadien_anzahl: int, aktueller_bestand: int, staerke: int, wachstum: int, wachstums_dauer: int) -> int:
	if stadien_anzahl <= 1:
		return 0
	var schadens_index := 0
	if staerke > 0:
		var rest := clampf(float(aktueller_bestand) / float(staerke), 0.0, 1.0)
		schadens_index = clampi(int((1.0 - rest) * float(stadien_anzahl)), 0, stadien_anzahl - 1)
	if kategorie == "wachsend" and wachstums_dauer > 0:
		var anteil := clampf(float(wachstum) / float(wachstums_dauer), 0.0, 1.0)
		var wachstums_index := clampi(int(anteil * float(stadien_anzahl)), 0, stadien_anzahl - 1)
		return mini(wachstums_index, schadens_index)
	return schadens_index
