extends Node2D
class_name Pop_Denkblase
## Observer-Spitze je Stickman: liest Pop_Mood und zeigt Sprechblase.
## Keine Logik, keine Maschine – nur Visualisierung. Sie zeigt die
## Erzählung der Mood: erst den Grund, darunter die Wirkung, beides mit
## den Emojis der erreichten Eskalationsstufe aus dem Datenpool.
## Kette: Pop_MoodMaschine -> mood_geaendert -> Denkblase zeigt Blase.

## Der Sprite des Strichmaennchens ist 64 Pixel hoch und steht auf der
## Fusslinie; darueber darf nur Luft sein. Die Blase waechst deshalb nach
## oben und kann den Koerper nicht mehr verdecken.
const SPRITE_HOEHE := 64.0
const KOPF_ABSTAND := 10.0

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
	_label.text = mood.erzaehlung()
	_blase_ueber_kopf_setzen()
	_blase.visible = true

func _blase_ueber_kopf_setzen() -> void:
	## Mittig ueber dem Kopf, mit der Unterkante oberhalb des Sprites. Die
	## Groesse kommt aus der Mindestgroesse des Inhalts, ist also schon vor
	## dem ersten Layout bekannt.
	if _blase == null:
		return
	var groesse := _blase.get_combined_minimum_size()
	_blase.size = groesse
	_blase.position = Vector2(-groesse.x * 0.5, -(SPRITE_HOEHE + KOPF_ABSTAND) - groesse.y)
