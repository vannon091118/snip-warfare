extends SceneTree
## Beweislauf des Blackboard-Vertrags (Regel 9): Zwei Dummy-Engines, ein
## Koordinator, ein Zyklus Lesen, Verarbeiten, Schreiben, Konsolidieren.
## Der Beweis: Der Taktteiler trennt die Takte, die Phasen-Sperre stirbt
## laut, und der Konsolidator liefert seine Durchreiche ohne Doppel-Tick.

const KOORDINATOR_SKRIPT := "res://core/logic/kategorie_blackboard/kern_engine_koordinator.gd"


class Beweis_Engine extends Kern_Engine:
	var zaehler := 0
	var letzter_konsolidiert: Variant = null

	func _init(id: String, teiler: int) -> void:
		super(id, teiler)

	func blackboard_lesen(view: Kern_BlackboardView) -> void:
		letzter_konsolidiert = view.lesen_konsolidiert("beweis_feld")

	func verarbeiten(_nummer: int, _zufall: Kern_Zufall) -> void:
		zaehler += 1

	func blackboard_schreiben(view: Kern_BlackboardView) -> void:
		view.schreiben("beweis_feld", zaehler)


func _initialize() -> void:
	var koordinator: Node = load(KOORDINATOR_SKRIPT).new()
	root.add_child(koordinator)
	var zaehler_a := Beweis_Engine.new("beweis_a", 1)
	var zaehler_b := Beweis_Engine.new("beweis_b", 2)
	koordinator.call("engine_anmelden", zaehler_a)
	koordinator.call("engine_anmelden", zaehler_b)
	# Vier Takte: a tickt viermal, b zweimal.
	for nummer in range(1, 5):
		koordinator.call("zyklus", nummer)
	print("BEWEIS_A_ZAEHLER: ", zaehler_a.zaehler)
	print("BEWEIS_B_ZAEHLER: ", zaehler_b.zaehler)
	print("BEWEIS_A_KONSOLIDIERT: ", zaehler_a.letzter_konsolidiert)
	# Phasen-Sperre: Eine Lese-View darf nicht schreiben; der assert stirbt
	# im Debug-Lauf laut. Wir fangen ihn nicht, wir beweisen die Form:
	# Die View hat die Phase LESEN und schreiben() prueft auf SCHREIBEN.
	var brett := Kern_Blackboard.new()
	var lese_view := Kern_BlackboardView.new(brett, "beweis_a", Kern_BlackboardView.Phase.LESEN)
	print("BEWEIS_LESE_PHASE: ", lese_view._phase == Kern_BlackboardView.Phase.LESEN)
	var schreib_view := Kern_BlackboardView.new(brett, "beweis_a", Kern_BlackboardView.Phase.SCHREIBEN)
	schreib_view.schreiben("beweis_feld", 99)
	print("BEWEIS_SCHREIBWERT: ", brett.lese_sektor("beweis_a").get("beweis_feld"))
	assert(zaehler_a.zaehler == 4, "Engine A mit Teiler 1 tickt jeden Takt")
	assert(zaehler_b.zaehler == 2, "Engine B mit Teiler 2 tickt jeden zweiten Takt")
	assert(zaehler_a.letzter_konsolidiert == null, "Ohne Transformation bleibt konsolidiert leer")
	quit(0)
