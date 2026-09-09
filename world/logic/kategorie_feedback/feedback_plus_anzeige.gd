extends Node2D
class_name Welt_PlusAnzeige
## Visuelles Feedback einer abgeschlossenen Arbeit (Preflight-Gate E022):
## Jede Aktion zeigt am Ziel-Objekt das passende Ressourcen-Icon und einen
## +X Zähler (Menge des Jobs). Die Registries liefern über logik_id und
## faktor die Logik; die Anzeige schwebt tick-basiert nach oben und verblasst.

## Kategorie daten: der anzuzeigende Zustand.
var ressource: String = ""
var menge: int = 0
var icon_pfad: String = ""
var _start_position := Vector2.ZERO
var _verbleibende_ticks: int = 0
var _gesamt_ticks: int = 0
var _tick_nummer: int = 0

## Kategorie logik: Lebenszyklus der Anzeige.
const DAUER_FAKTOR := 0.09
const HUB_HOEHE := 48.0
const BEWEGUNG_PRO_TICK := 38.0 / 24.0
const SKALIERUNG_MAX := 0.12

@onready var _icon: TextureRect = null
@onready var _label: Label = null
@onready var _kasten: HBoxContainer = null

func einrichten(ressource_id: String, menge_erhalten: int, icon: String, welt_position: Vector2) -> void:
	ressource = ressource_id
	menge = menge_erhalten
	icon_pfad = icon
	_start_position = welt_position + Vector2(0, -HUB_HOEHE)
	position = _start_position
	_verbleibende_ticks = Kern_Weltuhr.ticks_aus_faktor(DAUER_FAKTOR)
	_gesamt_ticks = _verbleibende_ticks

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
	var schatten := ColorRect.new()
	schatten.color = Color(0, 0, 0, 0.10)
	schatten.custom_minimum_size = Vector2(56, 20)
	schatten.position = Vector2(-28, 6)
	schatten.z_index = -1
	add_child(schatten)
	move_child(schatten, 0)

func _enter_tree() -> void:
	Weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	Weltuhr.tick.disconnect(_auf_tick)

func _auf_tick(tick_nummer: int, delta: float) -> void:
	_tick_nummer = tick_nummer
	_verbleibende_ticks -= 1
	var anteil: float = 1.0 - float(_verbleibende_ticks) / float(_gesamt_ticks)
	position.y -= BEWEGUNG_PRO_TICK
	modulate.a = 1.0 - anteil
	scale = Vector2.ONE * (1.0 + anteil * SKALIERUNG_MAX)
	if _verbleibende_ticks <= 0:
		queue_free()