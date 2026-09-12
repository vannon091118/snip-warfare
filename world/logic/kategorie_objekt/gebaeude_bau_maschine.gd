extends RefCounted
class_name Gebaeude_BauMaschine
## Bau-Zuständigkeitsmaschine. Sie verarbeitet ausschließlich den Bauzustand
## eines Gebäudes: nicht gebaut, Bau angefordert, Bau läuft, fertig.
## Sie rechnet nur über die zentrale Weltzeit (Tick-Aufrufe des Managers),
## besitzt keinen eigenen Timer und führt keine Kosten aus — Kosten prüft
## und entnimmt der koordinierende Manager.

enum Phase { NICHT_GEBAUT, BAUPLAN, BAU_ANGEFORDERT, BAU_LAEUFT, FERTIG }

## Kategorie daten: Phasen-Namen für die Anzeige.
const PHASEN_NAMEN := {
	Phase.NICHT_GEBAUT: "nicht gebaut",
	Phase.BAUPLAN: "Bauplan",
	Phase.BAU_ANGEFORDERT: "Bau angefordert",
	Phase.BAU_LAEUFT: "Bau läuft",
	Phase.FERTIG: "fertig",
}

## Kategorie daten: eigene Modifikator-Maschine mit Bereich Bau aus den
## globalen Settings; die Basis-Bauzeit kommt weiterhin aus der Definition.
var _modifikatoren := Kern_ModifikatorMaschine.new()

## Kategorie logik: Zustandsübergänge über die Weltzeit.

func _init() -> void:
	_modifikatoren.bereich_setzen("bau")
	_modifikatoren.aktualisieren()

static func neuer_zustand() -> Dictionary:
	return {"phase": Phase.NICHT_GEBAUT, "fortschritt": 0}

func bauplan_anlegen(zustand: Dictionary) -> Dictionary:
	# Bauplan platziert: Materialbedarf ist vermerkt, aber noch nicht geliefert.
	var neu := zustand.duplicate(true)
	neu["phase"] = Phase.BAUPLAN
	neu["fortschritt"] = 0
	return neu

func starten(zustand: Dictionary) -> Dictionary:
	# Bau angefordert: Material ist vollständig geliefert oder bestätigt.
	var neu := zustand.duplicate(true)
	neu["phase"] = Phase.BAU_ANGEFORDERT
	neu["fortschritt"] = 0
	return neu

func tick(zustand: Dictionary, bauzeit_ticks: int, material_vollstaendig: bool = true) -> Dictionary:
	# Die effektive Bauzeit kommt aus der eigenen Modifikator-Maschine;
	# der Zustand merkt sich die geltende Zeit für die Menü-Abstimmung.
	var phase := int(zustand.get("phase", Phase.NICHT_GEBAUT))
	var fortschritt := int(zustand.get("fortschritt", 0))
	var effektive_zeit := _modifikatoren.zeit_berechnen(bauzeit_ticks)
	var neu := zustand.duplicate(true)
	neu["ziel_ticks"] = effektive_zeit
	match phase:
		Phase.BAUPLAN:
			if material_vollstaendig:
				neu["phase"] = Phase.BAU_ANGEFORDERT
				neu["fortschritt"] = 0
		Phase.BAU_ANGEFORDERT:
			neu["phase"] = Phase.BAU_LAEUFT
			neu["fortschritt"] = 1
		Phase.BAU_LAEUFT:
			var neuer_fortschritt := fortschritt + 1
			if effektive_zeit > 0 and neuer_fortschritt >= effektive_zeit:
				neu["phase"] = Phase.FERTIG
				neu["fortschritt"] = effektive_zeit
			else:
				neu["fortschritt"] = neuer_fortschritt
	return neu

func zeit_ticks_fuer(bauzeit_ticks: int) -> int:
	# Öffentlicher Zugriff auf die effektive Bauzeit der eigenen Maschine.
	return _modifikatoren.zeit_berechnen(bauzeit_ticks)

func abstimmen(zustand: Dictionary, bauzeit_ticks: int) -> Dictionary:
	# Menü-Gegenprüfung: Der Fortschritt wird prozentual auf die neue
	# effektive Zeit skaliert, damit Anzeige und Fertigstellung präzise sind.
	var neu := zustand.duplicate(true)
	if int(neu.get("phase", Phase.NICHT_GEBAUT)) != Phase.BAU_LAEUFT:
		return neu
	var alte_zeit := maxi(int(neu.get("ziel_ticks", bauzeit_ticks)), 1)
	var anteil := clampf(float(int(neu.get("fortschritt", 0))) / float(alte_zeit), 0.0, 1.0)
	var neue_zeit := _modifikatoren.zeit_berechnen(bauzeit_ticks)
	neu["fortschritt"] = mini(maxi(int(round(anteil * neue_zeit)), 0), maxi(neue_zeit, 1))
	neu["ziel_ticks"] = neue_zeit
	return neu

func ist_fertig(zustand: Dictionary) -> bool:
	return int(zustand.get("phase", Phase.NICHT_GEBAUT)) == Phase.FERTIG

func fortschritt_anteil(zustand: Dictionary, bauzeit_ticks: int) -> float:
	# Der Anteil bezieht sich auf die effektive Zeit der eigenen Maschine,
	# damit das HUD den echten Fertigstellungsgrad zeigt.
	var effektive_zeit := _modifikatoren.zeit_berechnen(bauzeit_ticks)
	if effektive_zeit <= 0:
		return 1.0
	return clampf(float(int(zustand.get("fortschritt", 0))) / float(effektive_zeit), 0.0, 1.0)

func phase_name(zustand: Dictionary) -> String:
	return str(PHASEN_NAMEN.get(int(zustand.get("phase", Phase.NICHT_GEBAUT)), "unbekannt"))
