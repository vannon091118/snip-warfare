extends RefCounted
class_name Gebaeude_ProduktionsMaschine
## Produktions-Zuständigkeitsmaschine. Sie verarbeitet ausschließlich den
## Produktionszustand eines Gebäudes: wartet auf Eingang, Produktion läuft,
## wartet auf Ausgangslager, abgeschlossen, deaktiviert.
## Sie rechnet nur über die zentrale Weltzeit und meldet über die Aktion,
## welche Buchung der Manager als Nächstes ausführen muss (input_ziehen
## beziehungsweise output_legen). Sie berührt selbst keine Bestände.

enum Phase { DEAKTIVIERT, WARTET_EINGANG, LAEUFT, WARTET_AUSGANG, ABGESCHLOSSEN }

## Kategorie daten: Phasen-Namen für die Anzeige.
const PHASEN_NAMEN := {
	Phase.DEAKTIVIERT: "Produktion deaktiviert",
	Phase.WARTET_EINGANG: "wartet auf Eingang",
	Phase.LAEUFT: "Produktion läuft",
	Phase.WARTET_AUSGANG: "wartet auf Ausgangslager",
	Phase.ABGESCHLOSSEN: "Produktion abgeschlossen",
}

## Kategorie logik: Zustandsübergänge über die Weltzeit.

static func neuer_zustand() -> Dictionary:
	return {"phase": Phase.DEAKTIVIERT, "fortschritt": 0}

func starten(zustand: Dictionary) -> Dictionary:
	# Produktion starten: geht in den Wartezustand auf Eingänge.
	var neu := zustand.duplicate(true)
	neu["phase"] = Phase.WARTET_EINGANG
	neu["fortschritt"] = 0
	return neu

func phase_erzwingen(zustand: Dictionary, phase: Phase) -> Dictionary:
	var neu := zustand.duplicate(true)
	neu["phase"] = phase
	return neu

func tick(zustand: Dictionary, definition: Gebaeude_Definition, eingang_ok: bool, lager_ok: bool) -> Dictionary:
	var phase := int(zustand.get("phase", Phase.DEAKTIVIERT))
	var fortschritt := int(zustand.get("fortschritt", 0))
	var neu := zustand.duplicate(true)
	neu["aktion"] = "keine"
	match phase:
		Phase.DEAKTIVIERT:
			pass
		Phase.WARTET_EINGANG:
			if eingang_ok:
				neu["phase"] = Phase.LAEUFT
				neu["fortschritt"] = 0
				neu["aktion"] = "input_ziehen"
		Phase.LAEUFT:
			var neuer_fortschritt := fortschritt + 1
			if definition.dauer_ticks > 0 and neuer_fortschritt >= definition.dauer_ticks:
				neu["fortschritt"] = definition.dauer_ticks
				if lager_ok:
					neu["phase"] = Phase.ABGESCHLOSSEN
					neu["aktion"] = "output_legen"
				else:
					neu["phase"] = Phase.WARTET_AUSGANG
			else:
				neu["fortschritt"] = neuer_fortschritt
		Phase.WARTET_AUSGANG:
			if lager_ok:
				neu["phase"] = Phase.ABGESCHLOSSEN
				neu["aktion"] = "output_legen"
		Phase.ABGESCHLOSSEN:
			if definition.wiederholbar:
				neu["phase"] = Phase.WARTET_EINGANG
				neu["fortschritt"] = 0
	return neu

func fortschritt_anteil(zustand: Dictionary, dauer_ticks: int) -> float:
	if dauer_ticks <= 0:
		return 1.0
	return clampf(float(int(zustand.get("fortschritt", 0))) / float(dauer_ticks), 0.0, 1.0)

func phase_name(zustand: Dictionary) -> String:
	return str(PHASEN_NAMEN.get(int(zustand.get("phase", Phase.DEAKTIVIERT)), "unbekannt"))