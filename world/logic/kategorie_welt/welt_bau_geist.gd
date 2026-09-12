extends Node2D
class_name Welt_BauGeist
## Visueller Darsteller fuer Bauplaene und Baustellen.
## Zeigt ein halbtransparentes Phantom des kuenftigen Gebaeudes
## sowie einen Material-Anlieferungsbalken darueber.

var _textur: Texture2D = null
var _bedarf_anteil: float = 0.0
var _balken_breite: float = 52.0
var _balken_hoehe: float = 7.0
var _sprite: Sprite2D = null
var _zeit: float = 0.0

func einrichten(textur: Texture2D) -> void:
	_textur = textur
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite)
	if _textur != null:
		_sprite.texture = _textur
	_sprite.modulate = Color(0.35, 0.75, 1.0, 0.6)
	queue_redraw()

func bedarf_aktualisieren(anteil: float) -> void:
	_bedarf_anteil = clampf(anteil, 0.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	_zeit += delta
	if _sprite != null:
		var puls := 0.55 + 0.15 * sin(_zeit * 3.0)
		_sprite.modulate = Color(0.35, 0.75, 1.0, puls)

func _draw() -> void:
	# 1. Blueprint-Eckwinkel an den 4 Kanten
	var kante := 28.0
	var schenkel := 8.0
	var eck_farbe := Color(0.3, 0.8, 1.0, 0.75)
	# Oben-Links
	draw_line(Vector2(-kante, -kante), Vector2(-kante + schenkel, -kante), eck_farbe, 2.0)
	draw_line(Vector2(-kante, -kante), Vector2(-kante, -kante + schenkel), eck_farbe, 2.0)
	# Oben-Rechts
	draw_line(Vector2(kante, -kante), Vector2(kante - schenkel, -kante), eck_farbe, 2.0)
	draw_line(Vector2(kante, -kante), Vector2(kante, -kante + schenkel), eck_farbe, 2.0)
	# Unten-Links
	draw_line(Vector2(-kante, kante), Vector2(-kante + schenkel, kante), eck_farbe, 2.0)
	draw_line(Vector2(-kante, kante), Vector2(-kante, kante - schenkel), eck_farbe, 2.0)
	# Unten-Rechts
	draw_line(Vector2(kante, kante), Vector2(kante - schenkel, kante), eck_farbe, 2.0)
	draw_line(Vector2(kante, kante), Vector2(kante, kante - schenkel), eck_farbe, 2.0)

	# 2. Material-Bedarfsbalken ueber dem Baugeist
	var y_offset := -36.0
	var halbe_breite := _balken_breite / 2.0
	var hintergrund_rect := Rect2(-halbe_breite, y_offset, _balken_breite, _balken_hoehe)
	var rahmen_rect := Rect2(-halbe_breite - 1.5, y_offset - 1.5, _balken_breite + 3.0, _balken_hoehe + 3.0)

	# Rahmen
	draw_rect(rahmen_rect, Color(0.05, 0.1, 0.15, 0.9), false, 1.5)
	# Dunkler Hintergrund
	draw_rect(hintergrund_rect, Color(0.15, 0.2, 0.25, 0.8), true)

	# Fuellung (Leuchtendes Cyan/Tuerkis)
	if _bedarf_anteil > 0.0:
		var fuell_breite := _balken_breite * _bedarf_anteil
		var fuell_rect := Rect2(-halbe_breite, y_offset, fuell_breite, _balken_hoehe)
		draw_rect(fuell_rect, Color(0.2, 0.85, 1.0, 0.95), true)
		# Glanz-Akzentlinie oben
		draw_line(Vector2(-halbe_breite, y_offset + 1.0), Vector2(-halbe_breite + fuell_breite, y_offset + 1.0), Color(0.7, 0.95, 1.0, 0.8), 1.0)
