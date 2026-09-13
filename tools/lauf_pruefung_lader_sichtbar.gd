extends SceneTree
## Lauf-Beweis fuer die White-World-Reparatur in derselben Reihenfolge wie
## im Spiel: welt_planen laesst das Raster leer bzw. auf "boden", die Karte
## baut ihre Sprites daraus, der zeitgeslicene Lader fuellt Chunks NACH-
## traeglich. Ohne Repaint je Chunk bleibt die Karte weiss (Spieler-Foto).
## Der Beweis verlangt: Nach der Fuellung traegt die Kachel die Textur des
## gefuellten Elements, und der Chunk haengt sichtbar im Baum.

func _initialize() -> void:
	var fehler := 0
	var model := Welt_Model.new()
	model.kachel_groesse_setzen(64)
	var generator := Welt_Generator.new()
	# Reihenfolge wie im Spiel: Erst der Plan ("boden"-Raster), dann Karte.
	if not generator.welt_planen(model, 12345, "wiese"):
		print("LADER-BEWEIS FEHLGESCHLAGEN: Plan lief nicht")
		quit(1)
		return
	var registry := Welt_Registry.new()
	var renderer := Welt_Renderer.new()
	root.add_child(renderer)
	if renderer.get_node_or_null("Objekte") == null:
		renderer._ready()
	renderer.darstellen(model, registry)
	var ebene := renderer.get_node("Fliesen_Z0") as Node2D
	var erster_sprite := (ebene.get_child(0) as Node2D).get_child(0) as Sprite2D
	var textur_vor_fuellung := erster_sprite.texture
	print("LADER-BEWEIS: vor Fuellung Modell='%s' Sprite-Textur=%s" % [model.fliese(0, 0, 0), textur_vor_fuellung])
	# Zeitgeslicene Fuellung mit derselben Verdrahtung wie in welt.gd.
	var lader := Welt_AsyncChunkLader.new()
	lader.kamera_position_setzen(Vector2.ZERO)
	lader.starten(model, generator, "wiese", 0)
	lader.chunk_gefuellt.connect(func(chunk: Vector2i) -> void:
		renderer.chunk_erneuern(chunk, 0))
	var schritte := 0
	while lader.laeuft and schritte < 200:
		lader.schritt()
		schritte += 1
	print("LADER-BEWEIS: %d Schritte, offen %d, Modell='%s'" % [schritte, lader.laufende_anzahl(), model.fliese(0, 0, 0)])
	# Die gefuellte Kachel muss ihr frisches Bild tragen, nicht den Boden.
	if model.fliese(0, 0, 0) == "":
		print("LADER-BEWEIS FEHLGESCHLAGEN: Chunk (0,0) wurde gar nicht gefuellt")
		fehler += 1
	if erster_sprite.texture == textur_vor_fuellung and model.fliese(0, 0, 0) != "boden":
		print("LADER-BEWEIS FEHLGESCHLAGEN: gefuellte Kachel behaelt die Plan-Textur (Karte bleibt weiss)")
		fehler += 1
	if ebene.get_child_count() == 0:
		print("LADER-BEWEIS FEHLGESCHLAGEN: kein Chunk im Baum")
		fehler += 1
	# Rueckkehr-Garantie: chunk_erneuern haengt einen ruhenden Chunk wieder ein.
	var fern_px := 40.0 * float(model.kachel_groesse)
	renderer.sichtbereich_setzen(Rect2(fern_px, fern_px, 200, 200))
	var chunk00 := ebene.get_node_or_null("Chunk_0_0")
	var war_draussen := chunk00 == null
	renderer.chunk_erneuern(Vector2i(0, 0), 0)
	var ist_wieder_drin := ebene.get_node_or_null("Chunk_0_0") != null
	print("LADER-BEWEIS: ruhender Chunk war draussen=%s, nach chunk_erneuern drin=%s" % [str(war_draussen), str(ist_wieder_drin)])
	if not ist_wieder_drin:
		print("LADER-BEWEIS FEHLGESCHLAGEN: chunk_erneuern holt den Chunk nicht zurueck")
		fehler += 1
	if fehler > 0:
		quit(1)
		return
	print("LADER-BEWEIS OK: zeitgeslicene Fuellung wird sichtbar nachgezogen")
	quit(0)
