extends SceneTree
## Isolations-Beweis: Lädt der Soz_Datenpool allein die Regeln, und wann?

var _zaehler := 0

func _initialize() -> void:
	var pool: Soz_Datenpool = Soz_Datenpool.new()
	var ok := pool.laden("res://population/logic/sozial/data/sozial_regeln.json")
	print("LADEN_OK: ", ok)
	print("TRAITS: ", pool.gruppe("traits").size())
	var manager: Node = load("res://population/logic/sozial/logic/soz_manager.gd").new()
	root.add_child(manager)
	process_frame.connect(_auf_frame)

func _auf_frame() -> void:
	_zaehler += 1
	if _zaehler == 2:
		for kind in root.get_children():
			if kind.name.begins_with("Soz") or kind.get_script() != null and (kind.get_script() as Script).get_instance_base_type() == "Node":
				print("FRAME_GEFUNDEN: ", kind.get_script().resource_path if kind.get_script() != null else "?")
		for kind in root.get_children():
			if kind.get_script() != null and (kind.get_script() as Script).resource_path.contains("soz_manager"):
				print("NACH_FRAME: ", kind.call("test_datenpool_groesse"))
		quit(0)
