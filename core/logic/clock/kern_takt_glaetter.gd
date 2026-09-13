extends RefCounted
class_name Kern_TaktGlaetter
## Takt-Glätter der Weltuhr: Er hält den Akkumulator und entscheidet
## mechanisch, wie viele Ticks ein Rahmen läuft. Rohdeltas werden über ein
## rollendes Mittel geglättet, damit ein einzelner Ruckler nie in einen
## Aufhol-Zeitsprung kippt, den der Spieler spürt. Dauerhafte Überlastung
## (das Mittel bleibt über dem Tick-Soll) kippt in den Slow-Mode: Die Uhr
## taktet stabiler, aber messbar langsamer weiter, statt zu spiralen oder
## Zeit zu verlieren. Die Stabilisierung ist selbsttragend: Fällt das
## geglättete Delta wieder unter das Soll, kehrt die Uhr von allein in den
## Normaltakt zurück. Kein zweites System kennt diese Mechanik; die Uhr
## reicht nur durch.

const TICK_RATE_HZ := 24.0
const MAX_TICKS_PRO_FRAME := 5
## Fenster des rollenden Mittels in Rahmen. Groß genug, um Ausreißer zu
## verschlucken; klein genug, um dauerhafter Überlastung in wenigen
## Sekunden zu folgen (32 Rahmen sind rund eine halbe Sekunde).
const GEAETTETE_RAHMEN := 32
## Erst wenn das geglättete Delta dauerhaft über dem Soll liegt, kippt die
## Uhr in den Slow-Mode; einzelne Spitzen bleiben ohne jede Wirkung.
const SLOWMODE_SCHWELLE := 1.05
## Im Slow-Mode läuft der Takt auf diesen Anteil des Soll langsamer; die
## Simulation bleibt selbststabil, der Spieler sieht keinen Sprung, nur
## ein leicht ruhigeres Spiel.
const SLOWMODE_FAKTOR := 0.8

var _akkumulator: float = 0.0
var _geaettet: float = 1.0 / TICK_RATE_HZ
var _slow_mode: bool = false

## Nimmt ein Rahmen-Delta und liefert die Anzahl der zu laufenden Ticks.
## Der Rückgabewert bleibt immer im Rahmen-Budget; ein Rest im Akkumulator
## wird bewusst getragen, nicht verworfen, weil das Glätten kleine Reste
## von selbst wieder einsammelt.
func rahmen(delta: float) -> int:
	_delta_nivellieren(delta)
	_akkumulator += _geaettet
	var tick_soll := tickdauer()
	var ticks := 0
	while _akkumulator >= tick_soll and ticks < MAX_TICKS_PRO_FRAME:
		_akkumulator -= tick_soll
		ticks += 1
	_slow_mode_aktualisieren()
	return ticks

func _delta_nivellieren(delta: float) -> void:
	_geaettet += (delta - _geaettet) / float(GEAETTETE_RAHMEN)

func _slow_mode_aktualisieren() -> void:
	## Selbststabilisierung: Dauerhaft über dem Soll kippt in den Slow-Mode,
	## wieder darunter kippt zurück. Kein Hysterese-Fenster nötig, weil das
	## rollende Mittel selbst schon träge ist.
	_slow_mode = _geaettet > tickdauer() * SLOWMODE_SCHWELLE

func im_slow_mode() -> bool:
	return _slow_mode

func geaettetes_delta() -> float:
	return _geaettet

func tickdauer() -> float:
	var solldauer := 1.0 / TICK_RATE_HZ
	return solldauer / SLOWMODE_FAKTOR if _slow_mode else solldauer

func akkumulator() -> float:
	return _akkumulator
