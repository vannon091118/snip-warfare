extends RefCounted
class_name Orchestrator_Basis
## Basis aller Orchestrator-Maschinen. Ein Orchestrator ist eine eigene
## Bedarfs-Domäne: Er hält eine Zone mit Bedarfsliste und prüft im Takt
## der globalen Weltuhr, ob Einheiten den Bedarf decken. Logik einer
## anderen Domäne fließt nicht ein; die Bedarfsprüfung meldet nur Bedarf.

## Kategorie daten: Bezeichner der Orchestrator-Maschine.
var orchestrator_id: String = ""

## Kategorie logik: Einlesen und Prüfen der Basis.
func aus_eintrag(eintrag_id: String, _eintrag: Dictionary) -> void:
	orchestrator_id = eintrag_id

func schema_name() -> String:
	return "OrchestratorBasis"
