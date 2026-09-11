extends Objekt_Basis
class_name Objekt_Kachel
## Datenklasse einer Terrain-Kachel (Boden, Wiese, Waldboden, Acker, Weg,
## Sand, Ufer, Wasser, Fels, Geröll). Kacheln sind Weltobjekte der Kategorie
## Terrain und werden im Raster platziert.
## Die Kachel selbst trägt ihre Bildvarianten, ob sie spiegelbar ist und
## welche Tönungen erlaubt sind; welche Variante eine Kachel wählt, entscheidet
## allein Welt_TerrainBlatt. Diese Klasse enthält nur Daten.

## Kategorie daten: Kachel-Identität, Maße, Varianten und Tönungen.
var kachel_id: String = ""
var kachel_name: String = ""
var kachel_kategorie: StringName = &""
var kachel_typ: StringName = &"kachel"
var kachel_textur_pfad: String = ""
var kachel_groesse: float = 0.0
var kachel_logik_id: String = ""
var kachel_modifikator_id: String = "normal"
var kachel_faktor: float = 1.0
## Bildvarianten derselben Geländeart; leer heißt: nur textur_pfad.
var kachel_varianten: Array[String] = []
## Erlaubt das Blatt, dieselbe Kachel gespiegelt zu setzen (bricht Wiederholung).
var kachel_spiegelbar: bool = false
## Erlaubte Farbtönungen als Hex-Zeichenketten; leer heißt: keine Tönung.
var kachel_toenungen: Array[String] = []

## Kategorie logik: Katalog einlesen und Hilfsfunktionen.
func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	super.aus_katalog_eintrag(eintrag)
	kachel_id = id
	kachel_name = angezeigter_name
	kachel_kategorie = kategorie
	kachel_typ = typ
	kachel_textur_pfad = textur_pfad
	kachel_groesse = anzeige_breite if anzeige_breite > 0.0 else float(Welt_Model.KACHEL_GROESSE)
	kachel_logik_id = logik_id
	kachel_modifikator_id = modifikator_id
	kachel_faktor = faktor
	kachel_varianten = _string_array_aus(eintrag.get("varianten", []))
	kachel_spiegelbar = bool(eintrag.get("spiegelbar", false))
	kachel_toenungen = _string_array_aus(eintrag.get("toenungen", []))

func _string_array_aus(roh: Variant) -> Array[String]:
	# Reines Einlesen einer Liste von Zeichenketten; keine Logik.
	var ergebnis: Array[String] = []
	if typeof(roh) == TYPE_ARRAY:
		for wert: Variant in roh as Array:
			ergebnis.append(str(wert))
	return ergebnis
