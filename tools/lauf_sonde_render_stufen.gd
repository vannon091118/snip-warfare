extends SceneTree
## Stufen-Sonde: Baut die Welt schichtweise auf und misst je Stufe den
## Weiß-Anteil des Bildschirms. Die erste Stufe, die weiß macht, trägt die
## Schuld. Kachel-Sprite als Diagnose: trägt es seinen Platzhalter, war die
## Textur-Suche leer; trägt es ein Katalog-Bild, liegt die Ursache im Overlay.

func _initialize() -> void:
	await process_frame
	await process_frame

	# Stufe 1: Nur Kacheln, keine Objekte, kein Overlay.
	var renderer: Node = load("res://world/logic/kategorie_welt/welt_renderer.gd").new()
	root.add_child(renderer)
	var model := Welt_Model.new()
	var registry := Welt_RegistryZugriff.welt()
	model.karte_erzeugen(48, 32, "boden")
	renderer.darstellen(model, registry, null)
	await process_frame
	await process_frame
	var bild := root.get_texture().get_image()
	print("STUFE1 nur_kacheln: weiss=%.2f" % _weiss_anteil(bild))

	# Stufe 2: Kacheln plus Objekte aus dem Modell des echten Generators.
	var generator := Welt_Generator.new()
	generator.welt_planen(model, 424242, "gemaaessigt")
	var lader := Welt_AsyncChunkLader.new()
	lader.kamera_position_setzen(Vector2(model.groesse()) * float(model.kachel_groesse) * 0.5)
	lader.starten(model, generator, "gemaaessigt")
	while lader.laeuft:
		lader.schritt()
		await process_frame
	renderer.darstellen(model, Welt_RegistryZugriff.welt(), null)
	await process_frame
	await process_frame
	bild = root.get_texture().get_image()
	var gesamt := 0
	var mit_textur := 0
	var ebenen_knoten: Node = renderer.get_node_or_null("Fliesen_Z0")
	if ebenen_knoten != null:
		for kind: Node in ebenen_knoten.get_children():
			if kind is Sprite2D:
				gesamt += 1
				if (kind as Sprite2D).texture != null:
					mit_textur += 1
	print("STUFE2 volle_welt: weiss=%.2f kacheln=%d mit_textur=%d" % [_weiss_anteil(bild), gesamt, mit_textur])

	# Diagnose: Was trägt die erste Kachel konkret?
	var erster: Sprite2D = null
	if ebenen_knoten != null and ebenen_knoten.get_child_count() > 0:
		erster = ebenen_knoten.get_child(0) as Sprite2D
	if erster != null and erster.texture != null:
		var textur := erster.texture
		var pix := textur.get_image()
		var mitte := pix.get_pixel(pix.get_width() / 2, pix.get_height() / 2)
		print("STUFE2 kachel_bild: groesse=%dx%d mitte=%s pfad=%s" % [textur.get_width(), textur.get_height(), mitte, textur.resource_path])

	# Stufe 3: Die volle Szene mit allen Schichten obendrauf.
	var szene: Node = load("res://world/scenes/welt.tscn").instantiate()
	root.add_child(szene)
	for i in 200:
		await process_frame
	bild = root.get_texture().get_image()
	print("STUFE3 volle_szene: weiss=%.2f" % _weiss_anteil(bild))
	quit(0)

func _weiss_anteil(bild: Image) -> float:
	var breite := bild.get_width()
	var hoehe := bild.get_height()
	var weiss := 0
	var gesamt := 0
	var schritt := maxi(breite * hoehe / 4000, 1)
	for i in range(0, breite * hoehe, schritt):
		var x := i % breite
		var y := i / breite
		var farbe := bild.get_pixel(x, y)
		gesamt += 1
		if farbe.v > 0.85 and farbe.s < 0.15:
			weiss += 1
	return float(weiss) / float(maxi(gesamt, 1))
