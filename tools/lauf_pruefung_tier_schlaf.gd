extends SceneTree
## Lauf-Beweis für das Tier-Schlafen: Ohne Blick tragen alle Tiere sofort
## Darsteller (Editor-/Prüfpfad). Mit Blick tragen nur Tiere im Rechteck
## einen Knoten; wandert der Blick weg, schläft das Tier ein (Eintrag lebt
## als Logik ohne Node weiter), kehrt der Blick zurück, wacht es wieder auf.
## Das Deaktivieren weckt alles, wie es der Editor- und Prüfpfad verlangt.

const TierManagerSkript := preload("res://world/logic/kategorie_tier/tier_manager.gd")

func _initialize() -> void:
	await process_frame
	var manager: Tier_Manager = TierManagerSkript.new()
	root.add_child(manager)
	manager.modell_setzen(Welt_Model.new())

	# Ohne Blick: Editor-Pfad, jede Platzierung wächst sofort einen Darsteller.
	var id_a := manager.tier_platzieren("hase", Vector2(100, 100))
	var id_b := manager.tier_platzieren("baer", Vector2(9000, 9000))
	var knoten_ohne_blick := _darsteller_zahl(manager)
	print("BEWEIS: ohne Blick 2 Tiere, %d Darsteller (erwartet 2)" % knoten_ohne_blick)

	# Mit Blick: Nur das Tier im Rechteck bekommt einen Knoten.
	manager.sichtbereich_setzen(Rect2(0, 0, 2000, 2000))
	var id_c := manager.tier_platzieren("hase", Vector2(300, 300))
	var id_d := manager.tier_platzieren("hase", Vector2(8000, 8000))
	var knoten_mit_blick := _darsteller_zahl(manager)
	print("BEWEIS: mit Blick 4 Tiere, %d Darsteller (erwartet 3)" % knoten_mit_blick)

	# Einschlafen: Der Blick wandert zu (6000..8000); die Wiese bei (0..2000)
	# liegt außerhalb, der Bär ebenfalls. Alle wachen Darsteller schlafen ein,
	# der schlafende Hase bei (8000,8000) bleibt ohne Knoten (Rand ausgeschlossen).
	manager.sichtbereich_setzen(Rect2(6000, 6000, 2000, 2000))
	manager._auf_tick(1, 1.0 / 24.0)
	await process_frame
	await process_frame
	var knoten_nach_schlaf := _darsteller_zahl(manager)
	var alle_eintraege_leben := id_a >= 0 and id_b >= 0 and id_c >= 0 and id_d >= 0 \
		and manager.tier_position(id_a) != Vector2.INF \
		and manager.tier_position(id_b) != Vector2.INF \
		and manager.tier_position(id_c) != Vector2.INF \
		and manager.tier_position(id_d) != Vector2.INF
	print("BEWEIS: nach Schlaf %d Darsteller (erwartet 0), alle 4 Einträge leben: %s" % [knoten_nach_schlaf, alle_eintraege_leben])

	# Aufwachen: Blick zurück auf die Hasen-Wiese, der Tick weckt budgetiert.
	manager.sichtbereich_setzen(Rect2(0, 0, 2000, 2000))
	manager._auf_tick(2, 1.0 / 24.0)
	await process_frame
	var knoten_nach_aufwachen := _darsteller_zahl(manager)
	print("BEWEIS: nach Aufwachen %d Darsteller (erwartet 2: Hasen ja, Bär schläft)" % knoten_nach_aufwachen)

	# Deaktivieren: Editor-Rückweg, alles erwacht sofort.
	manager.sichtbereich_deaktivieren()
	var knoten_voll := _darsteller_zahl(manager)
	print("BEWEIS: nach Deaktivieren %d Darsteller (erwartet 4)" % knoten_voll)

	var ok := knoten_ohne_blick == 2 and knoten_mit_blick == 3 and knoten_nach_schlaf == 0 \
		and alle_eintraege_leben and knoten_nach_aufwachen == 2 and knoten_voll == 4
	print("BEWEIS OK" if ok else "BEWEIS FEHLGESCHLAGEN")
	# Sauberer Abschied: Der Baum wird sofort freigegeben, damit der Lauf
	# keine Leichen in die Abschlussbilanz wirft.
	root.remove_child(manager)
	manager.free()
	quit(0 if ok else 1)

func _darsteller_zahl(manager: Tier_Manager) -> int:
	var ebene := manager.get_node_or_null("TierDarstellerEbene")
	return 0 if ebene == null else ebene.get_child_count()
