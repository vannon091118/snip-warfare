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

## Kategorie daten: eigene Modifikator-Maschine mit Bereich Produktion aus
## den globalen Settings; die Basis-Dauer kommt weiterhin aus der Definition.
var _modifikatoren := Kern_ModifikatorMaschine.new()

## Kategorie logik: Zustandsübergänge über die Weltzeit.

func _init() -> void:
	_modifikatoren.bereich_setzen("produktion")
	_modifikatoren.aktualisieren()

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
	# Die effektive Dauer kommt aus der eigenen Modifikator-Maschine;
	# der Zustand merkt sich die geltende Zeit für die Menü-Abstimmung.
	var phase := int(zustand.get("phase", Phase.DEAKTIVIERT))
	var fortschritt := int(zustand.get("fortschritt", 0))
	var effektive_dauer := _modifikatoren.zeit_berechnen(definition.dauer_ticks)
	var neu := zustand.duplicate(true)
	neu["aktion"] = "keine"
	neu["ziel_ticks"] = effektive_dauer
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
			if effektive_dauer > 0 and neuer_fortschritt >= effektive_dauer:
				neu["fortschritt"] = effektive_dauer
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

func zeit_ticks_fuer(dauer_ticks: int) -> int:
	# Öffentlicher Zugriff auf die effektive Dauer der eigenen Maschine.
	return _modifikatoren.zeit_berechnen(dauer_ticks)

func abstimmen(zustand: Dictionary, definition: Gebaeude_Definition) -> Dictionary:
	# Menü-Gegenprüfung: Der Fortschritt wird prozentual auf die neue
	# effektive Dauer skaliert, damit Anzeige und Abschluss präzise sind.
	var neu := zustand.duplicate(true)
	if int(neu.get("phase", Phase.DEAKTIVIERT)) != Phase.LAEUFT:
		return neu
	var alte_zeit := maxi(int(neu.get("ziel_ticks", definition.dauer_ticks)), 1)
	var anteil := clampf(float(int(neu.get("fortschritt", 0))) / float(alte_zeit), 0.0, 1.0)
	var neue_zeit := _modifikatoren.zeit_berechnen(definition.dauer_ticks)
	neu["fortschritt"] = mini(maxi(int(round(anteil * neue_zeit)), 0), maxi(neue_zeit, 1))
	neu["ziel_ticks"] = neue_zeit
	return neu

func fortschritt_anteil(zustand: Dictionary, dauer_ticks: int) -> float:
	# Der Anteil bezieht sich auf die effektive Zeit der eigenen Maschine,
	# damit das HUD den echten Fertigstellungsgrad zeigt.
	var effektive_dauer := _modifikatoren.zeit_berechnen(dauer_ticks)
	if effektive_dauer <= 0:
		return 1.0
	return clampf(float(int(zustand.get("fortschritt", 0))) / float(effektive_dauer), 0.0, 1.0)

func phase_name(zustand: Dictionary) -> String:
	return str(PHASEN_NAMEN.get(int(zustand.get("phase", Phase.DEAKTIVIERT)), "unbekannt"))