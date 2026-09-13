extends SceneTree
## Lauf-Beweis nach dem Rueckbau des Chunk-Container-Experiments: Die
## Kacheln hängen direkt am Ebenen-Knoten, der zeitgeslicene Lader füllt
## die Chunks und jede Füllung macht ihre Kacheln sichtbar. Der Beweis
## verlangt: Ebene ohne Zwischen-Knoten, kein Spriteschwund durch den
## Rückbau, und die gefüllte Kachel trägt ihr frisches Bild.

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
	renderer.darstellen(model, registry)
	var ebene := renderer.get_node("Fliesen_Z0") as Node2D
	# Flat: Keine Chunk-Zwischen-Knoten, jede Kachel hängt direkt an der Ebene.
	var sprites_vor_fuellung := ebene.get_child_count()
	print("LADER-BEWEIS: Ebene haengt %d Kachel-Sprites direkt" % sprites_vor_fuellung)
	if sprites_vor_fuellung != int(model.raster_breite) * int(model.raster_hoehe):
		print("LADER-BEWEIS FEHLGESCHLAGEN: Ebene trägt nicht jede Kachel direkt")
		fehler += 1
	var erster_sprite := ebene.get_child(0) as Sprite2D
	var textur_vor_fuellung := erster_sprite.texture
	var lader := Welt_AsyncChunkLader.new()
	lader.kamera_position_setzen(Vector2.ZERO)
	lader.starten(model, generator, "wiese", 0)
	lader.chunk_gefuellt.connect(func(chunk: Vector2i) -> void:
		renderer.kachel_erneuern_fuer_chunk(chunk, 0))
	var schritte := 0
	while lader.laeuft and schritte < 200:
		lader.schritt()
		schritte += 1
	print("LADER-BEWEIS: %d Schritte, offen %d, Modell='%s'" % [schritte, lader.laufende_anzahl(), model.fliese(0, 0, 0)])
	if model.fliese(0, 0, 0) == "":
		print("LADER-BEWEIS FEHLGESCHLAGEN: Chunk (0,0) wurde gar nicht gefuellt")
		fehler += 1
	if model.fliese(0, 0, 0) != "boden" and erster_sprite.texture == textur_vor_fuellung:
		print("LADER-BEWEIS FEHLGESCHLAGEN: gefuellte Kachel behaelt die Plan-Textur (Karte bleibt weiss)")
		fehler += 1
	var sprites_nach_fuellung := ebene.get_child_count()
	if sprites_nach_fuellung != sprites_vor_fuellung:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Spriteschwund %d -> %d" % [sprites_vor_fuellung, sprites_nach_fuellung])
		fehler += 1
	# Einzelkachel-Tausch: Der Editor-Pfad bleibt intakt.
	model.fliese_setzen(2, 2, "fels", 0)
	renderer.kachel_ersetzen(2, 2, 0)
	var fels_sprite := ebene.get_node_or_null(NodePath("Kachel_2_2")) as Sprite2D
	if fels_sprite == null:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Einzelkachel-Tausch findet die Kachel nicht")
		fehler += 1
	if fehler > 0:
		quit(1)
		return
	print("LADER-BEWEIS OK: flat angehaengte Kacheln werden zeitgeslicen sichtbar")
	quit(0)
