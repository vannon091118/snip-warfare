extends Node
class_name Kern_Weltuhr
## Globale Weltuhr: einziger zentraler Tick aller Domänen. RT-Pyramide:
## Weltuhr ist die Basis der Pyramide, darauf stehen Registries und
## State Maschinen. Jede zeitabhängige Berechnung läuft nur hierüber.
## Tickstandard: klassisches RTS-Prinzip mit 24 Ticks pro Sekunde.
## Faktor 1.0 bedeutet 10 Sekunden auf dieser Uhr.
## Die Rahmen-Deltas glättet der Kern_TaktGlaetter: Einzelne Ruckler
## erzeugen keinen spürbaren Aufhol-Zeitsprung, und dauerhafte Überlastung
## stabilisiert die Simulation selbst in einen etwas ruhigeren Takt, statt
## zu spiralen oder Zeit zu verwerfen.

signal tick(tick_nummer: int, delta: float)

const TICK_RATE_HZ := 24.0
const MAX_TICKS_PRO_FRAME := 5
const FAKTOR_SEKUNDEN := 10.0
const FAKTOR_MIN := 0.1
const FAKTOR_MAX := 10.0
## Grenzen für Spielrhythmus-Dauern in Minuten. Sie sind bewusst weiter als
## die Modifikator-Grenzen, weil Takt, Tag und Nacht echte Spielzeiten sind
## und nicht auf den Modifikator-Bereich bis 100 Sekunden geklemmt werden
## dürfen.
const MINUTEN_MIN := 0.1
const MINUTEN_MAX := 120.0

var _tick_nummer: int = 0
## Der Glätter trägt Akkumulator und geglättetes Delta; die Uhr hält ihn
## als einzigen Zustand neben der Tick-Nummer.
var _glaetter := Kern_TaktGlaetter.new()

func _process(delta: float) -> void:
	var ticks_dieses_frames := _glaetter.rahmen(delta)
	if ticks_dieses_frames <= 0:
		return
	for _i in range(ticks_dieses_frames):
		_tick_nummer += 1
		tick.emit(_tick_nummer, tickdauer())

## Einzige zentrale Übersetzung faktor -> ticks im ganzen Projekt.
## Kein anderes System rechnet dies selbst, alle delegieren hierhin.
static func ticks_aus_faktor(faktor: float) -> int:
	var geklemmt := clampf(faktor, FAKTOR_MIN, FAKTOR_MAX)
	return maxi(int(round(geklemmt * FAKTOR_SEKUNDEN * TICK_RATE_HZ)), 1)

## Einzige zentrale Übersetzung Minuten -> ticks. Spielrhythmus-Werte aus
## der Konfiguration werden hier umgerechnet, damit weder Einheiten-Takt
## noch Tageszyklus dieselbe Rechnung separat führen. Die Modifikator-Klemme
## gilt hier nicht: Eine Dauer wird auf ihre eigenen Grenzen geklemmt, sonst
## fielen lange Takte auf 100 Sekunden zusammen und die Nacht verschwände.
static func ticks_aus_minuten(minuten: float) -> int:
	var geklemmte_dauer := clampf(minuten, MINUTEN_MIN, MINUTEN_MAX)
	return maxi(int(round(geklemmte_dauer * 60.0 * TICK_RATE_HZ)), 1)

static func faktor_aus_ticks(ticks: int) -> float:
	if ticks <= 0:
		return FAKTOR_MIN
	return clampf(float(ticks) / (FAKTOR_SEKUNDEN * TICK_RATE_HZ), FAKTOR_MIN, FAKTOR_MAX)

## Einzige zentrale Übersetzung ticks -> Sekunden im ganzen Projekt.
## Dauertexte und Anzeigen lesen sie hier ab, statt TICK_RATE_HZ
## selbst zu teilen und die Formel zu duplizieren.
static func sekunden_aus_ticks(ticks: int) -> float:
	return float(ticks) / TICK_RATE_HZ

## Das Rahmen-Budget in Sekunden: Der höchste Reststand, den der
## Akkumulator nach einem Rahmen tragen darf. Nur die Uhr selbst kennt
## diese Übersetzung, alle anderen lesen sie hier ab.
static func rahmen_budget() -> float:
	return float(MAX_TICKS_PRO_FRAME) / TICK_RATE_HZ

## True, während die Uhr dauerhaft überlastet ist und im entlasteten
## Slow-Takt läuft. Instrumente dürfen das anzeigen; das Spiel selbst
## merkt nur ein leicht ruhigeres Spiel, keinen Sprung.
func im_slow_mode() -> bool:
	return _glaetter.im_slow_mode()

## Zugriff auf den Autoload wie beim SignalBus
static func bus() -> Kern_Weltuhr:
	var baum := Engine.get_main_loop() as SceneTree
	if baum == null or baum.root == null:
		return null
	var knoten := baum.root.get_node_or_null("Weltuhr")
	if knoten is Kern_Weltuhr:
		return knoten as Kern_Weltuhr
	return null


func tick_nummer() -> int:
	return _tick_nummer

func tickdauer() -> float:
	return _glaetter.tickdauer()
