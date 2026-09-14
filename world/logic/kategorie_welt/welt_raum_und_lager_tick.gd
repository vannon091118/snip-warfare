extends Node2D
class_name Welt_RaumUndLagerTick
## Einzige Node, die die neuen Welt-Ticks (Raumerkennung, Lagerzonen)
## an die zentrale Weltuhr hängt. Die Logik wohnt in Welt_RaumRegister
## und Welt_LagerzoneRegister; dieser Knoten nur als Uhr-Brücke.
## Keine Bau-, keine Produktions-, keine Einheiten-Rechnung.

var _raum_register := Welt_RaumRegister.new()
var _lager_register := Welt_LagerzoneRegister.new()
var _model: Welt_Model = null
var _lager: Lager_Manager = null

func einrichten(model: Welt_Model, lager: Lager_Manager) -> void:
	_model = model
	_lager = lager
	_raum_register.einrichten(model)
	_lager_register.einrichten(model, lager)
	var bus := get_node_or_null("/root/Weltuhr")
	if bus != null and bus.has_signal("tick") and not bus.tick.is_connected(_auf_tick):
		bus.tick.connect(_auf_tick)

func model_setzen(model: Welt_Model) -> void:
	_model = model
	_raum_register.model_setzen(model)
	_lager_register.model_setzen(model, _lager)

func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager
	_lager_register.lager_setzen(lager)

func lagerzone_register() -> Welt_LagerzoneRegister:
	return _lager_register

func lagerzone_registrieren(welt_position: Vector2) -> Dictionary:
	return _lager_register.lagerzone_registrieren(welt_position)

func hat_lagerzone() -> bool:
	return _lager_register.hat_mindestens_eine_zone()

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	if _model == null:
		return
	_raum_register.tick()

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)
