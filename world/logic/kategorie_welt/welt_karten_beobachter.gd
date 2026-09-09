extends RefCounted
class_name Welt_KartenBeobachter
## Spitze: Karten-Beobachter. Reiner Observer über denselben
## autoritativen Weltzustand wie der Welt_Renderer. Liest nur
## Modell, Tiere und Kamera-Stand und reicht sie an die UI-Karte.

const GENERATOR_NAME := "Welt_Generator"

var _model: Welt_Model = null
var _generator: Welt_Generator = null
var _tiere: Tier_Manager = null

func einrichten(model: Welt_Model, generator: Welt_Generator, tiere: Tier_Manager) -> void:
	_model = model
	_generator = generator
	_tiere = tiere

func beobachten(viewer: Ui_KartenViewer, info: Ui_WeltInfo, karten_ebene: CanvasLayer, spieler_position: Vector2, kamera: Camera2D) -> void:
	if viewer != null and karten_ebene != null and karten_ebene.visible and kamera != null:
		var blick := kamera.get_viewport_rect().size / kamera.zoom.x
		viewer.beobachten_setzen(spieler_position, kamera.position, blick)
	if info != null and _model != null and _tiere != null and _generator != null:
		info.zustand_zeigen(_model, _tiere.tier_zahl(), spieler_position, GENERATOR_NAME, _generator.verworfene_chunks)
