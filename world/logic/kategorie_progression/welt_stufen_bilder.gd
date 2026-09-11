extends RefCounted
class_name Welt_StufenBilder
## Uebersetzt den sichtbaren Ressourcen-Stadiumszustand in eine Textur: Das
## passende Blatt des Progressions-Sheets wird als AtlasTexture geschnitten.
## Der Renderer kennt nur diese Spitze, keine Sheet-Geometrie: Blattbreite,
## Blatthoehe und Spaltenzahl kommen aus dem Datenpool
## world/data/ressourcen_progression.json (Abschnitt stufen_blatt).

## Kategorie daten: die Sheet-Raster der Progressions-Sheets und der Cache.
const BAUM_SHEET := "res://world/assets/progression/baum_stufe.svg"
const STEIN_SHEET := "res://world/assets/progression/stein_stufe.svg"
const BUSCH_SHEET := "res://world/assets/progression/busch_stufe.svg"

var _blatt_breite: float = 128.0
var _blatt_hoehe: float = 128.0
var _spalten: int = 4
var _cache: Dictionary = {}

## Kategorie logik: Einrichten, Textur fuer Stadium und Element.

func einrichten(registry: Welt_ProgressionsRegistry) -> void:
	# Die Geometrie ist Konfiguration und nicht Code: Der Pool liefert sie,
	# diese Klasse konsumiert sie nur. Fehlt der Abschnitt, bleibt der
	# Rahmen aus dem Datenpool-Ersatzwert bestehen.
	# Einrichten setzt den Cache zurueck, damit ein neuer Lauf nicht die
	# Blätter des vorherigen Datenstands ausliefert.
	_cache.clear()
	if registry == null:
		return
	var blatt := registry.stufen_blatt()
	_blatt_breite = maxf(float(blatt.get("blatt_breite", _blatt_breite)), 1.0)
	_blatt_hoehe = maxf(float(blatt.get("blatt_hoehe", _blatt_hoehe)), 1.0)
	_spalten = maxi(int(blatt.get("spalten", _spalten)), 1)

func blatt_breite() -> float:
	return _blatt_breite

func blatt_hoehe() -> float:
	return _blatt_hoehe

func _blatt_fuer(element_id: String, stadium_index: int) -> Texture2D:
	var sheet_pfad := _sheet_pfad_fuer(element_id)
	if sheet_pfad == "" or stadium_index < 0:
		return null
	var cache_schluessel := "%s_%d" % [sheet_pfad, stadium_index]
	if _cache.has(cache_schluessel):
		return _cache[cache_schluessel] as Texture2D
	if not ResourceLoader.exists(sheet_pfad):
		return null
	var textur: Texture2D = load(sheet_pfad)
	# Ein Blatt ausserhalb des Sheets wird nicht erfunden: Ohne gueltige
	# Zelle bleibt es beim normalen Katalogbild des Objekts.
	if float(stadium_index) * _blatt_breite + _blatt_breite > float(textur.get_width()):
		return null
	if _blatt_hoehe > float(textur.get_height()):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = textur
	atlas.region = Rect2(float(stadium_index) * _blatt_breite, 0.0, _blatt_breite, _blatt_hoehe)
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
