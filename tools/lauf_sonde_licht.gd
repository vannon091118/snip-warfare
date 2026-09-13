extends SceneTree
## Licht-Sonde: Die volle Szene wird geladen, der Weiß-Anteil gemessen,
## dann wird das DirectionalLight2D des Papier-Lichts stillgestellt und
## erneut gemessen. Fällt das Weiß damit weg, trägt das Licht die Schuld.

func _initialize() -> void:
	await process_frame
	await process_frame
	var szene: Node = load("res://world/scenes/welt.tscn").instantiate()
	root.add_child(szene)
	for i in 200:
		await process_frame
	print("LICHT: vor_aus weiss=%.2f" % _weiss_anteil(root.get_texture().get_image()))
	# Das Papier-Licht ist Kind der Atmosphaeren-Verdrahtung.
	var atmosphaere: Node = szene.get_node_or_null("Welt_AtmosphaereVerdrahtung")
	if atmosphaere == null:
		for kind: Node in szene.get_children():
			if kind.get_script() != null and str((kind.get_script() as Script).resource_path).contains("atmosphaere"):
				atmosphaere = kind
				break
	var licht: DirectionalLight2D = null
	if atmosphaere != null:
		var papier_licht: Node = atmosphaere.get_node_or_null("PapierLicht")
		if papier_licht != null:
			licht = papier_licht.get_node_or_null("PapierSonne") as DirectionalLight2D
	print("LICHT: gefunden=%s" % str(licht != null))
	if licht != null:
		print("LICHT: energie=%.2f schatten=%s blend=%d" % [licht.energy, str(licht.shadow_enabled), licht.blend_mode])
		licht.energy = 0.0
		await process_frame
		await process_frame
		print("LICHT: nach_aus weiss=%.2f" % _weiss_anteil(root.get_texture().get_image()))
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
