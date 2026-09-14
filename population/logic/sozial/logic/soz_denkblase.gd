extends Node2D
class_name Soz_Denkblase
## Observer-Spitze der Sozial-Domäne: Sie liest die Gerüchte ihres Trägers
## und zeigt die stärkste Farbe. Keine Logik, keine Maschine; die Wahrheit
## kommt über den Lesen-Ruf des Verdrahters, nicht über eine feste Klasse.

## Kategorie daten: Der eigene Träger und der lesende Manager-Ruf.
var _traeger_id: int = -1
var _lese_ruf: Callable = Callable()
var _blase: PanelContainer = null
var _label: Label = null
var _sichtbar_bis_tick: int = 0
var _letzte_farbe := Color.WHITE

const SICHT_TICKS := 240
## Der Sprite ist 64 Pixel hoch; diese Blase sitzt ueber der Mood-Blase,
## damit keine von beiden den Koerper verdeckt.
const SPRITE_HOEHE := 64.0
const BLASEN_ABSTAND := 56.0

func einrichten(traeger_id: int, lese_ruf: Callable) -> void:
	_traeger_id = traeger_id
	_lese_ruf = lese_ruf

func _ready() -> void:
	_blase = PanelContainer.new()
	var stil := StyleBoxFlat.new()
	stil.corner_radius_top_left = 8
	stil.corner_radius_top_right = 8
	stil.corner_radius_bottom_left = 8
	stil.corner_radius_bottom_right = 8
	stil.content_margin_left = 5
	stil.content_margin_right = 5
	stil.content_margin_top = 2
	stil.content_margin_bottom = 2
	_blase.add_theme_stylebox_override("panel", stil)
	_blase.visible = false
	add_child(_blase)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	_blase.add_child(_label)

func _blase_ueber_kopf_setzen() -> void:
	## Mittig ueber dem Kopf und oberhalb der Mood-Blase: Der Koerper des
	## Strichmaennchens bleibt in jedem Fall sichtbar.
	if _blase == null:
		return
	var groesse := _blase.get_combined_minimum_size()
	_blase.size = groesse
	_blase.position = Vector2(-groesse.x * 0.5, -(SPRITE_HOEHE + BLASEN_ABSTAND) - groesse.y)


func auf_tick(nummer: int) -> void:
	if _blase == null or not _lese_ruf.is_valid():
		return
	var geruechte: Array = _lese_ruf.call(_traeger_id)
	var staerkstes: Soz_Geruecht = null
	for g: Soz_Geruecht in geruechte:
		if g.glaube > 0.05 and (staerkstes == null or g.eskalation() > staerkstes.eskalation()):
			staerkstes = g
	if staerkstes == null:
		if nummer >= _sichtbar_bis_tick:
			_blase.visible = false
		return
	_label.text = staerkstes.erzaehlung()
	_letzte_farbe = staerkstes.farbe()
	var stil: StyleBoxFlat = _blase.get_theme_stylebox("panel")
	stil.bg_color = Color(_letzte_farbe.r, _letzte_farbe.g, _letzte_farbe.b, 0.88)
	_blase_ueber_kopf_setzen()
	_blase.visible = true
	_sichtbar_bis_tick = nummer + SICHT_TICKS
