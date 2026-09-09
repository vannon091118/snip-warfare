extends RefCounted
class_name Orchestrator_Verdrahtung
## Spitze: Orchestrator-Zonen verdrahten. Liest nur Orchestrator_Registry
## und schreibt nur in Orchestrator_Manager + Darsteller. Keine Welt-
## oder HUD-Logik. Der Aufrufer fügt die Darsteller als Kinder hinzu.

## Kategorie daten: gehaltene Darsteller als Zustand der Verdrahtung.
var _darsteller: Array[Orchestrator_Darsteller] = []

## Kategorie logik: Registry -> Manager + Szene-Kinder verdrahten.

func verdrahten(registry: Orchestrator_Registry, manager: Orchestrator_Manager, eltern: Node) -> Array[Orchestrator_Darsteller]:
	_darsteller.clear()
	if registry == null or manager == null or eltern == null:
		return _darsteller
	for konfig in registry.zonen:
		konfig.zustand = Orchestrator_Status.Zustand.AKTIV
		var idx := manager.orchestrator_platzieren(konfig)
		var darsteller_knoten := Orchestrator_Darsteller.new()
		darsteller_knoten.einrichten(konfig)
		eltern.add_child(darsteller_knoten)
		_darsteller.append(darsteller_knoten)
		var status := manager.status_fuer(idx)
		if status != null:
			status.zustand_geaendert.connect(darsteller_knoten.status_geaendert)
	return _darsteller

func darsteller() -> Array[Orchestrator_Darsteller]:
	return _darsteller
