extends ColorRect
## Selection-Spitze: Auswahl-Rechteck für die Massenwahl. Sie zeichnet nur
## den Rahmen zwischen Start- und Endpunkt im Bildschirmraum und sagt, ob
## er sichtbar ist. Sie wählt keine Einheiten aus und mischt sich in keine
## Job-Kette.
## Kette: PrototypKarte (Eingabe) -> rechteck_setzen(start, ende) -> Sichtbarkeit.

## Kategorie daten: der aktuelle Rahmen als Zustand der Anzeige.
var zieht_gerade: bool = false

## Kategorie logik: Rahmen setzen und verbergen.

func _ready() -> void:
	color = Color(0.5, 0.7, 1.0, 0.18)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func rechteck_setzen(start_bild: Vector2, ende_bild: Vector2) -> void:
	var rect := Rect2(start_bild, ende_bild - start_bild).abs()
	position = rect.position
	size = rect.size
	zieht_gerade = rect.size.length() > 6.0
	visible = zieht_gerade

func rechteck_verbergen() -> void:
	zieht_gerade = false
	visible = false
