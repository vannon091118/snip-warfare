extends RefCounted
class_name Tier_TempoBerechnung
## Tempo eines Tieres: Der Zustand waehlt das Datenfeld, die Tierdaten tragen
## die Zahl, der Modifikatorfaktor skaliert sie. Reine Berechnung ohne Zustand
## und ohne Gedaechtnis.

const FLUCHT_ART := "flucht"
const FLUG_ART := "flug"
const GEH_ART := "gehe"

const FELD_JE_ART := {
	FLUCHT_ART: "flucht_geschwindigkeit",
	FLUG_ART: "flug_geschwindigkeit",
	GEH_ART: "gehe_geschwindigkeit",
}

const STANDARD_JE_ART := {
	FLUCHT_ART: 400.0,
	FLUG_ART: 280.0,
	GEH_ART: 150.0,
}


static func aktuell(verhalten: Tier_Registry, tier_id: String, art: String, faktor: float) -> float:
	## Das Tempo einer Bewegungsart, skaliert mit dem geklemmten Faktor.
	if verhalten == null or not FELD_JE_ART.has(art):
		return 0.0
	var basis := verhalten.wert(tier_id, FELD_JE_ART[art], STANDARD_JE_ART[art])
	if basis == 0.0:
		return 0.0
	return basis * clampf(faktor, 0.1, 10.0)
