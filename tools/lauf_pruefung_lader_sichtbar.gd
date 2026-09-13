extends SceneTree
## Lauf-Beweis des faulen Sprite-Aufbaus: Der Start-Frame baut keine
## tausend Kachel-Sprites mehr, der zeitgeslicene Lader erzeugt sie je
## Füllung, und faulbau_abschliessen traegt den vollen Endstand. Der
## Beweis verlangt: leere Ebene im Faulbau, Sprites je Füllung, volle
## Ebene nach dem Abschluss, Editor-Vollbau ohne Faulbau unberuehrt.

func _initialize() -> void:
	var fehler := 0
	var model := Welt_Model.new()
	model.kachel_groesse_setzen(64)
	var generator := Welt_Generator.new()
	# Reihenfolge wie im Spiel: Erst der Plan, dann Karte, dann Füllung.
	if not generator.welt_planen(model, 12345, "wiese"):
		print("LADER-BEWEIS FEHLGESCHLAGEN: Plan lief nicht")
		quit(1)
		return
	var registry := Welt_Registry.new()
	var renderer := Welt_Renderer.new()
	root.add_child(renderer)
	if renderer.get_node_or_null("Objekte") == null:
		renderer._ready()
	# Faulbau scharf wie in welt.gd vor der Generierung.
	renderer.sprites_faul_setzen(true)
	renderer.darstellen(model, registry)
	var ebene := renderer.get_node("Fliesen_Z0") as Node2D
	var sprites_im_start_frame := ebene.get_child_count()
	print("LADER-BEWEIS: Start-Frame haengt %d Kachel-Sprites (erwartet 0 im Faulbau)" % sprites_im_start_frame)
	if sprites_im_start_frame != 0:
		print("LADER-BEWEIS FEHLGESCHLAGEN: der Start-Frame baut noch alle Sprites synchron")
		fehler += 1
	# Zeitgeslicene Fuellung mit derselben Verdrahtung wie in welt.gd.
	var lader := Welt_AsyncChunkLader.new()
	lader.kamera_position_setzen(Vector2.ZERO)
	lader.starten(model, generator, "wiese", 0)
	lader.chunk_gefuellt.connect(func(chunk: Vector2i) -> void:
		renderer.kachel_erneuern_fuer_chunk(chunk, 0))
	var schritte := 0
	var sprites_nach_erstem_chunk := -1
	while lader.laeuft and schritte < 200:
		lader.schritt()
		schritte += 1
		if schritte == 1:
			sprites_nach_erstem_chunk = ebene.get_child_count()
			print("LADER-BEWEIS: nach erstem Schritt haengen %d Kachel-Sprites (4 Chunks je 64 Kacheln = 256 erwartet)" % sprites_nach_erstem_chunk)
	print("LADER-BEWEIS: %d Schritte, Modell='%s', Sprites am Ende %d" % [schritte, model.fliese(0, 0, 0), ebene.get_child_count()])
	if model.fliese(0, 0, 0) == "":
		print("LADER-BEWEIS FEHLGESCHLAGEN: Chunk (0,0) wurde gar nicht gefuellt")
		fehler += 1
	if sprites_nach_erstem_chunk <= 0:
		print("LADER-BEWEIS FEHLGESCHLAGEN: die erste Füllung erzeugt keine Sprites")
		fehler += 1
	if ebene.get_child_count() != int(model.raster_breite) * int(model.raster_hoehe):
		print("LADER-BEWEIS FEHLGESCHLAGEN: nach allen Fuellungen fehlen Sprites (%d von %d)" % [ebene.get_child_count(), int(model.raster_breite) * int(model.raster_hoehe)])
		fehler += 1
	# Abschluss wie in welt.gd: faulbau_abschliessen traegt den Endstand
	# (Gewaesser, Fels) und endet den Faulbau; die Zahl der Sprites bleibt.
	var sprites_vor_abschluss := ebene.get_child_count()
	renderer.faulbau_abschliessen()
	if ebene.get_child_count() != sprites_vor_abschluss:
		print("LADER-BEWEIS FEHLGESCHLAGEN: der Abschluss wirft Sprites weg")
		fehler += 1
	# Einzelkachel-Tausch nach dem Abschluss: Der Editor-Pfad bleibt intakt.
	model.fliese_setzen(2, 2, "fels", 0)
	renderer.kachel_ersetzen(2, 2, 0)
	var fels_sprite := ebene.get_node_or_null(NodePath("Kachel_2_2")) as Sprite2D
	if fels_sprite == null:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Einzelkachel-Tausch findet die Kachel nicht")
		fehler += 1
	# Editor-Pfad ohne Faulbau: Ein frischer Renderer baut sofort voll.
	var editor_renderer := Welt_Renderer.new()
	root.add_child(editor_renderer)
	if editor_renderer.get_node_or_null("Objekte") == null:
		editor_renderer._ready()
	editor_renderer.darstellen(model, registry)
	var editor_ebene := editor_renderer.get_node("Fliesen_Z0") as Node2D
	var editor_sprites := editor_ebene.get_child_count()
	print("LADER-BEWEIS: Editor-Vollbau haengt %d Sprites" % editor_sprites)
	if editor_sprites != int(model.raster_breite) * int(model.raster_hoehe):
		print("LADER-BEWEIS FEHLGESCHLAGEN: der Editor-Vollbau ohne Faulbau ist kaputt")
		fehler += 1
	if fehler > 0:
		quit(1)
		return
	print("LADER-BEWEIS OK: fauler Sprite-Aufbau, Fuellungen und Abschluss greifen")
	quit(0)
