extends RefCounted
class_name Welt_TagesZyklusFaerbung
## Darstellung des Tageszyklus: Schablonen-Deckkraft, Grundfaerbung und die
## weiche Farbkurve je Phase. Reine Darstellung ohne Zustand; sie liest Phase
## und Taktfortschritt und liefert Farbe oder Deckkraft zurueck.

const TAG := "tag"
const DAEMMERUNG := "daemmerung"
const NACHT := "nacht"
const MORGEN := "morgen"

const MORGEN_FARBE := Color(1.0, 0.96, 0.88, 1.0)
const MITTAG_FARBE := Color(1.0, 1.0, 0.9, 1.0)
const ABEND_FARBE := Color(1.0, 0.65, 0.42, 1.0)
const NACHT_FARBE := Color(0.52, 0.58, 0.78, 1.0)


static func schablonen_alpha(phase: String) -> float:
	## Wie stark die Nachtschablone ueber der Karte liegt.
	match phase:
		DAEMMERUNG:
			return 0.35
		NACHT:
			return 0.65
		MORGEN:
			return 0.25
	return 0.0


static func faerbung(phase: String) -> Color:
	## Die Grundfarbe einer Phase fuer einfache Bildschirmtönung.
	if phase == NACHT:
		return Color(0.72, 0.78, 1.0, 1.0)
	if phase == DAEMMERUNG:
		return Color(0.95, 0.82, 0.78, 1.0)
	if phase == MORGEN:
		return Color(1.0, 0.96, 0.88, 1.0)
	return Color(1, 1, 1, 1)


static func tages_farbe(phase: String, fortschritt: float) -> Color:
	## Die weiche Farbe innerhalb einer Phase, von Anfang zu Ende gemischt.
	match phase:
		MORGEN:
			return MORGEN_FARBE.lerp(MITTAG_FARBE, fortschritt)
		TAG:
			return MITTAG_FARBE.lerp(ABEND_FARBE, fortschritt)
		NACHT:
			return ABEND_FARBE.lerp(NACHT_FARBE, fortschritt)
		DAEMMERUNG:
			return NACHT_FARBE.lerp(MORGEN_FARBE, fortschritt)
	return MORGEN_FARBE
