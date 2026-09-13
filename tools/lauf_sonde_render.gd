extends SceneTree
## Render-Sonde mit echtem Fenster: Lädt die Welt-Szene mit echter GPU,
## wartet die Ladekette ab und liest den Bildschirm aus. Färbt der Bildschirm
## fast weiß trotz voller Kacheln im Baum, trägt ein Overlay oder Shader die
## Schuld; bleiben die Kacheln aus, ist es die Logik.

func _initialize() -> void:
	await process_frame
	await process_frame
	var szene: Node = load("res://world/scenes/welt.tscn").instantiate()
	root.add_child(szene)
	for i in 200:
		await process_frame
	var karte: Node = szene.get_node_or_null("%Karte")
	var gesamt := 0
	var mit_textur := 0
	if karte != null:
		var ebenen_knoten: Node = karte.get_node_or_null("Fliesen_Z0")
		if ebenen_knoten != null:
			for kind: Node in ebenen_knoten.get_children():
				if kind is Sprite2D:
					gesamt += 1
					if (kind as Sprite2D).texture != null:
						mit_textur += 1
	var bild := root.get_texture().get_image()
	var breite := bild.get_width()
	var hoehe := bild.get_height()
	var weiss := 0
	var gesamt_pixel := 0
	var schritt := maxi(breite * hoehe / 4000, 1)
	for i in range(0, breite * hoehe, schritt):
		var x := i % breite
		var y := i / breite
		var farbe := bild.get_pixel(x, y)
		gesamt_pixel += 1
		if farbe.v > 0.85 and farbe.s < 0.15:
			weiss += 1
	var anteil := float(weiss) / float(maxi(gesamt_pixel, 1))
	print("SONDE: kacheln=%d mit_textur=%d weiss_anteil=%.2f aufloesung=%dx%d" % [gesamt, mit_textur, anteil, breite, hoehe])
	if gesamt == 0:
		printerr("SONDE-FEHLER: Keine Kacheln im Baum")
		quit(1)
	elif anteil > 0.8:
		printerr("SONDE-FEHLER: Bildschirm fast komplett weiß (%.0f %%), obwohl %d Kacheln existieren" % [anteil * 100.0, gesamt])
		quit(1)
	else:
		print("SONDE: OK - Karte sichtbar")
		quit(0)
