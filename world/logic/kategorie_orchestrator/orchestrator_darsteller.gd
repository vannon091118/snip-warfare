class_name Orchestrator_Darsteller
## Kategorie daten: Felder für Orchestrator-Darstellung
var konfig: Orchestrator_Konfiguration
var _radius_kreis: Node2D
var _status_indikator: Node2D

## Kategorie logik: Initialisierung
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

## Kategorie logik: Einrichten
func einrichten(neue_konfig: Orchestrator_Konfiguration) -> void:
    konfig = neue_konfig
    position = konfig.position
    queue_redraw()

## Kategorie logik: Zeichnen
func _radius_kreis_zeichnen() -> void:
    var radius := konfig.radius
    var farbe := konfig.farbe
    farbe.a = 0.15
    _radius_kreis.draw_circle(Vector2.ZERO, radius, farbe)
    _radius_kreis.draw_arc(Vector2.ZERO, radius, 0, TAU, 64, farbe, 2.0)

func _status_indikator_zeichnen() -> void:
    var farbe: Color
    match konfig.zustand:
        Orchestrator_Status.Zustand.AKTIV: farbe = Color.GREEN
        Orchestrator_Status.Zustand.PAUSIERT: farbe = Color.GRAY
        Orchestrator_Status.Zustand.KONFIGURIERT: farbe = Color.BLUE
        _: farbe = Color.WHITE

    _status_indikator.draw_circle(Vector2.ZERO, 8.0, farbe)
    _status_indikator.draw_circle(Vector2.ZERO, 8.0, Color.BLACK, false, 2.0)

## Kategorie logik: Status-Aktualisierung
func status_geaendert(neuer_zustand: Orchestrator_Status.Zustand) -> void:
    konfig.zustand = neuer_zustand
    queue_redraw()