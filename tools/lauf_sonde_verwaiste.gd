extends SceneTree
## Verwaisten-Sonde, zweite Stufe: Misst OBJECT_ORPHAN_NODE_COUNT mit
## Rahmen-Wartungen zwischen den Schritten, damit queue_free abarbeiten
## kann, und prueft ob die Engine _ready selbst ruft. Ziel: die Quelle
## der Verwaisten im Live-Spiel finden (520 im Spieler-Monitor).

func _initialize() -> void:
	await process_frame
	await process_frame
	var vor := _verwaiste()
	print("SONDE: Start %d Verwaiste" % vor)
	var model := Welt_Model.new()
	model.kachel_groesse_setzen(64)
	var generator := Welt_Generator.new()
	if not generator.welt_planen(model, 12345, "wiese"):
		print("SONDE: Plan scheiterte")
		quit(1)
		return
	var registry := Welt_Registry.new()
	var renderer := Welt_Renderer.new()
	root.add_child(renderer)
	# Nur EIN _ready-Anstoß: Wenn die Engine ihn nicht selbst gerufen hat,
	# holen wir ihn manuell nach und merken das.
	if renderer.get_node_or_null("Objekte") == null:
		renderer._ready()
	await process_frame
	print("SONDE: Renderer in Baum=%s, Ebenen=%d" % [str(renderer.is_inside_tree()), renderer.get_child_count()])
	print("SONDE: nach Renderer-Aufbau %d (+%d)" % [_verwaiste(), _verwaiste() - vor])
	renderer.sprites_faul_setzen(true)
	renderer.darstellen(model, registry)
	await process_frame
	await process_frame
	print("SONDE: nach darstellen(faul) %d (+%d)" % [_verwaiste(), _verwaiste() - vor])
	var lader := Welt_AsyncChunkLader.new()
	lader.kamera_position_setzen(Vector2.ZERO)
	lader.starten(model, generator, "wiese", 0)
	lader.chunk_gefuellt.connect(func(chunk: Vector2i) -> void:
		renderer.kachel_erneuern_fuer_chunk(chunk, 0))
	var schritte := 0
	while lader.laeuft and schritte < 200:
		lader.schritt()
		schritte += 1
		if schritte % 2 == 0:
			await process_frame
	generator.welt_abschliessen(model, model.welt_seed, model.biom_id)
	renderer.faulbau_abschliessen()
	await process_frame
	await process_frame
	print("SONDE: nach Füllung+Abschluss %d (+%d)" % [_verwaiste(), _verwaiste() - vor])
	# Wo sitzt die Masse? Ebene zaehlen und Rest ableiten.
	var ebene := renderer.get_node_or_null("Fliesen_Z0") as Node2D
	var kacheln := 0
	if ebene != null:
		kacheln = ebene.get_child_count()
	print("SONDE: Kacheln in Ebene %d, Verwaiste gesamt %d, Differenz %d" % [kacheln, _verwaiste(), _verwaiste() - vor - kacheln])
	renderer.queue_free()
	await process_frame
	await process_frame
	print("SONDE: nach Teardown %d (Start war %d)" % [_verwaiste(), vor])
	quit(0)

func _verwaiste() -> int:
	return Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
