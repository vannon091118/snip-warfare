extends CanvasLayer
## WaermeOverlay: Fullscreen ColorRect mit Heat-Shader.
## mouse_filter = IGNORE, damit Klicks durchgehen.
## Wird von Welt_WaermeSammler nach jedem Tick aktualisiert.

@onready var _overlay: ColorRect = %WaermeRect
var _material: ShaderMaterial = null

func _ready() -> void:
	layer = 10
	_material = Welt_WaermeShader.new().material_neu()
	_overlay.material = _material
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func waerme_wert_setzen(wert: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("waerme_wert", clampf(wert, 0.0, 1.0))