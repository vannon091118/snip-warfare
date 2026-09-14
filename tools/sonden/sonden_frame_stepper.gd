extends RefCounted
class_name Sonden_FrameStepper
## Tick-genaue Steuerung für Sonden. Ein Schritt = ein Weltuhr-Tick (24 Hz).
## Zwischen zwei Frames können beliebig viele Ticks gepumpt werden, immer
## verfolgbar an der Vertragszeile. Kein Spielcode kennt diese Klasse.

var _baum: SceneTree
var _weltuhr: Kern_Weltuhr = null
var _frame_nr: int = 0

func _init(baum: SceneTree) -> void:
	_baum = baum
	var root: Node = baum.root if baum != null else null
	if root != null:
		_weltuhr = root.get_node_or_null("Weltuhr") as Kern_Weltuhr
		if _weltuhr == null:
			# Weltuhr als Autoload liegt als Kind von root — Name exakt.
			for k in root.get_children():
				if k is Kern_Weltuhr:
					_weltuhr = k
					break

func frame_nr() -> int:
	return _frame_nr

func frame_setzen(nr: int) -> void:
	_frame_nr = nr

func auf_frame_warten() -> void:
	_frame_nr += 1
	await _baum.process_frame

func ticks_pumpen(anzahl: int) -> void:
	if anzahl <= 0:
		return
	var delta := 1.0 / 24.0
	for i in anzahl:
		if _weltuhr != null:
			# Weltuhr besitzt das einzige _process der Zeit — wir rufen
			# denselben Pfad wie der Engine-Loop auf, sichtbar im Log.
			_weltuhr._process(delta)
		else:
			# Fallback: direkter Tick ohne Autoload (Headless-Beweis-Setup).
			var w := Engine.get_main_loop() as SceneTree
			if w != null and w.root != null:
				for k in w.root.get_children():
					if k.has_method("_auf_tick"):
						k.call("_auf_tick", _frame_nr, delta)
	_frame_nr += 1
	await _baum.process_frame
	print("SONDE-ZEILE: frame_stepper frame=%d ticks=%d" % [_frame_nr, anzahl])

func warte_frames(anzahl: int) -> void:
	for i in anzahl:
		await auf_frame_warten()
