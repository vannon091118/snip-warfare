extends RefCounted
class_name Welt_FortschrittsMaschine
## Zuständigkeitsmaschine der Einstiegs-Progression. Sie trägt ausschließlich
## den Stufen-Zustand: Welche Stufe aktiv ist, ob ein Ziel erfüllt ist und was
## die Stufe freischaltet. Sie rechnet nur mit den Einträgen der
## Welt_FortschrittsRegistry, besitzt keine eigenen Zahlen und tickt nicht selbst;
## der Gebaeude_Manager meldet Bauabschlüsse, der Einwanderungs-Zustand wird
## von außen gesetzt. Freischaltungen und Zielabschluss werden als Signale
## sichtbar, damit HUD und Eingabe ohne Umwege reagieren können.

signal stufe_erreicht(stufe: Dictionary)
signal ziel_erreicht(stufe: Dictionary)

## Kategorie daten: der aktuelle Stufen-Zustand.
var stufe_index: int = 0
var abgeschlossen: Dictionary = {}

## Kategorie logik: Ziel prüfen, Fortschalten, Freischalten lesen.

func _init() -> void:
	abgeschlossen = {}

func registry_setzen(registry: Welt_FortschrittsRegistry) -> void:
	_registry = registry

func aktive_stufe() -> Dictionary:
	if _registry == null:
		return {}
	return _registry.stufe_an(stufe_index)

func ziel_zeile() -> String:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return "Alle Ziele erreicht."
	return "Ziel: %s" % str(stufe.get("beschreibung", ""))

## Zieltyp gebaeude_bauen: Der Manager meldet jedes fertiggestellte Gebäude.
func gebaeude_fertiggestellt(gebaeude_id: String) -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	if str(stufe.get("ziel_typ", "")) != "gebaeude_bauen":
		return
	if str(stufe.get("gebaeude_id", "")) != gebaeude_id:
		return
	_fortschalten()

## Zieltyp einwanderung: Der Manager meldet jeden Ankömmling.
func einwanderer_angekommen() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	if str(stufe.get("ziel_typ", "")) != "einwanderung":
		return
	_fortschalten()

func _fortschalten() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	abgeschlossen[str(stufe.get("id", ""))] = true
	ziel_erreicht.emit(stufe)
	if stufe_index + 1 < _registry.stufen_zahl():
		stufe_index += 1
		stufe_erreicht.emit(aktive_stufe())

## Gating-Frage der Eingabe: Eine Aktion mit gesperrt_ab_stufe N ist frei,
## sobald die Kette mindestens Stufe N erreicht hat; 0 heißt immer offen.
func stufe_frei(gesperrt_ab_stufe: int) -> bool:
	return stufe_index >= gesperrt_ab_stufe

## Lesende Freischaltungen der erreichten Stufen (nur Beobachtung).
func freigeschaltete_gebaeude() -> Array[String]:
	var frei: Array[String] = []
	if _registry == null:
		return frei
	for index in stufe_index + 1:
		var stufe := _registry.stufe_an(index)
		for gebaeude_id: Variant in (stufe.get("schaltet_frei", {}).get("gebaeude", []) as Array):
			frei.append(str(gebaeude_id))
	return frei

var _registry: Welt_FortschrittsRegistry = null
