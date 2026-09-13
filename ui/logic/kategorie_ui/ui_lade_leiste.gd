extends Control
class_name Ui_LadeLeiste
## Schmale Ladeleiste im HUD: Zeigt den Fortschritt des zeitgeslicenen
## Chunk-Laders, bis die Welt voll materialisiert ist. Genau eine
## Verantwortung: Anteil lesen, Balken füllen, bei Fertigstellung
## verschwinden. Kein Lader-Wissen, keine Zeitquelle, keine Domänenlogik;
## die Szene reicht den Anteil herein und blendet den Rest selbst aus.

## Kategorie daten: Balken und Beschriftung als eigener Zustand.

var _hintergrund: ColorRect = null
var _fuellung: ColorRect = null
var _text: Label = null
## Letzter bekannter Anteil: Der Ausblend-Tween liest ihn, bevor er leert.
var _anteil: float = 0.0

## Kategorie logik: Aufbau und Sichtbarkeit.

func _ready() -> void:
	# Schmale Leiste unten mittig: Sichtbar über der Karte, ohne das HUD
	# zu verdecken. Anchors halten sie auch bei Fenstergrößenwechsel fest.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	custom_minimum_size = Vector2(280.0, 26.0)
	position = Vector2(-140.0, -56.0)
	_hintergrund = ColorRect.new()
	_hintergrund.color = Color(0.08, 0.07, 0.06, 0.85)
	_hintergrund.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hintergrund.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hintergrund)
	_fuellung = ColorRect.new()
	_fuellung.color = Color(0.85, 0.68, 0.25, 1.0)
	_fuellung.position = Vector2(2.0, 2.0)
	_fuellung.size = Vector2(0.0, 22.0)
	_fuellung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hintergrund.add_child(_fuellung)
	_text = Label.new()
	_text.text = "Die Welt wird entfaltet …"
	_text.position = Vector2(6.0, 2.0)
	_text.add_theme_font_size_override("font_size", 12)
	_text.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_hintergrund.add_child(_text)
	visible = false

func anteil_setzen(anteil: float) -> void:
	## Die Szene reicht den Lader-Fortschritt herein; der Balken füllt sich
	## und zeigt sich, solange etwas offen bleibt.
	_anteil = clampf(anteil, 0.0, 1.0)
	if _fuellung == null or _hintergrund == null:
		return
	var breite := maxf(_hintergrund.size.x - 4.0, 0.0)
	_fuellung.size = Vector2(breite * _anteil, 22.0)
	visible = _anteil < 1.0
	if visible:
		_text.text = "Die Welt wird entfaltet … %d%%" % int(round(_anteil * 100.0))

func fertig_anzeigen() -> void:
	## Fertigstellung: Der Balken füllt sich ganz und blendet sich weich aus,
	## statt mitten im Bild zu verschwinden.
	if _fuellung == null:
		return
	var breite := maxf(_hintergrund.size.x - 4.0, 0.0)
	_fuellung.size = Vector2(breite, 22.0)
	_text.text = "Die Welt steht."
	var ausblend := create_tween()
	ausblend.tween_interval(0.6)
	ausblend.tween_property(self, "modulate:a", 0.0, 0.5)
	ausblend.tween_callback(func() -> void: visible = false)
