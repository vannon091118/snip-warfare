extends RefCounted
class_name Orchestrator_Konfiguration
## Datenklasse einer Orchestrator-Zone. Die Zone trägt Position, Radius,
## Biom und eine Bedarfsliste. Sie ist reine Datenhaltung: Einlesefunktionen
## rechnen nichts und rufen nichts auf.

## Kategorie daten: Felder der Orchestrator-Zone.
var orchestrator_id: String = ""
var position: Vector2 = Vector2.ZERO
var radius: float = 100.0
var biom_id: String = ""
var bedarfsliste: Array[Dictionary] = []
var zustand: Orchestrator_Status.Zustand = Orchestrator_Status.Zustand.KONFIGURIERT
var farbe: Color = Color(0.2, 0.6, 0.2, 1.0)

## Kategorie logik: Einlesefunktionen der Zone.

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	orchestrator_id = eintrag_id
	position = Vector2(
		float(eintrag.get("position_x", 0)),
		float(eintrag.get("position_y", 0))
	)
	radius = float(eintrag.get("radius", 100.0))
	biom_id = str(eintrag.get("biom_id", ""))
	var bedarf: Variant = eintrag.get("bedarfsliste", [])
	bedarfsliste.clear()
	if typeof(bedarf) == TYPE_ARRAY:
		for eintrag_bedarf: Dictionary in bedarf:
			bedarfsliste.append(eintrag_bedarf)
	farbe = Color(
		float(eintrag.get("farbe_r", 0.2)),
		float(eintrag.get("farbe_g", 0.6)),
		float(eintrag.get("farbe_b", 0.2)),
		1.0
	)

func hat_bedarf(ressource: String) -> bool:
	for eintrag in bedarfsliste:
		if str(eintrag.get("ressource", "")) == ressource:
			return true
	return false

func menge_fuer_bedarf(ressource: String) -> int:
	for eintrag in bedarfsliste:
		if str(eintrag.get("ressource", "")) == ressource:
			return int(eintrag.get("menge", 0))
	return 0

func job_fuer_bedarf(ressource: String) -> String:
	for eintrag in bedarfsliste:
		if str(eintrag.get("ressource", "")) == ressource:
			return str(eintrag.get("job_id", ""))
	return ""

func prioritaet_fuer_bedarf(ressource: String) -> int:
	for eintrag in bedarfsliste:
		if str(eintrag.get("ressource", "")) == ressource:
			return int(eintrag.get("prioritaet", 1))
	return 1

func sortierte_bedarfe() -> Array[Dictionary]:
	# Liefert die Bedarfsliste nach Priorität aufsteigend (1 zuerst).
	var liste := bedarfsliste.duplicate(true)
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("prioritaet", 1)) < int(b.get("prioritaet", 1)))
	return liste
