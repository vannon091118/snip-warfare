extends RefCounted
class_name Welt_FraktionsProtokoll
## Entscheidungs-Protokoll der Fraktions-KI: Es baut den Log-Eintrag einer
## Entscheidung aus den Schwellenwerten und legt ihn am Welt-Modell ab, damit
## jeder Zug nachvollziehbar bleibt. Reine Rechnung, kein eigener Zustand.

static func erfassen(modell: Welt_Model, fraktion_id: String, aggression: float, bedarf: float,
		bestand: int, expansion: float, handel: float, konflikt: float) -> Dictionary:
	# Die Schwellen entscheiden, was im Protokoll als ausgelöst steht.
	var eintrag := {
		"fraktion_id": fraktion_id,
		"welt_tick": modell.welt_seed,
		"aggression": aggression,
		"ressourcen_bedarf": bedarf,
		"lager_bestand": bestand,
		"expansion_schwelle": expansion,
		"handel_schwelle": handel,
		"konflikt_schwelle": konflikt,
		"expansion_ausgeloest": aggression > expansion,
		"konflikt_ausgeloest": aggression > konflikt,
		"handel_ausgeloest": aggression > handel,
	}
	modell.objekt_feld_setzen(-1, "ki_entscheidungs_log", eintrag)
	return eintrag
