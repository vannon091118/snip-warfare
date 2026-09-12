extends RefCounted
class_name Welt_FortschrittsMaschine
## Zuständigkeitsmaschine der Einstiegs-Progression. Sie trägt ausschließlich
## den Stufen-Zustand: Welche Stufe aktiv ist, ob ein Ziel erfüllt ist und was
## die Stufe freischaltet. Sie rechnet nur mit den Einträgen der
## Welt_FortschrittsRegistry, besitzt keine eigenen Zahlen und tickt nicht selbst;
## der Gebaeude_Manager meldet Bauabschlüsse, der Einwanderungs-Zustand wird
## von außen gesetzt. Freischaltungen und Zielabschluss werden als Signale
## sichtbar, damit HUD und Eingabe ohne Umwege reagieren können.
## Wenn ein Rathaus-Möbel-Set den Produktionsraum "rathaus" vervollständigt,
## spawnt diese Maschine die Orchestrator_Einheit über den Einheit_Manager.

signal stufe_erreicht(stufe: Dictionary)
signal ziel_erreicht(stufe: Dictionary)
signal orchestrator_gespawnt(position: Vector2)

## Kategorie daten: der aktuelle Stufen-Zustand.
var stufe_index: int = 0
var abgeschlossen: Dictionary = {}

## Kategorie logik: Verbindungen zu anderen Domänen.
var _einheit_manager: Einheit_Manager = null
var _orchestrator_manager: Orchestrator_Manager = null
var _rassen_registry: Pop_RassenSchemaRegistry = null

## Kategorie logik: Ziel prüfen, Fortschalten, Freischalten lesen.

func _init() -> void:
	abgeschlossen = {}

func registry_setzen(registry: Welt_FortschrittsRegistry) -> void:
	_registry = registry

func einheit_manager_setzen(manager: Einheit_Manager) -> void:
	_einheit_manager = manager
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("produktionsraum_entstanden") and not bus.produktionsraum_entstanden.is_connected(_auf_produktionsraum_entstanden):
		bus.produktionsraum_entstanden.connect(_auf_produktionsraum_entstanden)

func orchestrator_manager_setzen(manager: Orchestrator_Manager) -> void:
	_orchestrator_manager = manager

func rassen_registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_rassen_registry = registry

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

## Reaktion auf Rathaus-Fertigstellung: Spawnt die Orchestrator-Einheit.
func _auf_produktionsraum_entstanden(raum_id: String, profil: String) -> void:
	if profil != "rathaus":
		return
	if _einheit_manager == null:
		push_warning("Welt_FortschrittsMaschine: Einheit_Manager nicht gesetzt, Orchestrator kann nicht gespawnt werden")
		return
	# Spawn-Position: Verwende die Position des Raums (hier vereinfacht: Anker-Position)
	var spawn_position := Vector2(500, 300)  # Standard-Position, könnte aus Raum-Daten kommen
	# Prüfe Spawn-Cap vor dem Spawn (Rasse = "mensch" als Default)
	if _spawn_cap_erreicht("mensch"):
		push_warning("Welt_FortschrittsMaschine: Spawn-Cap für Mensch erreicht, Orchestrator nicht gespawnt")
		return
	var einheit_index := _einheit_manager.einheit_hinzufuegen(spawn_position, "mensch")
	# Registriere die Einheit als Orchestrator für die erste Zone (Index 0)
	if _orchestrator_manager != null:
		_orchestrator_manager.einheit_als_orchestrator_registrieren(einheit_index, 0)
	orchestrator_gespawnt.emit(spawn_position)

func _spawn_cap_erreicht(rasse_id: String) -> bool:
	if _einheit_manager == null:
		return false
	# Lade rassen_schemata.json direkt für max_einheiten
	var config_pfad := "res://population/data/rassen_schemata.json"
	if not FileAccess.file_exists(config_pfad):
		return false
	var datei := FileAccess.open(config_pfad, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		return false
	var rassen := gelesen as Dictionary
	if not rassen.has(rasse_id):
		return false
	var max_einheiten := int(rassen[rasse_id].get("max_einheiten", 20))
	return _einheit_manager.einheiten_zahl() >= max_einheiten

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
