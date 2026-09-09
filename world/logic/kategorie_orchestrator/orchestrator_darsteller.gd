extends Node2D
class_name Orchestrator_Darsteller
## Darsteller einer Orchestrator-Zone. Er liest nur die Daten seiner
## Zone und zeichnet Radius und Zustands-Indikator; er ändert keinen
## Zustand und rechnet keine Logik.

## Kategorie daten: die dargestellte Zone und die Zeichenebenen.
var konfig: Orchestrator_Konfiguration = null
var _radius_kreis: Node2D = null
var _status_indikator: Node2D = null

## Kategorie logik: Aufbau, Einrichten und Zeichnen.

func _ready() -> void:
	_radius_kreis = Node2D.new()
	_radius_kreis.name = "RadiusKreis"
	_radius_kreis.draw.connect(_radius_kreis_zeichnen)
	add_child(_radius_kreis)

	_status_indikator = Node2D.new()
	_status_indikator.name = "StatusIndikator"
	_status_indikator.draw.connect(_status_indikator_zeichnen)
	add_child(_status_indikator)

	queue_redraw()

func einrichten(neue_konfig: Orchestrator_Konfiguration) -> void:
	konfig = neue_konfig
	position = konfig.position
	queue_redraw()

func _radius_kreis_zeichnen() -> void:
	if konfig == null:
		return
	var radius := konfig.radius
	var farbe := konfig.farbe
	farbe.a = 0.15
	_radius_kreis.draw_circle(Vector2.ZERO, radius, farbe)
	_radius_kreis.draw_arc(Vector2.ZERO, radius, 0, TAU, 64, farbe, 2.0)

func _status_indikator_zeichnen() -> void:
	if konfig == null:
		return
	var farbe: Color
	match konfig.zustand:
		Orchestrator_Status.Zustand.AKTIV:
			farbe = Color.GREEN
		Orchestrator_Status.Zustand.PAUSIERT:
			farbe = Color.GRAY
		Orchestrator_Status.Zustand.KONFIGURIERT:
			farbe = Color.BLUE
		_:
			farbe = Color.WHITE
	_status_indikator.draw_circle(Vector2.ZERO, 8.0, farbe)
	_status_indikator.draw_circle(Vector2.ZERO, 8.0, Color.BLACK, false, 2.0)

func status_geaendert(neuer_zustand: Orchestrator_Status.Zustand) -> void:
	# Rein lesend: Nur die Anzeige folgt dem gemeldeten Zustand.
	if konfig == null:
		return
	konfig.zustand = neuer_zustand
	queue_redraw()
