extends RefCounted
class_name Welt_KarawanenZeichner
## Zeichner der Karawanen: Punkte mit Fortschrittsbalken und Kennung auf der
## Karte. Reine Darstellung; er liest nur und malt, er rechnet und tickt
## nichts. Die Farben je Zustand bleiben hier an einer Stelle.

const PUNKT_RADIUS := 6.0
const BALKEN_HOEHE := 3.0
const FARBE := Color(1.0, 0.9, 0.2)
const RAND_FARBE := Color(0.3, 0.2, 0.0)

func zeichnen(canvas: CanvasItem, karawanen: Array[Welt_Karawane], eigene_map_id: String) -> void:
	for karawane: Welt_Karawane in karawanen:
		if karawane == null or not _ist_meine(karawane, eigene_map_id):
			continue
		_punkt(canvas, karawane)

func _ist_meine(karawane: Welt_Karawane, eigene_map_id: String) -> bool:
	return (karawane.von_map_id == eigene_map_id) or (karawane.nach_map_id == eigene_map_id)

func _punkt(canvas: CanvasItem, karawane: Welt_Karawane) -> void:
	var pos := karawane.position_aktuel()
	var zustand := karawane.zustand()
	canvas.draw_circle(pos, PUNKT_RADIUS, _farbe_fuer(zustand))
	canvas.draw_circle(pos, PUNKT_RADIUS, RAND_FARBE, false, 2.0)
	if zustand == "unterwegs":
		_balken(canvas, pos, karawane._aktueller_fortschritt)
	canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-20, PUNKT_RADIUS + 10), karawane.karawanen_id, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

func _farbe_fuer(zustand: String) -> Color:
	if zustand == "wartend":
		return Color(0.6, 0.6, 0.6)
	if zustand == "angekommen" or zustand == "entladen":
		return Color(0.2, 1.0, 0.3)
	if zustand == "fertig":
		return Color(0.5, 0.5, 0.5)
	return FARBE

func _balken(canvas: CanvasItem, pos: Vector2, fortschritt: float) -> void:
	var breite := PUNKT_RADIUS * 4.0
	var balken_pos := pos + Vector2(-breite * 0.5, -PUNKT_RADIUS - 8.0)
	canvas.draw_rect(Rect2(balken_pos, Vector2(breite, BALKEN_HOEHE)), Color(0, 0, 0, 0.5))
	canvas.draw_rect(Rect2(balken_pos, Vector2(breite * fortschritt, BALKEN_HOEHE)), FARBE)
