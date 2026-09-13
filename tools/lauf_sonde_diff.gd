extends SceneTree
## Differenz-Sonde: Die volle Szene läuft, dann wird jede verdächtige
## Darstellungs-Ebene einzeln stillgestellt und je Schritt der Weiß-Anteil
## gemessen. Die Ebene, deren Abschalten das Weiß tötet, ist der Täter.

func _initialize() -> void:
	await process_frame
	await process_frame
	var szene: Node = load("res://world/scenes/welt.tscn").instantiate()
	root.add_child(szene)
	for i in 200:
		await process_frame
	print("DIFF: start weiss=%.2f" % _weiss(root.get_texture().get_image()))
	# Kandidaten: Alle CanvasLayer und Overlays der Szene, samt Farbebenen.
	var kandidaten: Array[String] = [
		"TageszyklusOverlay", "WaermeOverlay", "PapierKornEbene",
		"SonnenEffekt", "ComicOverlayer", "TiefenNeige", "PapierLicht",
		"KartenEbene", "UILayer", "HUD", "LadeLeiste", "AuswahlRechteck",
		"KontextMenue", "BauPanel", "PopEinheitPanel", "DebugPanel",
	]
	for such_name in kandidaten:
		var knoten := _finde(szene, such_name)
		if knoten == null:
			print("DIFF: %s fehlt (uebersprungen)" % such_name)
			continue
		var war_sichtbar: bool = knoten.visible
		knoten.visible = false
		await process_frame
		await process_frame
		var weiss := _weiss(root.get_texture().get_image())
		knoten.visible = war_sichtbar
		print("DIFF: ohne %s weiss=%.2f" % [such_name, weiss])
	quit(0)

func _finde(wurzel: Node, such_name: String) -> Node:
	if wurzel.name == such_name:
		return wurzel
	for kind: Node in wurzel.get_children():
		var treffer := _finde(kind, such_name)
		if treffer != null:
			return treffer
	return null

func _weiss(bild: Image) -> float:
	var breite := bild.get_width()
	var hoehe := bild.get_height()
	var weiss := 0
	var gesamt := 0
	var schritt := maxi(breite * hoehe / 4000, 1)
	for i in range(0, breite * hoehe, schritt):
		var farbe := bild.get_pixel(i % breite, i / breite)
		gesamt += 1
		if farbe.v > 0.85 and farbe.s < 0.15:
			weiss += 1
	return float(weiss) / float(maxi(gesamt, 1))
