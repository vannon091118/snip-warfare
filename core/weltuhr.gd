extends Node
class_name Kern_Weltuhr
## Globale Weltuhr: einziger zentraler Tick aller Domänen.
## Jede State Machine, die auf Zeit reagiert, abonniert diesen Tick.
## Tickstandard: klassisches RTS-Prinzip mit 24 Ticks pro Sekunde.

signal tick(tick_nummer: int, delta: float)

const TICK_RATE_HZ := 24.0
const MAX_TICKS_PRO_FRAME := 5

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

func tick_nummer() -> int:
	return _tick_nummer

func tickdauer() -> float:
	return 1.0 / TICK_RATE_HZ
