extends CanvasLayer
## Observer-Spitze: Färbt die Welt über einen Schablonen-Schieber.
## Liest nur TageszyklusMaschine, besitzt keine Logik, kein Tick selbst.

var _maschine: Welt_TageszyklusMaschine = null
var _overlay: ColorRect = null

func einrichten(maschine: Welt_TageszyklusMaschine) -> void:
	_maschine = maschine
	if _maschine != null:
		_maschine.phase_geaendert.connect(_auf_phase)

func _ready() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0, 0, 0, 0)
	add_child(_overlay)
	if _maschine != null:
		_faerben(_maschine.helligkeit(), _maschine.schablonen_alpha(), _maschine.faerbung())

func _auf_phase(_phase: int, _hell: float) -> void:
	if _maschine != null:
		_faerben(_maschine.helligkeit(), _maschine.schablonen_alpha(), _maschine.faerbung())

func _faerben(helligkeit: float, alpha: float, farbe: Color) -> void:
	if _overlay == null:
		return
	var dunkel := 1.0 - clampf(helligkeit, 0.0, 1.0)
	_overlay.color = Color(farbe.r * dunkel * 0.3, farbe.g * dunkel * 0.3, farbe.b * dunkel * 0.5, alpha)
