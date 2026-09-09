extends RefCounted
class_name Ui_KameraSteuerung
## Spitze: Kamera-Steuerung. Besitzt ausschließlich die Kamera-Zustände
## (Position, Zoom) und deren Bewegung. Keine Jobs, keine Welt-Generierung,
## keine Lager-Logik. Liest nur Kern_SteuerungRegistry für Geschwindigkeit.

const KAMERA_ZOOM_SCHRITT := 1.1
const KAMERA_ZOOM_MIN := 0.2
const KAMERA_ZOOM_MAX := 2.5

var spieler_position: Vector2 = Vector2.ZERO
var _steuerung: Kern_SteuerungRegistry = null
var _model: Welt_Model = null

func einrichten(steuerung: Kern_SteuerungRegistry, model: Welt_Model, start_position: Vector2) -> void:
	_steuerung = steuerung
	_model = model
	spieler_position = start_position

func kamera_bewegen(delta: float, kamera: Camera2D, spieler: Node2D) -> void:
	var richtung := _lese_kamera_richtung()
	var geschw := _steuerung.steuerung.kamera_geschwindigkeit if _steuerung != null and _steuerung.steuerung != null else 520.0
	spieler_position += richtung * geschw * delta
	if _model != null:
		var karten_groesse := Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE
		spieler_position = spieler_position.clamp(Vector2.ZERO, karten_groesse)
	if kamera != null:
		kamera.position = spieler_position
	if spieler != null:
		spieler.position = spieler_position

func zoom(faktor: float, kamera: Camera2D) -> void:
	if kamera == null:
		return
	var neuer_zoom: float = clampf(kamera.zoom.x * faktor, KAMERA_ZOOM_MIN, KAMERA_ZOOM_MAX)
	kamera.zoom = Vector2(neuer_zoom, neuer_zoom)

func zoom_schritt() -> float:
	return KAMERA_ZOOM_SCHRITT

func _lese_kamera_richtung() -> Vector2:
	if _steuerung == null or _steuerung.steuerung == null or _steuerung.steuerung.kamera_tasten.is_empty():
		return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var richtung := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		richtung.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		richtung.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		richtung.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		richtung.x += 1.0
	return richtung.normalized() if richtung.length() > 1.0 else richtung
