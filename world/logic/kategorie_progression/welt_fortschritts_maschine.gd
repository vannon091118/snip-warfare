extends RefCounted
class_name Welt_FortschrittsMaschine
signal stufe_erreicht(stufe: Dictionary)
signal ziel_erreicht(stufe: Dictionary)
signal orchestrator_gespawnt(position: Vector2)

var stufe_index: int = 0
var abgeschlossen: Dictionary = {}
var _model: Welt_Model = null
var _registry: Welt_FortschrittsRegistry = null
var _helfer := Welt_FortschrittHelfer.new()

func _init() -> void:
	abgeschlossen = {}
	_helfer.maschine_setzen(self)

func registry_setzen(registry: Welt_FortschrittsRegistry) -> void:
	_registry = registry

func einheit_manager_setzen(manager: Einheit_Manager) -> void:
	_helfer.einheit_setzen(manager)
	_helfer.bus_verbinden()

func orchestrator_manager_setzen(manager: Orchestrator_Manager) -> void:
	_helfer.orchestrator_setzen(manager)

func rassen_registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_helfer.rassen_setzen(registry)

func model_setzen(model: Welt_Model) -> void:
	_model = model
	_fortschritt_laden()

func aktive_stufe() -> Dictionary:
	if _registry == null:
		return {}
	return _registry.stufe_an(stufe_index)

func ziel_zeile() -> String:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return "Alle Ziele erreicht."
	return "Ziel: %s" % str(stufe.get("beschreibung", ""))

func gebaeude_fertiggestellt(gebaeude_id: String) -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty() or str(stufe.get("ziel_typ", "")) != "gebaeude_bauen":
		return
	if str(stufe.get("gebaeude_id", "")) != gebaeude_id:
		return
	fortschalten()

func einwanderer_angekommen() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty() or str(stufe.get("ziel_typ", "")) != "einwanderung":
		return
	fortschalten()

func fortschalten() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	var sid := str(stufe.get("id", ""))
	abgeschlossen[sid] = true
	ziel_erreicht.emit(stufe)
	if sid == "rathaus_bauen":
		var p := _helfer.spawn_vorarbeiter()
		if p != Vector2.INF:
			orchestrator_gespawnt.emit(p)
	if stufe_index + 1 < _registry.stufen_zahl():
		stufe_index += 1
		stufe_erreicht.emit(aktive_stufe())
	_fortschritt_speichern()

func stufe_frei(gesperrt_ab_stufe: int) -> bool:
	return stufe_index >= gesperrt_ab_stufe

func freigeschaltete_gebaeude() -> Array[String]:
	var frei: Array[String] = []
	if _registry == null:
		return frei
	for i in stufe_index + 1:
		for gid: Variant in (_registry.stufe_an(i).get("schaltet_frei", {}).get("gebaeude", []) as Array):
			frei.append(str(gid))
	return frei

func freigeschaltete_kategorien() -> Array[String]:
	var frei: Array[String] = []
	if _registry == null:
		return frei
	for i in stufe_index + 1:
		for kat: Variant in (_registry.stufe_an(i).get("schaltet_frei", {}).get("kategorien", []) as Array):
			var k := str(kat)
			if not frei.has(k):
				frei.append(k)
	return frei

func _fortschritt_speichern() -> void:
	if _model == null:
		return
	_model.objekt_feld_setzen(0, "fortschritt_stufe", stufe_index)
	_model.objekt_feld_setzen(0, "fortschritt_abgeschlossen", abgeschlossen.duplicate(true))

func _fortschritt_laden() -> void:
	if _model == null:
		return
	var gi: Variant = _model.objekt_feld(0, "fortschritt_stufe", null)
	if typeof(gi) in [TYPE_INT, TYPE_FLOAT]:
		stufe_index = int(gi)
	var ga: Variant = _model.objekt_feld(0, "fortschritt_abgeschlossen", null)
	if typeof(ga) == TYPE_DICTIONARY:
		abgeschlossen = (ga as Dictionary).duplicate(true)
