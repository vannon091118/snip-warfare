extends RefCounted
class_name Gebaeude_BauMaschine
## Bau-Zuständigkeitsmaschine. Sie verarbeitet ausschließlich den Bauzustand
## eines Gebäudes: nicht gebaut, Bau angefordert, Bau läuft, fertig.
## Sie rechnet nur über die zentrale Weltzeit (Tick-Aufrufe des Managers),
## besitzt keinen eigenen Timer und führt keine Kosten aus — Kosten prüft
## und entnimmt der koordinierende Manager.

enum Phase { NICHT_GEBAUT, BAU_ANGEFORDERT, BAU_LAEUFT, FERTIG }

## Kategorie daten: Phasen-Namen für die Anzeige.
const PHASEN_NAMEN := {
	Phase.NICHT_GEBAUT: "nicht gebaut",
	Phase.BAU_ANGEFORDERT: "Bau angefordert",
	Phase.BAU_LAEUFT: "Bau läuft",
	Phase.FERTIG: "fertig",
}

## Kategorie logik: Zustandsübergänge über die Weltzeit.

static func neuer_zustand() -> Dictionary:
	return {"phase": Phase.NICHT_GEBAUT, "fortschritt": 0}

func starten(zustand: Dictionary) -> Dictionary:
	# Bau angefordert: Kosten sind bereits geprüft und entnommen.
	var neu := zustand.duplicate(true)
	neu["phase"] = Phase.BAU_ANGEFORDERT
	neu["fortschritt"] = 0
	return neu

func tick(zustand: Dictionary, bauzeit_ticks: int) -> Dictionary:
	var phase := int(zustand.get("phase", Phase.NICHT_GEBAUT))
	var fortschritt := int(zustand.get("fortschritt", 0))
	var neu := zustand.duplicate(true)
	match phase:
		Phase.BAU_ANGEFORDERT:
			neu["phase"] = Phase.BAU_LAEUFT
			neu["fortschritt"] = 1
		Phase.BAU_LAEUFT:
			var neuer_fortschritt := fortschritt + 1
			if bauzeit_ticks > 0 and neuer_fortschritt >= bauzeit_ticks:
				neu["phase"] = Phase.FERTIG
				neu["fortschritt"] = bauzeit_ticks
			else:
				neu["fortschritt"] = neuer_fortschritt
	return neu

func ist_fertig(zustand: Dictionary) -> bool:
	return int(zustand.get("phase", Phase.NICHT_GEBAUT)) == Phase.FERTIG

func fortschritt_anteil(zustand: Dictionary, bauzeit_ticks: int) -> float:
	if bauzeit_ticks <= 0:
		return 1.0
	return clampf(float(int(zustand.get("fortschritt", 0))) / float(bauzeit_ticks), 0.0, 1.0)

func phase_name(zustand: Dictionary) -> String:
	return str(PHASEN_NAMEN.get(int(zustand.get("phase", Phase.NICHT_GEBAUT)), "unbekannt"))