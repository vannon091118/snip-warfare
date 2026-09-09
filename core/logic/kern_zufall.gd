extends RefCounted
class_name Kern_Zufall
## Einzige erlaubte Zufallsquelle des Projekts.
## Zufall passiert niemals frei: Er tritt nur innerhalb einer Mutation des
## Mutationsschemas auf, wird aus dem aktuellen Zustand abgeleitet (jeder
## Start ist vorhersagbar) und sein Ergebnis wird als Zustand festgehalten.
## randi, randf, randomize und randf_range außerhalb dieser Klasse sind
## verboten (Preflight E012).

var zufallsstaende: PackedInt64Array = PackedInt64Array([0, 0])
var gezogene_zahlen: int = 0

func start_zustand_setzen(start: int) -> void:
	# Jeder Start ist erlaubt, aber niemals unvorhersehbar: Er wird als
	# Zustand abgelegt und geht in die Folgestände ein.
	var erster := int(start) & 0x7FFFFFFFFFFFFFFF
	zufallsstaende = PackedInt64Array([erster, (erster * 6364136223846793005 + 1442695040888963407) & 0x7FFFFFFFFFFFFFFF])
	gezogene_zahlen = 0

func naechste_zahl() -> int:
	# Deterministische Generatorenfolge (PCG-artig): Dieselben Startzustände
	# liefern immer dieselbe Zahlenfolge, an jedem Rechner, zu jedem Zeitpunkt.
	# 0x9E3779B97F4A7C15 passt nicht in signed 64, daher wird die gemaskte
	# Variante 0x1E3779B97F4A7C15 (low 63 Bit) verwendet.
	zufallsstaende[1] = (zufallsstaende[1] + 2177342782468422677) & 0x7FFFFFFFFFFFFFFF
	var versetzt := zufallsstaende[1]
	var gedreht := ((versetzt >> 27) | (versetzt << 37)) & 0x7FFFFFFFFFFFFFFF
	var wert := int((gedreht * 2685821657736338717) & 0x7FFFFFFFFFFFFFFF)
	zufallsstaende[0] = wert
	gezogene_zahlen += 1
	return wert

func zahl_bereich(minimum: int, maximum: int) -> int:
	# Geschlossener Bereich; der Zustand entscheidet, nicht die Uhrzeit.
	var spanne := maximum - minimum + 1
	if spanne <= 0:
		return minimum
	return minimum + naechste_zahl() % spanne

func zustaende_als_wort() -> String:
	return "%d;%d;%d" % [zufallsstaende[0], zufallsstaende[1], gezogene_zahlen]

func zustaende_uebernehmen(wort: String) -> void:
	# Zustand vollständig wiederherstellen, zum Beispiel aus einer Spielstand-Datei.
	var teile := wort.split(";")
	if teile.size() != 3:
		return
	zufallsstaende = PackedInt64Array([int(teile[0]), int(teile[1])])
	gezogene_zahlen = int(teile[2])

static func abgeleitet_fuer(welt_seed: int, region_identitaet: int) -> Kern_Zufall:
	# Deterministische Ableitung: gleiche Welt + gleiche Region-Identität
	# ergibt immer denselben Teil-Zufall, unabhängig von Erzeugungsreihenfolge.
	# Verwendet dieselbe PCG-Mischung wie start_zustand_setzen.
	var gemischt := (int(welt_seed) * 6364136223846793005 + int(region_identitaet) * 1442695040888963407) & 0x7FFFFFFFFFFFFFFF
	var abgeleitet := Kern_Zufall.new()
	abgeleitet.start_zustand_setzen(gemischt)
	return abgeleitet

static func abgeleitet_fuer_chunk(welt_seed: int, chunk_x: int, chunk_y: int) -> Kern_Zufall:
	# Chunk-Identität ist ein 64-Bit-Mix aus den beiden Koordinaten.
	var identitaet := ((int(chunk_x) & 0xFFFF) << 16) | (int(chunk_y) & 0xFFFF)
	identitaet = (identitaet * 0x9E3779B1) & 0x7FFFFFFFFFFFFFFF
	return abgeleitet_fuer(welt_seed, identitaet)
