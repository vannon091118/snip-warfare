class_name Orchestrator_Konfiguration
## Kategorie daten: Felder der Orchestrator-Datenklasse
var orchestrator_id: String = ""
var position: Vector2 = Vector2.ZERO
var radius: float = 100.0
var biom_id: String = ""
var bedarfsliste: Array[Dictionary] = []
var zustand: Orchestrator_Status.Zustand = Orchestrator_Status.Zustand.KONFIGURIERT
var farbe: Color = Color.GREEN

## Kategorie logik: Einlesefunktionen
func hat_bedarf(ressource: String) -> bool:
    for eintrag in bedarfsliste:
        if eintrag.get("ressource", "") == ressource:
            return true
    return false

func menge_fuer_bedarf(ressource: String) -> int:
    for eintrag in bedarfsliste:
        if eintrag.get("ressource", "") == ressource:
            return int(eintrag.get("menge", 0))
    return 0

func job_fuer_bedarf(ressource: String) -> String:
    for eintrag in bedarfsliste:
        if eintrag.get("ressource", "") == ressource:
            return eintrag.get("job_id", "")
    return ""

func prioritaet_fuer_bedarf(ressource: String) -> int:
    for eintrag in bedarfsliste:
        if eintrag.get("ressource", "") == ressource:
            return int(eintrag.get("prioritaet", 1))
    return 1