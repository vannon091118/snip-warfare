extends SceneTree
## Uebergang-Sonde: Läuft den echten Szenenwechsel-Kreis des Spiels ab,
## Hauptmenue, Weltkarte, Uebergang, Welt, und zurueck ins Hauptmenue,
## ueber change_scene_to_file wie der Startknopf. Misst die Verwaisten
## nach jedem Bein, damit der Leck-Schritt sichtbar wird.

func _initialize() -> void:
	await process_frame
	await process_frame
	print("SONDE: Start %d Verwaiste" % _verwaiste())
	# Bein 1: Hauptmenue wie beim Spielstart.
	change_scene_to_file("res://ui/scenes/hauptmenue.tscn")
	for rahmen in 10:
		await process_frame
	print("SONDE: nach Hauptmenue %d Verwaiste" % _verwaiste())
	# Bein 2: Weltkarte wie beim Startknopf.
	change_scene_to_file("res://world/scenes/welt_map.tscn")
	for rahmen in 10:
		await process_frame
	print("SONDE: nach Weltkarte %d Verwaiste" % _verwaiste())
	# Bein 3: Welt wie nach der Kartenauswahl.
	var sitzung := root.get_node_or_null("WeltSitzung")
	if sitzung != null:
		sitzung.set("welt_name", "")
		sitzung.set("seed_wunsch", 12345)
		sitzung.set("world", null)
		sitzung.set("aktive_map_id", "")
	change_scene_to_file("res://world/scenes/welt.tscn")
	for rahmen in 40:
		await process_frame
	print("SONDE: nach Welt %d Verwaiste" % _verwaiste())
	# Bein 4: Zurueck ins Hauptmenue wie ueber den Menueknopf im HUD.
	change_scene_to_file("res://ui/scenes/hauptmenue.tscn")
	for rahmen in 10:
		await process_frame
	print("SONDE: nach Rueckkehr ins Menue %d Verwaiste" % _verwaiste())
	# Bein 5: Noch eine Welt, damit Wiederholung das Leck verstaerkt sichtbar macht.
	if sitzung != null:
		sitzung.set("world", null)
		sitzung.set("aktive_map_id", "")
	change_scene_to_file("res://world/scenes/welt.tscn")
	for rahmen in 40:
		await process_frame
	print("SONDE: nach zweiter Welt %d Verwaiste" % _verwaiste())
	change_scene_to_file("res://ui/scenes/hauptmenue.tscn")
	for rahmen in 10:
		await process_frame
	print("SONDE: nach zweiter Rueckkehr %d Verwaiste (Start war 0)" % _verwaiste())
	quit(0)

func _verwaiste() -> int:
	return Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
