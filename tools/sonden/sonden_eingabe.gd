extends RefCounted
class_name Sonden_Eingabe
## Injiziert echte InputEvents wie ein Spieler. Jedes Event ist so
## getreulich wie ein echter Klick/Drag/Menü-Aufruf, damit Feedback
## (Selektion, Hover, Kontextmenü, Blende) denselben Pfad nimmt.
## Nur Sonden laden diese Klasse; im Spiel existiert sie nicht.

var _baum: SceneTree

func _init(baum: SceneTree) -> void:
	_baum = baum

func _viewport() -> Viewport:
	return _baum.root if _baum != null else null

func maus_bewegen(auf: Vector2) -> void:
	var vp := _viewport()
	if vp == null:
		return
	var ev := InputEventMouseMotion.new()
	ev.position = auf
	ev.global_position = auf
	Input.parse_input_event(ev)
	print("SONDE-ZEILE: eingabe=maus_bewegen pos=%.0f,%.0f frame=%d" % [auf.x, auf.y, _baum.root.get_child_count() if _baum.root else 0])

func klick_links(auf: Vector2) -> void:
	var vp := _viewport()
	if vp == null:
		return
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = auf
	down.global_position = auf
	Input.parse_input_event(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = auf
	up.global_position = auf
	Input.parse_input_event(up)
	print("SONDE-ZEILE: eingabe=klick_links pos=%.0f,%.0f" % [auf.x, auf.y])

func drag_links(von: Vector2, nach: Vector2, schritte: int = 8) -> void:
	var vp := _viewport()
	if vp == null:
		return
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = von
	Input.parse_input_event(down)
	for i in schritte:
		var t := float(i + 1) / float(schritte)
		var pos := von.lerp(nach, t)
		var mv := InputEventMouseMotion.new()
		mv.position = pos
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mv)
		await _baum.process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = nach
	Input.parse_input_event(up)
	print("SONDE-ZEILE: eingabe=drag_links von=%.0f,%.0f nach=%.0f,%.0f" % [von.x, von.y, nach.x, nach.y])

func klick_rechts(auf: Vector2) -> void:
	var vp := _viewport()
	if vp == null:
		return
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_RIGHT
	down.pressed = true
	down.position = auf
	Input.parse_input_event(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_RIGHT
	up.pressed = false
	up.position = auf
	Input.parse_input_event(up)
	print("SONDE-ZEILE: eingabe=klick_rechts pos=%.0f,%.0f" % [auf.x, auf.y])

func cursor_form() -> int:
	return DisplayServer.cursor_get_shape()

func cursor_ausschnitt_bild(groesse: int = 32) -> Image:
	var vp := _viewport()
	if vp == null:
		return null
	var voll: Image = vp.get_texture().get_image()
	var maus := vp.get_mouse_position()
	var r := Rect2i(int(maus.x) - groesse / 2, int(maus.y) - groesse / 2, groesse, groesse)
	r = r.intersection(Rect2i(0, 0, voll.get_width(), voll.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return voll
	var ausschnitt := Image.create(r.size.x, r.size.y, false, voll.get_format())
	for y in r.size.y:
		for x in r.size.x:
			ausschnitt.set_pixel(x, y, voll.get_pixel(r.position.x + x, r.position.y + y))
	return ausschnitt
