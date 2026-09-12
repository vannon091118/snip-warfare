extends Node2D
class_name Welt_SchadenAnzeige
## Visuelles Feedback eines Schadens-Ereignisses: Sie zeigt am Ziel eine
## rote Zahl mit Schadensart, schwebt als Tween der Engine nach oben und
## verblasst. Kein Uhr-Abo, keine Tick-Buchhaltung: Der Knoten rechnet
## nichts, die Dauer kommt aus derselben zentralen Faktor-Übersetzung
## wie vorher der Tick-Lauf.

## Kategorie daten: der anzuzeigende Zustand.
var schaden: int = 0
var art: String = "physisch"
var icon_pfad: String = "res://world/assets/ui/schaden.svg"
var _start_position := Vector2.ZERO

## Kategorie logik: Lebenszyklus der Anzeige.
const DAUER_FAKTOR := 0.09
const HUB_HOEHE := 48.0
const SKALIERUNG_MAX := 0.12

var _icon: TextureRect = null
var _label: Label = null
var _kasten: HBoxContainer = null

func einrichten(schaden_erhalten: int, art_erhalten: String, welt_position: Vector2) -> void:
	schaden = schaden_erhalten
	art = art_erhalten
	_start_position = welt_position + Vector2(0, -HUB_HOEHE)
	position = _start_position

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
	_label.text = "-%d %s" % [schaden, art]
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.62, 0.15, 0.12, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.92))
	_label.add_theme_constant_override("outline_size", 5)
	_kasten.add_child(_label)
	var schatten := ColorRect.new()
	schatten.color = Color(0, 0, 0, 0.10)
	schatten.custom_minimum_size = Vector2(72, 20)
	schatten.position = Vector2(-36, 6)
	schatten.z_index = -1
	add_child(schatten)
	move_child(schatten, 0)
	_hub_starten()

func _hub_starten() -> void:
	# Der Hub ist Darstellung, nicht Simulation: Die Dauer entsteht aus
	# derselben zentralen Faktor-Übersetzung (faktor -> ticks -> Sekunden),
	# der Ablauf gehört dem Tween der Engine. Am Ende freigeben.
	var dauer := float(Kern_Weltuhr.ticks_aus_faktor(DAUER_FAKTOR)) / Kern_Weltuhr.TICK_RATE_HZ
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", _start_position.y - HUB_HOEHE, dauer)
	tween.tween_property(self, "modulate:a", 0.0, dauer)
	tween.tween_property(self, "scale", Vector2.ONE * (1.0 + SKALIERUNG_MAX), dauer)
	tween.chain().tween_callback(queue_free)
