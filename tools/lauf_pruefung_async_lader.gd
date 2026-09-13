extends SceneTree
## Lauf-Beweis fuer den zeitgeslicenen Chunk-Lader: Eine Welt wird geplant,
## der Lader arbeitet im Budget, und am Ende steht dieselbe gefuellte Welt
## wie im synchronen Weg. Der Determinismus bleibt gewahrt: dieselbe
## Kachel- und Objekt-Zahl wie beim synchronen Gesamtweg.

func _initialize() -> void:
	var model_sync := Welt_Model.new()
	var model_async := Welt_Model.new()
	var generator_a := Welt_Generator.new()
	var generator_b := Welt_Generator.new()

	# Synchroner Weg als Vergleichswahrheit.
	var ok_sync := generator_a.welt_erzeugen(model_sync, 424242, "gemaaessigt")
	if not ok_sync:
		print("LADER-BEWEIS FEHLGESCHLAGEN: synchroner Weg lieferte false")
		quit(1)
		return

	# Asynchroner Weg: Plan, dann Lader-Schritte bis Abschluss.
	var ok_plan := generator_b.welt_planen(model_async, 424242, "gemaaessigt")
	if not ok_plan:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Plan lieferte false")
		quit(1)
		return
	var lader := Welt_AsyncChunkLader.new()
	lader.starten(model_async, generator_b, "gemaaessigt", 0)
	var schritte := 0
	while lader.laeuft and schritte < 100000:
		lader.schritt()
		schritte += 1
	if lader.laeuft:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Lader nach %d Schritten nicht fertig" % schritte)
		quit(1)
		return

	# Abschluss-Pass: Gewaesser, Fels, Fraktionen wie im Spiel.
	generator_b.welt_abschliessen(model_async, 424242, "gemaaessigt", 0)

	# Vergleich: Kachel-Zahl, Objekt-Zahl und Kachel-Stichproben.
	var kacheln_sync := 0
	var kacheln_async := 0
	for y in model_sync.raster_hoehe:
		for x in model_sync.raster_breite:
			if model_sync.fliese(x, y, 0) != "":
				kacheln_sync += 1
			if model_async.fliese(x, y, 0) != "":
				kacheln_async += 1
	var objekte_sync := model_sync.objekt_anzahl()
	var objekte_async := model_async.objekt_anzahl()
	print("LADER-BEWEIS: schritte=%d kacheln_sync=%d kacheln_async=%d objekte_sync=%d objekte_async=%d" % [schritte, kacheln_sync, kacheln_async, objekte_sync, objekte_async])
	if kacheln_sync == 0 or kacheln_sync != kacheln_async:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Kachel-Zahlen weichen ab")
		quit(1)
		return
	if objekte_sync != objekte_async:
		print("LADER-BEWEIS FEHLGESCHLAGEN: Objekt-Zahlen weichen ab")
		quit(1)
		return
	var stichproben_ok := true
	for probe in 200:
		var x := probe * 7 % model_sync.raster_breite
		var y := probe * 13 % model_sync.raster_hoehe
		if model_sync.fliese(x, y, 0) != model_async.fliese(x, y, 0):
			stichproben_ok = false
			print("LADER-BEWEIS FEHLGESCHLAGEN: Kachel %d,%d weicht ab (%s != %s)" % [x, y, model_sync.fliese(x, y, 0), model_async.fliese(x, y, 0)])
			break
	if not stichproben_ok:
		quit(1)
		return
	print("LADER-BEWEIS OK: asynchroner und synchroner Weg liefern dieselbe Welt")
	quit(0)
