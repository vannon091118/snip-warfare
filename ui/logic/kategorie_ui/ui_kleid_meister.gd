extends RefCounted
class_name Ui_KleidMeister
## Der Schneider der geteilten UI-Tracht: Er baut die StyleBox-Lagen, die
## Fensterleiste, Onboarding-Leitplanke und Hauptmenü gemeinsam tragen.
## Dunkles Panel, abgerundete Ecken, heller Rand, ein warmer Akzent für den
## gehobenen Zustand. Kein Knoten, kein Zustand: reine Fabrik für StyleBoxen
## und das Ankleiden ganzer Knopfreihen. Wer das Kleid hier ändert, ändert
## es überall auf einmal.

const PANEL_FARBE := Color(0.06, 0.08, 0.1, 0.82)
const RAND_FARBE := Color(1, 1, 1, 0.18)
const AKZENT_FARBE := Color(1.0, 0.87, 0.55)
const TEXT_GEDAEFFTIGT := Color(0.78, 0.78, 0.78)

## Kategorie logik: StyleBoxen bauen und Knöpfe ankleiden.

static func panel_stil(rundung: int = 10, randstaerke: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_FARBE
	box.border_width_left = randstaerke
	box.border_width_top = randstaerke
	box.border_width_right = randstaerke
	box.border_width_bottom = randstaerke
	box.border_color = RAND_FARBE
	box.corner_radius_top_left = rundung
	box.corner_radius_top_right = rundung
	box.corner_radius_bottom_right = rundung
	box.corner_radius_bottom_left = rundung
	box.content_margin_left = 14.0
	box.content_margin_top = 6.0
	box.content_margin_right = 14.0
	box.content_margin_bottom = 6.0
	return box

static func knopf_stil(gehoben: bool = false) -> StyleBoxFlat:
	var box := panel_stil(8, 1)
	box.bg_color = Color(0.1, 0.13, 0.17, 0.9)
	if gehoben:
		box.bg_color = Color(0.16, 0.2, 0.26, 0.95)
		box.border_color = AKZENT_FARBE
		box.border_width_left = 2
		box.border_width_top = 2
		box.border_width_right = 2
		box.border_width_bottom = 2
	return box

static func knopf_ankleiden(knopf: Button, gehoben: bool = false) -> void:
	## Die eine Tracht für alle Knöpfe: normal, gehoben und der Zustand
	## darunter bleiben aus einer Hand, damit nichts auseinanderläuft.
	if knopf == null:
		return
	knopf.add_theme_stylebox_override("normal", knopf_stil(false))
	knopf.add_theme_stylebox_override("hover", knopf_stil(true))
	knopf.add_theme_stylebox_override("pressed", knopf_stil(true))
	knopf.add_theme_stylebox_override("focus", knopf_stil(gehoben))
	if gehoben:
		knopf.add_theme_color_override("font_color", AKZENT_FARBE)
		knopf.add_theme_color_override("font_hover_color", AKZENT_FARBE)
	else:
		knopf.add_theme_color_override("font_color", Color.WHITE)
		knopf.add_theme_color_override("font_hover_color", AKZENT_FARBE)
	knopf.add_theme_color_override("font_pressed_color", AKZENT_FARBE)
	knopf.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func reihe_ankleiden(knoepfe: Array) -> void:
	for eintrag: Variant in knoepfe:
		if eintrag is Button:
			knopf_ankleiden(eintrag as Button)
