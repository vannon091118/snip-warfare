extends RefCounted
class_name Kern_Engine
## Die Form: Lesen, Verarbeiten, Schreiben. Kein Autoload, kein Singleton,
## keine Weltuhr-Anmeldung. Engines extenden diese Basis direkt; Manager-Nodes
## bleiben stehen und werden von ihren Engines besessen, nicht ersetzt.

var engine_id: String = ""
var takt_teiler: int = 1

func _init(neue_id: String, neuer_teiler: int = 1) -> void:
	engine_id = neue_id
	takt_teiler = neuer_teiler

func blackboard_lesen(_view: Kern_BlackboardView) -> void:
	pass

func verarbeiten(_nummer: int, _zufall: Kern_Zufall) -> void:
	pass

func blackboard_schreiben(_view: Kern_BlackboardView) -> void:
	pass
