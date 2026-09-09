extends Node2D
class_name Pop_Denkblase
## Observer-Spitze je Stickman: liest Pop_Mood und zeigt Sprechblase.
## Keine Logik, keine Maschine – nur Visualisierung.
## Kette: Pop_MoodMaschine -> mood_geaendert -> Denkblase zeigt Blase.

var _maschine: Pop_MoodMaschine = null
var _blase: PanelContainer = null
var _label: Label = null
var _ausstehend: Pop_Mood = null

func einrichten(maschine: Pop_MoodMaschine) -> void:
	_maschine = maschine
	if _maschine != null:
		_maschine.mood_geaendert.connect(_auf_mood)
		if _blase != null:
			_auf_mood(_maschine.mood())
		else:
			_ausstehend = _maschine.mood()

func _ready() -> void:
	_blase = PanelContainer.new()
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(1, 1, 1, 0.92)
	stil.corner_radius_top_left = 10
	stil.corner_radius_top_right = 10
	stil.corner_radius_bottom_left = 10
	stil.corner_radius_bottom_right = 10
	stil.content_margin_left = 6
	stil.content_margin_right = 6
	stil.content_margin_top = 3
	stil.content_margin_bottom = 3
	_blase.add_theme_stylebox_override("panel", stil)
	_blase.position = Vector2(-28, -74)
	_blase.visible = false
	add_child(_blase)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18, 1.0))
	_blase.add_child(_label)
	if _ausstehend != null:
		_auf_mood(_ausstehend)
		_ausstehend = null
	elif _maschine != null:
		_auf_mood(_maschine.mood())

func _auf_mood(mood: Pop_Mood) -> void:
	if _blase == null or _label == null:
		_ausstehend = mood
		return
	if mood == null or mood.leer():
		_blase.visible = false
		return
	_label.text = "%s %s" % [mood.emoji, mood.sprechblase_text]
	_blase.visible = true
