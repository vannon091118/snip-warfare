extends Node2D
## Übergangs-Verbindung zwischen Szenen: Diese 2D-Szene kündigt die nächste
## Szene an, zeigt den Zieltext und läutet sie nach kurzer Zeit oder auf
## Klick beziehungsweise Leertaste ein. Sie ist die Verbindungs-Stelle, an
## der später Events und Cutscenes zwischen Szenen eingefügt werden können.
## Sie liest das Ziel ausschließlich aus der Sitzung und besitzt keine
## Simulationslogik, keine eigene Zeitwahrheit und kein fachliches Wissen.
## Das Warten und Blenden gehört dem Timer und dem Tween der Engine; die
## Szene selbst führt keinen Zähler mehr und rechnet nichts.

const FALLBACK_ZIEL := "res://ui/scenes/hauptmenue.tscn"
const WARTE_SEKUNDEN := 1.4
const EINBLEND_SEKUNDEN := 0.7
const BLINK_SEKUNDEN := 0.5
const SPRUNGSCHUTZ_SEKUNDEN := 0.3

var _ziel: String = ""
var _sprung_erlaubt: bool = false
var _weiter_gestartet: bool = false

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
	var deckel_tween := create_tween()
	deckel_tween.tween_property(_deckel, "color:a", 0.0, EINBLEND_SEKUNDEN)
	var hinweis_tween := create_tween().set_loops()
	hinweis_tween.tween_interval(BLINK_SEKUNDEN)
	hinweis_tween.tween_callback(_hinweis_umschalten)
	get_tree().create_timer(SPRUNGSCHUTZ_SEKUNDEN).timeout.connect(_sprung_freigeben)
	get_tree().create_timer(WARTE_SEKUNDEN).timeout.connect(_weiter)

func _sprung_freigeben() -> void:
	_sprung_erlaubt = true

func _hinweis_umschalten() -> void:
	_hinweis_label.visible = not _hinweis_label.visible

func _unhandled_input(ereignis: InputEvent) -> void:
	# Überspringen: Linksklick, Leertaste oder Enter läuten sofort weiter.
	if _weiter_gestartet or not _sprung_erlaubt:
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
	if _weiter_gestartet:
		return
	_weiter_gestartet = true
	get_tree().change_scene_to_file(_ziel)
