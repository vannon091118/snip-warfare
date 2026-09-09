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
		var darsteller := Orchestrator_Darsteller.new()
		darsteller.einrichten(konfig)
		eltern.add_child(darsteller)
		_darsteller.append(darsteller)
		var status := manager.status_fuer(idx)
		if status != null:
			status.zustand_geaendert.connect(darsteller.status_geaendert)
	return _darsteller

func darsteller() -> Array[Orchestrator_Darsteller]:
	return _darsteller
