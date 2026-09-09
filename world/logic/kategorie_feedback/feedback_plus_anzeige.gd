extends Node2D
class_name Welt_PlusAnzeige
## Visuelles Feedback einer abgeschlossenen Arbeit (Preflight-Gate E022):
## Jede Aktion zeigt am Ziel-Objekt das passende Ressourcen-Icon und einen
## +X Zähler (Menge des Jobs). Die Registries liefern über logik_id und
## faktor die Logik; die Anzeige schwebt 0.9 Sekunden nach oben und verblasst.

## Kategorie daten: der anzuzeigende Zustand.
var ressource: String = ""
var menge: int = 0
var icon_pfad: String = ""
var _vergangen: float = 0.0
var _start_position := Vector2.ZERO

## Kategorie logik: Lebenszyklus der Anzeige.

const DAUER := 0.9
const HUB_HOEHE := 48.0

@onready var _icon: TextureRect = null
@onready var _label: Label = null
@onready var _kasten: HBoxContainer = null

func einrichten(ressource_id: String, menge_erhalten: int, icon: String, welt_position: Vector2) -> void:
	ressource = ressource_id
	menge = menge_erhalten
	icon_pfad = icon
	position = welt_position + Vector2(0, -HUB_HOEHE)

func _ready() -> void:
	_kasten = HBoxContainer.new()
	_kasten.alignment = BoxContainer.ALIGNMENT_CENTER
	_kasten.add_theme_constant_override("separation", 4)
	add_child(_kasten)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(22, 22)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_pfad != "" and ResourceLoader.exists(icon_pfad):
		_icon.texture = load(icon_pfad)
	_kasten.add_child(_icon)
	_label = Label.new()
	_label.text = "+%d" % menge
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.23, 0.25, 0.20, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.92))
	_label.add_theme_constant_override("outline_size", 5)
	_kasten.add_child(_label)
	# Leichter Schatten unter dem Text
	var schatten := ColorRect.new()
	schatten.color = Color(0, 0, 0, 0.10)
	schatten.custom_minimum_size = Vector2(56, 20)
	schatten.position = Vector2(-28, 6)
	schatten.z_index = -1
	add_child(schatten)
	move_child(schatten, 0)

func _process(delta: float) -> void:
	_vergangen += delta
	var anteil := clampf(_vergangen / DAUER, 0.0, 1.0)
	position.y -= delta * 38.0
	modulate.a = 1.0 - anteil
	scale = Vector2.ONE * (1.0 + anteil * 0.12)
	if _vergangen >= DAUER:
		queue_free()
