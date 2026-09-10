extends Node
class_name Kern_Weltuhr
## Globale Weltuhr: einziger zentraler Tick aller Domänen. RT-Pyramide:
## Weltuhr ist die Basis der Pyramide, darauf stehen Registries und
## State Maschinen. Jede zeitabhängige Berechnung läuft nur hierüber.
## Tickstandard: klassisches RTS-Prinzip mit 24 Ticks pro Sekunde.
## Faktor 1.0 bedeutet 10 Sekunden auf dieser Uhr.

signal tick(tick_nummer: int, delta: float)

const TICK_RATE_HZ := 24.0
const MAX_TICKS_PRO_FRAME := 5
const FAKTOR_SEKUNDEN := 10.0
const FAKTOR_MIN := 0.1
const FAKTOR_MAX := 10.0

var _tick_nummer: int = 0
var _akkumulator: float = 0.0

func _process(delta: float) -> void:
	_akkumulator += delta
	var ticks_dieses_frames := 0
	while _akkumulator >= 1.0 / TICK_RATE_HZ and ticks_dieses_frames < MAX_TICKS_PRO_FRAME:
		_akkumulator -= 1.0 / TICK_RATE_HZ
		_tick_nummer += 1
		tick.emit(_tick_nummer, 1.0 / TICK_RATE_HZ)
		ticks_dieses_frames += 1
	# Spiralen-Schutz: Bricht die Schleife am Rahmen-Maximum ab, darf der
	# Rest im Akkumulator nicht stehen bleiben, sonst jagt die Uhr nach
	# jedem Ruckler dauerhaft mit vollem Rahmen-Budget und holt nie wieder
	# auf. Alles ueber einem vollen Rahmen-Budget faellt bewusst weg, der
	# Rueckstand wird verworfen statt nachgeholt, und der Verlust wird
	# gemeldet, damit kein Zeitraffer unbemerkt bleibt.
	if _akkumulator > rahmen_budget():
		_akkumulator = rahmen_budget()
		push_warning("Weltuhr: Rueckstand nach Ruckler verworfen, naechste Rahmen laufen mit vollem Budget.")

## Einzige zentrale Übersetzung faktor -> ticks im ganzen Projekt.
## Kein anderes System rechnet dies selbst, alle delegieren hierhin.
static func ticks_aus_faktor(faktor: float) -> int:
	var geklemmt := clampf(faktor, FAKTOR_MIN, FAKTOR_MAX)
	return maxi(int(round(geklemmt * FAKTOR_SEKUNDEN * TICK_RATE_HZ)), 1)

static func faktor_aus_ticks(ticks: int) -> float:
	if ticks <= 0:
		return FAKTOR_MIN
	return clampf(float(ticks) / (FAKTOR_SEKUNDEN * TICK_RATE_HZ), FAKTOR_MIN, FAKTOR_MAX)

## Das Rahmen-Budget in Sekunden: Der hoechste Reststand, den der
## Akkumulator nach einem Rahmen tragen darf. Nur die Uhr selbst kennt
## diese Übersetzung, alle anderen lesen sie hier ab.
static func rahmen_budget() -> float:
	return float(MAX_TICKS_PRO_FRAME) / TICK_RATE_HZ


func tick_nummer() -> int:
	return _tick_nummer

func tickdauer() -> float:
	return 1.0 / TICK_RATE_HZ
