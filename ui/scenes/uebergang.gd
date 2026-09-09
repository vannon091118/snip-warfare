extends Node2D
## Übergangs-Verbindung zwischen Szenen: Diese 2D-Szene kündigt die nächste
## Szene an, zeigt den Zieltext und läutet sie nach kurzer Zeit oder auf
## Klick beziehungsweise Leertaste ein. Sie ist die Verbindungs-Stelle, an
## der später Events und Cutscenes zwischen Szenen eingefügt werden können.
## Sie liest das Ziel ausschließlich aus der Sitzung und besitzt keine
## Simulationslogik, keine eigene Zeitwahrheit und kein fachliches Wissen.

const FALLBACK_ZIEL := "res://ui/scenes/hauptmenue.tscn"
const WARTE_SEKUNDEN := 1.4

var _verstrichen: float = 0.0
var _ziel: String = ""

@onready var _text_label: Label = %TextLabel
@onready var _hinweis_label: Label = %HinweisLabel
@onready var _deckel: ColorRect = %Deckel

func _ready() -> void:
	_ziel = WeltSitzung.uebergang_ziel
	if _ziel == "":
		_ziel = FALLBACK_ZIEL
	var ankündigung := WeltSitzung.uebergang_text
	if ankündigung == "":
		ankündigung = "Die Welt erwacht …"
	_text_label.text = ankündigung
	_deckel.color = Color(0, 0, 0, 1.0)
	_deckel.color.a = 1.0

func _process(delta: float) -> void:
	_verstrichen += delta
	# Einblenden in den ersten Sekunden, danach die nächste Szene einläuten.
	if _verstrichen < 0.7:
		_deckel.color.a = clampf(1.0 - _verstrichen / 0.7, 0.0, 1.0)
	else:
		_deckel.color.a = 0.0
	if _verstrichen >= WARTE_SEKUNDEN:
		_weiter()
		return
	_hinweis_label.visible = int(_verstrichen * 2.0) % 2 == 0

func _unhandled_input(ereignis: InputEvent) -> void:
	# Überspringen: Linksklick, Leertaste oder Enter läuten sofort weiter.
	if _verstrichen < 0.3:
		return
	var ueberspringen := false
	if ereignis is InputEventMouseButton and ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		ueberspringen = true
	elif ereignis is InputEventKey and ereignis.pressed and (ereignis.keycode == KEY_SPACE or ereignis.keycode == KEY_ENTER):
		ueberspringen = true
	if ueberspringen:
		_weiter()

func _weiter() -> void:
	# Einmalige Verbindung: Die nächste Szene wird nur einmal eingeläutet.
	set_process(false)
	get_tree().change_scene_to_file(_ziel)