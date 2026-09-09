extends Control
## Selection-Spitze: Auswahl-Rechteck für die Massenwahl. Sie zeichnet nur
## den Rahmen zwischen Start- und Endpunkt im Bildschirmraum und sagt, ob
## er sichtbar ist. Sie wählt keine Einheiten aus und mischt sich in keine
## Job-Kette.
## Kette: PrototypKarte (Eingabe) -> rechteck_setzen(start, ende) -> _draw().
## Zeichnet sich selbst statt einen unterlegten ColorRect zu skalieren:
## ein Node weniger im Baum, Farben konfigurierbar über exports.

## Kategorie daten: der aktuelle Rahmen als Zustand der Anzeige.
var zieht_gerade: bool = false
var _rahmen: Rect2 = Rect2()

@export var fuellung_farbe: Color = Color(0.5, 0.7, 1.0, 0.18)
@export var rand_farbe: Color = Color(0.5, 0.7, 1.0, 0.85)
@export var rand_breite: float = 1.5

## Kategorie logik: Rahmen setzen, verbergen und zeichnen.

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func rechteck_setzen(start_bild: Vector2, ende_bild: Vector2) -> void:
	_rahmen = Rect2(start_bild, ende_bild - start_bild).abs()
	zieht_gerade = _rahmen.size.length() > 6.0
	visible = zieht_gerade
	queue_redraw()

func rechteck_verbergen() -> void:
	zieht_gerade = false
	visible = false
	queue_redraw()

func _draw() -> void:
	if not zieht_gerade:
		return
	# Füllung und Rand direkt im CanvasLayer-Bildschirmraum; kein Kind-Node nötig.
	draw_rect(_rahmen, fuellung_farbe, true)
	draw_rect(_rahmen, rand_farbe, false, rand_breite)
