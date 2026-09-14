extends Node
class_name Kern_EngineKoordinator
## Der Registrar: Er besitzt das Brett, nimmt Engines an und treibt den
## Zyklus Lesen, Verarbeiten, Schreiben, Konsolidieren. Er loest die Weltuhr
## zur Laufzeit auf, damit Headless-Laeufe ohne Autoloads funktionieren. Eine
## Engine, die sich hier anmeldet, verliert ihren alten Weltuhr-Connect
## gleichzeitig; es entsteht nie ein Doppel-Tick.

var _brett := Kern_Blackboard.new()
var _engines: Array[Kern_Engine] = []
var _zufall := Kern_Zufall.new()

## Kategorie daten: Das Brett gehoert diesem Registrar, Engines erhalten nur Views.
## Kategorie logik: Anmeldung, Zyklus und Taktteiler-Reihenfolge.

func _enter_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func engine_anmelden(engine: Kern_Engine) -> void:
	# Der Registrier-Vertrag: Keine Engine ohne Eintrag in engine_register.json.
	var register := _register_lesen()
	assert(register.has(engine.engine_id), "Engine ohne Register-Eintrag angemeldet: %s" % engine.engine_id)
	_engines.append(engine)

func _auf_tick(nummer: int, _delta: float) -> void:
	zyklus(nummer)

func zyklus(nummer: int) -> void:
	for engine in _engines:
		if nummer % engine.takt_teiler != 0:
			continue
		_engine_runde(engine, nummer)
	konsolidieren()

func _engine_runde(engine: Kern_Engine, nummer: int) -> void:
	engine.blackboard_lesen(Kern_BlackboardView.new(_brett, engine.engine_id, Kern_BlackboardView.Phase.LESEN))
	engine.verarbeiten(nummer, _zufall)
	engine.blackboard_schreiben(Kern_BlackboardView.new(_brett, engine.engine_id, Kern_BlackboardView.Phase.SCHREIBEN))

func konsolidieren() -> void:
	var konsolidator := Kern_Konsolidator.new()
	konsolidator.durchreichen(_brett)

func _register_lesen() -> Dictionary:
	var pfad := "res://core/data/engine_register.json"
	if not FileAccess.file_exists(pfad):
		return {}
	var text := FileAccess.get_file_as_string(pfad)
	var daten: Variant = JSON.parse_string(text)
	if daten is Dictionary and daten.has("engines"):
		return daten["engines"] as Dictionary
	return {}
