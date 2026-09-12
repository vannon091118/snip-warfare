extends Node2D
class_name Ui_AuswahlMarkierung
## Visuelle Auswahl-Markierung fuer selektierte Einheiten.
## Zeichnet einen animierten, schwebenden goldenen Stern
## direkt ueber der aktiven Einheit.

var _schweb_zeit: float = 0.0
var _aktiv: bool = true

func _process(delta: float) -> void:
	if not visible or not _aktiv:
		return
	_schweb_zeit += delta * 4.0
	queue_redraw()

func aktiv_setzen(ist_aktiv: bool) -> void:
	_aktiv = ist_aktiv
	visible = ist_aktiv
	if ist_aktiv:
		queue_redraw()

func _draw() -> void:
	if not _aktiv:
		return

	# Schwebender Offset ueber dem Kopf der Einheit (-52 px plus Sinus-Welle)
	var schweb := sin(_schweb_zeit) * 3.5
	var zentrum := Vector2(0.0, -56.0 + schweb)

	# Goldener Stern / Diamant
	var spitzen: PackedVector2Array = [
		zentrum + Vector2(0.0, -9.0),
		zentrum + Vector2(3.0, -3.0),
		zentrum + Vector2(9.0, 0.0),
		zentrum + Vector2(3.0, 3.0),
		zentrum + Vector2(0.0, 9.0),
		zentrum + Vector2(-3.0, 3.0),
		zentrum + Vector2(-9.0, 0.0),
		zentrum + Vector2(-3.0, -3.0),
	]

	# Dunkler Rand fuer hohen Kontrast ueber jedem Terrain
	var rand_punkte: PackedVector2Array = []
	for p in spitzen:
		var richtung := (p - zentrum).normalized() * 1.5
		rand_punkte.append(p + richtung)
	draw_colored_polygon(rand_punkte, Color(0.1, 0.1, 0.1, 0.85))

	# Goldene Stern-Flaeche
	draw_colored_polygon(spitzen, Color(1.0, 0.85, 0.15, 0.95))

	# Weisser Glanz-Kern im Zentrum
	var kern: PackedVector2Array = [
		zentrum + Vector2(0.0, -4.0),
		zentrum + Vector2(4.0, 0.0),
		zentrum + Vector2(0.0, 4.0),
		zentrum + Vector2(-4.0, 0.0),
	]
	draw_colored_polygon(kern, Color(1.0, 1.0, 0.9, 0.95))
