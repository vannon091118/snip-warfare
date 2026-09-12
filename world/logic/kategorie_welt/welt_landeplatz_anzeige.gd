extends Node2D
class_name Welt_LandeplatzAnzeige
## Reine Visualisierung des Landeplatzes und Startbereichs auf der lokalen Karte.
## Zeichnet einen dezenten, gestrichelten Rahmen mit Eckmarkierungen um den
## Startbereich, der sanft pulsiert, um dem Spieler beim Einstieg sofortige
## Orientierung zu geben. Sobald das erste Lagerfeuer errichtet wird, blendet
## sich die Anzeige sanft aus. Diese Klasse besitzt keine Simulationslogik
## und modifiziert keine Spieldaten.

## Kategorie daten: Ausmaße, Farben und kosmetischer Pulszustand.
var _bereich_groesse := Vector2(192.0, 192.0)
var _basis_farbe := Color(0.95, 0.82, 0.35, 0.75)
var _hintergrund_farbe := Color(0.95, 0.82, 0.35, 0.08)
var _puls_zeit: float = 0.0
var _ist_ausgeblendet: bool = false
var _alpha_modulator: float = 1.0

## Kategorie logik: Einrichten, Zeichnen und Ausblenden.

func einrichten(start_pos: Vector2, kachel_groesse: float = 64.0, radius_kacheln: int = 2) -> void:
	# Der Bereich erstreckt sich symmetrisch um die gegebene Startposition.
	position = start_pos
	var seite := float(radius_kacheln * 2 + 1) * kachel_groesse
	_bereich_groesse = Vector2(seite, seite)
	z_index = 0
	queue_redraw()

func ausblenden(dauer: float = 1.0) -> void:
	# Sanftes Verblassen, wenn der Startbereich mit dem Lagerfeuer aktiviert wurde.
	if _ist_ausgeblendet:
		return
	_ist_ausgeblendet = true
	var tween := create_tween()
	if tween != null:
		tween.tween_property(self, "_alpha_modulator", 0.0, dauer)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _process(delta: float) -> void:
	if _ist_ausgeblendet:
		return
	_puls_zeit += delta * 2.2
	queue_redraw()

func _draw() -> void:
	if _ist_ausgeblendet and _alpha_modulator <= 0.0:
		return
	var halb := _bereich_groesse * 0.5
	var rechteck := Rect2(-halb, _bereich_groesse)
	# Dezente Sinus-Atmung fuer den Alpha-Kanal (zwischen 0.45 und 0.85).
	var puls_alpha := (0.65 + 0.2 * sin(_puls_zeit)) * _alpha_modulator
	var rahmen_farbe := Color(_basis_farbe.r, _basis_farbe.g, _basis_farbe.b, puls_alpha)
	var flaechen_farbe := Color(_hintergrund_farbe.r, _hintergrund_farbe.g, _hintergrund_farbe.b, _hintergrund_farbe.a * _alpha_modulator)
	
	# Zarter Hintergrundteppich
	draw_rect(rechteck, flaechen_farbe, true)
	
	# Gestrichelte Kanten um das Startareal
	_zeichne_gestrichelte_kante(Vector2(rechteck.position.x, rechteck.position.y), Vector2(rechteck.end.x, rechteck.position.y), rahmen_farbe)
	_zeichne_gestrichelte_kante(Vector2(rechteck.end.x, rechteck.position.y), Vector2(rechteck.end.x, rechteck.end.y), rahmen_farbe)
	_zeichne_gestrichelte_kante(Vector2(rechteck.end.x, rechteck.end.y), Vector2(rechteck.position.x, rechteck.end.y), rahmen_farbe)
	_zeichne_gestrichelte_kante(Vector2(rechteck.position.x, rechteck.end.y), Vector2(rechteck.position.x, rechteck.position.y), rahmen_farbe)
	
	# Praegnente Eck-Winkel zur taktischen Orientierung
	var eck_laenge := 24.0
	_zeichne_ecke(rechteck.position, Vector2.RIGHT, Vector2.DOWN, eck_laenge, rahmen_farbe)
	_zeichne_ecke(Vector2(rechteck.end.x, rechteck.position.y), Vector2.LEFT, Vector2.DOWN, eck_laenge, rahmen_farbe)
	_zeichne_ecke(rechteck.end, Vector2.LEFT, Vector2.UP, eck_laenge, rahmen_farbe)
	_zeichne_ecke(Vector2(rechteck.position.x, rechteck.end.y), Vector2.RIGHT, Vector2.UP, eck_laenge, rahmen_farbe)
	
	# Zentrales Fadenkreuz / Orientierungsmarkierung
	var kreuz_groesse := 12.0
	draw_line(Vector2(-kreuz_groesse, 0.0), Vector2(kreuz_groesse, 0.0), rahmen_farbe, 1.5)
	draw_line(Vector2(0.0, -kreuz_groesse), Vector2(0.0, kreuz_groesse), rahmen_farbe, 1.5)

func _zeichne_ecke(ursprung: Vector2, richtung_a: Vector2, richtung_b: Vector2, laenge: float, farbe: Color) -> void:
	draw_line(ursprung, ursprung + richtung_a * laenge, farbe, 2.5)
	draw_line(ursprung, ursprung + richtung_b * laenge, farbe, 2.5)

func _zeichne_gestrichelte_kante(von: Vector2, nach: Vector2, farbe: Color, strich_laenge: float = 12.0, luecke: float = 8.0) -> void:
	var richtung := nach - von
	var gesamt_laenge := richtung.length()
	if gesamt_laenge <= 0.0:
		return
	var einheit := richtung.normalized()
	var schritt := strich_laenge + luecke
	var cursor: float = 0.0
	while cursor < gesamt_laenge:
		var ende_cursor := minf(cursor + strich_laenge, gesamt_laenge)
		draw_line(von + einheit * cursor, von + einheit * ende_cursor, farbe, 1.2)
		cursor += schritt
