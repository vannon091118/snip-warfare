extends SceneTree
## Ehrliche Verwaisten-Sonde: Lädt die echte Welt-Szene mit allem Aufbau
## (Overlays, Atmosphäre, Domänen, Tiere, UI), wartet mehrere Rahmen,
## misst OBJECT_ORPHAN_NODE_COUNT und räumt ab. Zeigt, ob der volle
## Szenenlauf Verwaiste hinterlässt, die der reine Renderer-Pfad verbirgt.
## Die Autoloads kommen aus project.godot, weil --script sie sonst nicht
## lädt; root.get_node() ist der Laufzeit-Weg, keine compile-time Konstante.

func _initialize() -> void:
	await process_frame
	await process_frame
	var vor := _verwaiste()
	print("SONDE: Start %d Verwaiste" % vor)
	var sitzung := root.get_node_or_null("WeltSitzung")
	if sitzung == null:
		print("SONDE FEHLGESCHLAGEN: WeltSitzung-Autoload fehlt im Headless-Lauf")
		quit(1)
		return
	# Frische Generierung wie beim Startknopf.
	sitzung.set("welt_name", "")
	sitzung.set("seed_wunsch", 12345)
	sitzung.set("kommt_vom_editor", false)
	sitzung.set("world", null)
	sitzung.set("aktive_map_id", "")
	var szene: Node = (load("res://world/scenes/welt.tscn") as PackedScene).instantiate()
	root.add_child(szene)
	# Ladevorgang und Lader arbeiten frameweise: mehrere Rahmen warten.
	for rahmen in 30:
		await process_frame
	print("SONDE: nach Szene+30 Rahmen %d Verwaiste (+%d)" % [_verwaiste(), _verwaiste() - vor])
	# Teardown wie beim Szenenwechsel ins Hauptmenü.
	szene.queue_free()
	for rahmen in 5:
		await process_frame
	print("SONDE: nach Teardown %d Verwaiste (Start war %d)" % [_verwaiste(), vor])
	quit(0)

func _verwaiste() -> int:
	return Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
