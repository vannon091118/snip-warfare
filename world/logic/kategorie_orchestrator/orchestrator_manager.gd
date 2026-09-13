extends Node2D
class_name Orchestrator_Manager
## Manager des Orchestrators: Verantwortlich für die Verarbeitung von
## Orchestrator-Zonen alle 60 Ticks. Er liest die Konfiguration aus
## orchestrator_config.json, weist freien Einheiten Jobs zu und respektiert
## Spawn-Caps aus rassen_schemata.json. Der Spieler kann per Klick auf einen
## Orchestrator die Prioritäten in der Config ändern.

signal orchestrator_platziert(status: Orchestrator_Status, konfig: Orchestrator_Konfiguration)

## Kategorie daten: die verwalteten Orchestratoren mit Status und Zone.
var _orchestratoren: Array[Dictionary] = []

## Kategorie daten: Zuordnung Einheit-Index -> Orchestrator-Zonen-Index.
var _einheit_zu_zone: Dictionary = {}

## Kategorie logik: Verbindungen zu anderen Domänen und Tick-Intervall.
var _einheit_manager: Einheit_Manager = null
var _welt_modell: Welt_Model = null
var _welt_registry: Welt_Registry = null
var _job_registry: Job_Registry = null

## Tick-Zähler: Alle 60 Ticks wird die Orchestrierung neu evaluiert.
var _tick_counter: int = 0

## Kategorie daten: Referenz auf die Orchestrator-Konfiguration.
var orchestrator_config: Dictionary = {}
var _rassen_registry: Pop_RassenSchemaRegistry = null

func rassen_registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_rassen_registry = registry

func _enter_tree() -> void:
	# Die Weltuhr wird zur Laufzeit aufgeloesst statt ueber den Autoload-Globalnamen,
	# damit der Manager auch in Headless-Testlaeufen ohne Autoloads ladbar bleibt.
	# Im Spiel ist es dieselbe zentrale Uhr aus project.godot.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func referenzen_setzen(einheit_manager: Einheit_Manager, welt_modell: Welt_Model, welt_registry: Welt_Registry, job_registry: Job_Registry) -> void:
	_einheit_manager = einheit_manager
	_welt_modell = welt_modell
	_welt_registry = welt_registry
	_job_registry = job_registry
	load_orchestrator_config()

func load_orchestrator_config() -> void:
	## Lade die Orchestrator-Konfiguration aus game/data/orchestrator_config.json
	var config_pfad := "res://game/data/orchestrator_config.json"
	if FileAccess.file_exists(config_pfad):
		var datei := FileAccess.open(config_pfad, FileAccess.READ)
		var gelesen: Variant = JSON.parse_string(datei.get_as_text())
		if typeof(gelesen) == TYPE_DICTIONARY:
			orchestrator_config = gelesen
			print("Orchestrator-Konfiguration geladen: %d Zonen" % orchestrator_config.size())
		else:
			push_warning("Orchestrator-Konfiguration ungültig: %s" % config_pfad)

func orchestrator_platzieren(konfig: Orchestrator_Konfiguration) -> int:
	var status := Orchestrator_Status.new()
	status.konfigurieren(konfig)
	status.bedarf_pruefen.connect(_auf_bedarf_pruefen)
	var idx := _orchestratoren.size()
	_orchestratoren.append({"status": status, "konfig": konfig, "einheiten": []})
	orchestrator_platziert.emit(status, konfig)
	return idx

func status_fuer(idx: int) -> Orchestrator_Status:
	if idx < 0 or idx >= _orchestratoren.size():
		return null
	return _orchestratoren[idx]["status"]

## Gibt den Orchestrator-Zonen-Index für eine Einheit zurück, oder -1.
func zonen_index_fuer_einheit(einheit_index: int) -> int:
	if _einheit_zu_zone.has(einheit_index):
		return _einheit_zu_zone[einheit_index]
	return -1

## Registriert eine Einheit als Orchestrator für eine bestimmte Zone.
func einheit_als_orchestrator_registrieren(einheit_index: int, zonen_index: int) -> void:
	_einheit_zu_zone[einheit_index] = zonen_index
	if zonen_index >= 0 and zonen_index < _orchestratoren.size():
		var einheiten_array: Array = _orchestratoren[zonen_index].get("einheiten", [])
		if not einheiten_array.has(einheit_index):
			einheiten_array.append(einheit_index)
			_orchestratoren[zonen_index]["einheiten"] = einheiten_array

