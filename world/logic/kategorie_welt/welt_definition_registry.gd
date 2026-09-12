extends RefCounted
class_name Welt_DefinitionRegistry
## Einzige Quelle für fachliche Welt-Größen (max/min Karte, Kachel, Chunk, Region).
## Liefert deterministisch Breite/Höhe aus dem Welt-Seed; keine zweite Wahrheit,
## keine Sonderfälle für 25/50/75/100 Prozent im Generator.

const DEFINITION_PFAD := "res://world/data/welt_definition.json"

## Kategorie daten: Roh-Definition als Wörterbuch.
var definition: Dictionary = {}

## Kategorie logik: Laden und deterministische Größen ableiten.

func laden() -> bool:
	if not FileAccess.file_exists(DEFINITION_PFAD):
		push_warning("Welt-Definition fehlt: %s" % DEFINITION_PFAD)
		return false
	var datei := FileAccess.open(DEFINITION_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) != TYPE_DICTIONARY:
		push_warning("Welt-Definition ungültiges JSON: %s" % DEFINITION_PFAD)
		return false
	definition = daten
	return true

func max_karten_groesse() -> Vector2i:
	var max_wort: Dictionary = definition.get("max_karten_groesse", {"breite": 32, "hoehe": 24})
	return Vector2i(int(max_wort.get("breite", 32)), int(max_wort.get("hoehe", 24)))

func min_karten_groesse() -> Vector2i:
	var min_wort: Dictionary = definition.get("min_karten_groesse", {"breite": 8, "hoehe": 8})
	return Vector2i(int(min_wort.get("breite", 8)), int(min_wort.get("hoehe", 8)))

func kachel_groesse() -> int:
	return int(definition.get("kachel_groesse", Welt_Model.KACHEL_GROESSE))

func chunk_groesse() -> int:
	return int(definition.get("chunk_groesse", 8))

func region_kante() -> int:
	return int(definition.get("region_kante", 4))

func wasser_wert(schluessel: String, rueckfall: Variant) -> Variant:
	# Wasser-Abschnitt als Daten: Schalter und Reichweite des Automaten
	# kommen aus derselben Definition wie Kachel- und Chunk-Größe.
	var abschnitt: Variant = definition.get("wasser_welt_abschnitt", {})
	if typeof(abschnitt) != TYPE_DICTIONARY:
		return rueckfall
	return (abschnitt as Dictionary).get(schluessel, rueckfall)

func lokalkarten_groesse_fuer(welt_seed: int) -> Vector2i:
	# Flächenanteil als Daten: aus dem Welt-Seed deterministisch 25-100% in 8er-Schritten.
	var max_groesse := max_karten_groesse()
	var min_groesse := min_karten_groesse()
	var ableitung := Kern_Zufall.abgeleitet_fuer(welt_seed, 0x4C4B4752)
	var anteil_index := ableitung.zahl_bereich(0, 3)
	var anteile: Array[float] = [0.5, 0.625, 0.75, 1.0]
	if anteil_index < 0 or anteil_index >= anteile.size():
		anteil_index = 3
	var anteil: float = anteile[anteil_index]
	var breite := int(round(float(max_groesse.x) * anteil))
	var hoehe := int(round(float(max_groesse.y) * anteil))
	breite = clampi(breite, min_groesse.x, max_groesse.x)
	hoehe = clampi(hoehe, min_groesse.y, max_groesse.y)
	# Auf Chunk-Groesse runden, damit Regionen/Chunks aufgehen.
	var chunk := chunk_groesse()
	if chunk > 0:
		breite = maxi(chunk, int(floor(float(breite) / float(chunk))) * chunk)
		hoehe = maxi(chunk, int(floor(float(hoehe) / float(chunk))) * chunk)
	return Vector2i(breite, hoehe)
