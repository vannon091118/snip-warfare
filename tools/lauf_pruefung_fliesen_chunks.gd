extends SceneTree
## Lauf-Beweis der Fliesen-Chunks: Ganze Kachel-Gruppen verlassen den Baum,
## wenn der Blick sie verlässt, und kehren zurück, sobald die Kamera sie
## wieder ansieht. Ohne Blick (Editor, Prüfstände) bleibt alles angehängt.

func _initialize() -> void:
	var fehler := 0
	var model := Welt_Model.new()
	model.karte_erzeugen(64, 64, "wiese")
	model.kachel_groesse_setzen(64)
	var registry := Welt_Registry.new()
	var renderer := Welt_Renderer.new()
	root.add_child(renderer)
	if renderer.get_node_or_null("Objekte") == null:
		renderer._ready()
	renderer.darstellen(model, registry)

	# Ohne Blick: Alle Chunk-Container hängen im Baum (Vollsicht).
	var ebene_knoten := renderer.get_node("Fliesen_Z0") as Node2D
	var kinder_ohne_blick := ebene_knoten.get_child_count()
	print("CHUNK-BEWEIS: ohne Blick haengen %d Chunk-Knoten" % kinder_ohne_blick)
	if kinder_ohne_blick == 0:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: kein Chunk gebaut")
		quit(1)
		return

	# Blick oben links: Nur der erste Chunk hängt, der Rest ruht.
	renderer.sichtbereich_setzen(Rect2(0, 0, 100, 100))
	var dran := _angehaengte_zaehlen(ebene_knoten)
	print("CHUNK-BEWEIS: Blick oben links haengen %d von %d" % [dran, kinder_ohne_blick])
	if dran != 1:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: erwartet 1 haengender Chunk, gesehen %d" % dran)
		fehler += 1

	# Blick in die Ferne: Der erste Chunk verlässt den Baum, ein ferner kehrt ein.
	var fern_px := 40.0 * float(model.kachel_groesse)
	renderer.sichtbereich_setzen(Rect2(fern_px, fern_px, 200, 200))
	var dran_fern := _angehaengte_zaehlen(ebene_knoten)
	var erster_drin := ebene_knoten.get_node_or_null("Chunk_0_0") != null
	print("CHUNK-BEWEIS: Blick fern haengen %d, erster Chunk drin=%s" % [dran_fern, str(erster_drin)])
	if erster_drin:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: Chunk_0_0 haengt trotz ferner Kamera noch im Baum")
		fehler += 1
	if dran_fern != 1:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: erwartet 1 haengender Chunk fern, gesehen %d" % dran_fern)
		fehler += 1

	# Einzelkachel-Tausch in einem ruhenden Chunk darf nicht brechen.
	model.fliese_setzen(2, 2, "fels", 0)
	renderer.kachel_ersetzen(2, 2, 0)

	# Rückkehr: Dieselbe Kamera-Ecke stellt den ersten Chunk wieder her.
	renderer.sichtbereich_setzen(Rect2(0, 0, 100, 100))
	var zurueck := ebene_knoten.get_node_or_null("Chunk_0_0") != null
	print("CHUNK-BEWEIS: Rueckkehr Chunk_0_0 drin=%s" % str(zurueck))
	if not zurueck:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: Chunk_0_0 kam nicht zurück")
		fehler += 1

	# Deaktivieren: Vollansicht kehrt für Editor und Prüfstände zurück.
	renderer.sichtbereich_deaktivieren()
	var alle_dran := _angehaengte_zaehlen(ebene_knoten)
	print("CHUNK-BEWEIS: deaktiviert haengen %d von %d" % [alle_dran, kinder_ohne_blick])
	if alle_dran != kinder_ohne_blick:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: Deaktivierung holt nicht alle Chunks zurück")
		fehler += 1

	if fehler > 0:
		print("CHUNK-BEWEIS FEHLGESCHLAGEN: %d Befunde" % fehler)
		quit(1)
		return
	print("CHUNK-BEWEIS OK: Chunks verlassen den Baum und kehren wieder")
	quit(0)

func _angehaengte_zaehlen(ebene: Node2D) -> int:
	var zahl := 0
	for kind in ebene.get_children():
		zahl += 1
	return zahl