func _auf_bedarf_pruefen(_konfig: Orchestrator_Konfiguration) -> void:
	pass

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	_tick_counter += 1
	# Alle 60 Ticks Orchestrierung evaluieren
	if _tick_counter % 60 != 0:
		return

	# Sicherstellen, dass Referenzen gesetzt sind
	if _einheit_manager == null or _welt_modell == null or _welt_registry == null:
		return

	# Spawn-Cap prüfen: Einheiten_count < max_einheiten aus rassen_schemata.json
	var max_einheiten := _max_einheiten_fuer_rasse()
	if _einheit_manager.einheit_zahl() >= max_einheiten:
		# Cap erreicht: Es tickt weiter, aber keine neuen Einheiten mehr.
		return

	# Freie Einheiten im System holen
	var frei_einheiten: Array = _einheit_manager.idle_einheiten()
	if frei_einheiten.is_empty():
		return

	# Jede Orchestrator-Zone abarbeiten nach Priorität
	for eintrag: Dictionary in _orchestratoren:
		var status: Orchestrator_Status = eintrag["status"]
		var konfig: Orchestrator_Konfiguration = eintrag["konfig"]

		# Aus der Konfiguration Bedarfsliste lesen und nach Priorität sortieren
		var sortierte_bedarfe := konfig.sortierte_bedarfe()

		for bedarf: Dictionary in sortierte_bedarfe:
			if frei_einheiten.is_empty():
				break

			var ressource := str(bedarf.get("ressource", ""))
			var job_id := str(bedarf.get("job_id", ""))
			var prioritaet := int(bedarf.get("prioritaet", 1))

			if job_id == "" or ressource == "":
				continue

			# Job vom Registry erzeugen
			var job := _job_registry.job_erzeugen(job_id)
			if job == null:
				continue

			# Ressource aus Job prüfen
			var job_ressource := job.ressource()
			if job_ressource != "" and job_ressource != ressource:
				continue

			# Höchst verfügbare Menge für diesen Bedarf
			var menge_bedarf := int(bedarf.get("menge", 0))

			# So viele wie mögliche freie Einheiten und gewünschte Menge zuweisen
			var zu_weisende := frei_einheiten.size()
			if menge_bedarf > 0:
				zu_weisende = min(zu_weisende, menge_bedarf)

			for _i in range(zu_weisende):
				if frei_einheiten.is_empty():
					break

				var einheit_idx: int = frei_einheiten.pop_front()
				var ziel_index := _naechstes_objekt_fuer_ressource(ressource, konfig.position, konfig.radius)
				if ziel_index < 0:
					# Ziel nicht gefunden, Einheit wieder frei geben
					frei_einheiten.append(einheit_idx)
					continue

				var ziel_position := _welt_modell.objekt_position(ziel_index)
				_einheit_manager.job_vergeben(
					einheit_idx,
					job_id,
					Job_Basis.ZielTyp.OBJEKT,
					ziel_index,
					ziel_position
				)


func _max_einheiten_fuer_rasse() -> int:
	# Liefert das max_einheiten für die Standardrasse (mensch) aus dem Rassen-Registry.
	if _rassen_registry == null:
		var config_pfad := "res://population/data/rassen_schemata.json"
		if not FileAccess.file_exists(config_pfad):
			return 20
		var datei := FileAccess.open(config_pfad, FileAccess.READ)
		var gelesen: Variant = JSON.parse_string(datei.get_as_text())
		if typeof(gelesen) != TYPE_DICTIONARY:
			return 20
		var rassen := gelesen as Dictionary
		if not rassen.has("mensch"):
			return 20
		return int(rassen["mensch"].get("max_einheiten", 20))
	var schema := _rassen_registry.schema_fuer("mensch")
	if schema == null:
		return 20
	return schema.max_einheiten

func _naechstes_objekt_fuer_ressource(ressource: String, zentrum: Vector2, radius: float) -> int:
	# Nächstes Objekt mit passender Arbeitsressource innerhalb des Radius.
	if _welt_modell == null or _welt_registry == null:
		return -1
	var bester_index := -1
	var beste_distanz := 1e9
	for index in _welt_modell.objekt_anzahl():
		var element_id := _welt_modell.objekt_element_id(index)
		if element_id == "":
			continue
		var objekt := _welt_registry.finde_objekt(element_id)
		if objekt == null or objekt.arbeits_ressource != ressource:
			continue
		var objekt_position := _welt_modell.objekt_position(index)
		var distanz := objekt_position.distance_to(zentrum)
		if distanz <= radius and distanz < beste_distanz:
			beste_distanz = distanz
			bester_index = index
	return bester_index

func _einheiten_im_radius(konfig: Orchestrator_Konfiguration) -> Array[int]:
	# Freie Einheiten im Zone-Radius; die Reihenfolge bleibt stabil.
	var gefundene: Array[int] = []
	if _einheit_manager == null:
		return gefundene
	for index in _einheit_manager.einheit_zahl():
		var einheit_position := _einheit_manager.einheit_position(index)
		var im_radius := einheit_position.distance_to(konfig.position) <= konfig.radius
		if im_radius and _einheit_manager.job_id_einheit(index) == "":
			gefundene.append(index)
	return gefundene
