extends PopupPanel
class_name Ui_OrchestratorPriorityPanel
## Panel für Orchestrator-Prioritäten: Der Spieler klickt auf eine
## Orchestrator-Einheit und ändert die Prioritäten der Bedarfsliste in
## der orchestrator_config.json. Das Panel liest die Konfiguration des
## gewählten Orchestrators und bietet Buttons zum Erhöhen/Erniedrigen
## der Priorität. Änderungen werden sofort in die JSON-Datei geschrieben.

signal panel_geschlossen()

## Kategorie daten: Referenzen und aktueller Zustand.
var _orchestrator_manager: Orchestrator_Manager = null
var _auswahl_manager: Ui_AuswahlManager = null
var _aktuelle_konfig_index: int = -1
var _aktuelle_konfig: Orchestrator_Konfiguration = null
var _ui_container: VBoxContainer = null

## Kategorie logik: Aufbau und Events.

func _ready() -> void:
	_ui_container = VBoxContainer.new()
	_ui_container.name = "PriorityContainer"
	add_child(_ui_container)
	# Panel standardmäßig versteckt (PopupPanel ist initial nicht sichtbar)

func einrichten(orchestrator_manager: Orchestrator_Manager, auswahl_manager: Ui_AuswahlManager) -> void:
	_orchestrator_manager = orchestrator_manager
	_auswahl_manager = auswahl_manager

func fuer_orchestrator_oeffnen(konfig_index: int) -> void:
	if _orchestrator_manager == null:
		return
	var status := _orchestrator_manager.status_fuer(konfig_index)
	if status == null:
		return
	_aktuelle_konfig_index = konfig_index
	_aktuelle_konfig = status.konfiguration
	if _aktuelle_konfig == null:
		return
	_ui_erstellen()
	popup_centered()

func _ui_erstellen() -> void:
	_ui_container.queue_free()
	_ui_container = VBoxContainer.new()
	_ui_container.name = "PriorityContainer"
	add_child(_ui_container)

	# Titel
	var titel := Label.new()
	titel.text = "Orchestrator-Prioritäten: %s" % _aktuelle_konfig.orchestrator_id
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titel.add_theme_constant_override("font_size", 18)
	_ui_container.add_child(titel)

	# Zone-Info
	var info := Label.new()
	info.text = "Position: (%.0f, %.0f)  Radius: %.0f  Biom: %s" % [
		_aktuelle_konfig.position.x, _aktuelle_konfig.position.y,
		_aktuelle_konfig.radius, _aktuelle_konfig.biom_id
	]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_container.add_child(info)

	# Trennlinie
	var trennung := HSeparator.new()
	_ui_container.add_child(trennung)

	# Bedarfsliste mit Prioritäts-Buttons
	var bedarfe := _aktuelle_konfig.sortierte_bedarfe()
	for idx in bedarfe.size():
		var bedarf: Dictionary = bedarfe[idx]
		var ressource := str(bedarf.get("ressource", ""))
		var job_id := str(bedarf.get("job_id", ""))
		var prioritaet := int(bedarf.get("prioritaet", 1))
		var menge := int(bedarf.get("menge", 0))

		var zeile := HBoxContainer.new()
		_ui_container.add_child(zeile)

		# Ressource + Job
		var label := Label.new()
		label.text = "%s (%s) - Menge: %d" % [ressource, job_id, menge]
		label.custom_minimum_size = Vector2(200, 0)
		zeile.add_child(label)

		# Priorität anzeigen
		var prio_label := Label.new()
		prio_label.text = "Prio: %d" % prioritaet
		prio_label.custom_minimum_size = Vector2(80, 0)
		prio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zeile.add_child(prio_label)

		# Button: Priorität erhöhen (kleinere Zahl = höhere Priorität)
		var btn_hoch := Button.new()
		btn_hoch.text = "▲"
		btn_hoch.custom_minimum_size = Vector2(40, 30)
		btn_hoch.disabled = (prioritaet <= 1)
		btn_hoch.pressed.connect(_auf_prioritaet_hoch.bind(idx, prio_label))
		zeile.add_child(btn_hoch)

		# Button: Priorität erniedrigen
		var btn_runter := Button.new()
		btn_runter.text = "▼"
		btn_runter.custom_minimum_size = Vector2(40, 30)
		btn_runter.pressed.connect(_auf_prioritaet_runter.bind(idx, prio_label))
		zeile.add_child(btn_runter)

		# Button: Bedarf entfernen
		var btn_entfernen := Button.new()
		btn_entfernen.text = "✕"
		btn_entfernen.custom_minimum_size = Vector2(40, 30)
		btn_entfernen.pressed.connect(_auf_bedarf_entfernen.bind(idx))
		zeile.add_child(btn_entfernen)

	# Neuer Bedarf hinzufügen
	var trennung2 := HSeparator.new()
	_ui_container.add_child(trennung2)

	var btn_neu := Button.new()
	btn_neu.text = "Neuen Bedarf hinzufügen"
	btn_neu.pressed.connect(_auf_neuen_bedarf)
	_ui_container.add_child(btn_neu)

	# Schließen-Button
	var btn_schliessen := Button.new()
	btn_schliessen.text = "Schließen"
	btn_schliessen.pressed.connect(_auf_schliessen)
	_ui_container.add_child(btn_schliessen)

func _auf_prioritaet_hoch(idx: int, _prio_label: Label) -> void:
	if _aktuelle_konfig == null or _orchestrator_manager == null:
		return
	var bedarfe := _aktuelle_konfig.bedarfsliste
	if idx < 0 or idx >= bedarfe.size():
		return
	var neue_prio := int(bedarfe[idx].get("prioritaet", 1)) - 1
	if neue_prio < 1:
		neue_prio = 1
	bedarfe[idx]["prioritaet"] = neue_prio
	_config_speichern()
	_ui_erstellen()

func _auf_prioritaet_runter(idx: int, _prio_label: Label) -> void:
	if _aktuelle_konfig == null or _orchestrator_manager == null:
		return
	var bedarfe := _aktuelle_konfig.bedarfsliste
	if idx < 0 or idx >= bedarfe.size():
		return
	var neue_prio := int(bedarfe[idx].get("prioritaet", 1)) + 1
	bedarfe[idx]["prioritaet"] = neue_prio
	_config_speichern()
	_ui_erstellen()

func _auf_bedarf_entfernen(idx: int) -> void:
	if _aktuelle_konfig == null or _orchestrator_manager == null:
		return
	var bedarfe := _aktuelle_konfig.bedarfsliste
	if idx < 0 or idx >= bedarfe.size():
		return
	bedarfe.remove_at(idx)
	_config_speichern()
	_ui_erstellen()

func _auf_neuen_bedarf() -> void:
	# Einfacher Dialog für neuen Bedarf: In der Praxis wäre hier ein
	# separates Eingabe-Panel besser. Für jetzt fügen wir einen Standard
	# Bedarf hinzu.
	if _aktuelle_konfig == null or _orchestrator_manager == null:
		return
	var bedarfe := _aktuelle_konfig.bedarfsliste
	var neue_prio := bedarfe.size() + 1
	bedarfe.append({
		"ressource": "holz",
		"menge": 10,
		"prioritaet": neue_prio,
		"job_id": "holzfaeller"
	})
	_config_speichern()
	_ui_erstellen()

func _auf_schliessen() -> void:
	hide()
	panel_geschlossen.emit()

func _config_speichern() -> void:
	# Schreibe die geänderte Konfiguration zurück in die JSON-Datei
	var config_pfad := "res://game/data/orchestrator_config.json"
	if not FileAccess.file_exists(config_pfad):
		push_warning("Orchestrator-Konfiguration nicht gefunden: %s" % config_pfad)
		return
	var datei := FileAccess.open(config_pfad, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Orchestrator-Konfiguration ungültig")
		return
	var daten := gelesen as Dictionary
	var orch_id := _aktuelle_konfig.orchestrator_id
	if daten.has(orch_id):
		# Aktualisiere nur die Bedarfsliste, andere Felder bleiben erhalten
		daten[orch_id]["bedarfsliste"] = _aktuelle_konfig.bedarfsliste
		# Schreibe zurück
		var schreib_datei := FileAccess.open(config_pfad, FileAccess.WRITE)
		if schreib_datei != null:
			schreib_datei.store_string(JSON.stringify(daten, "\t"))
		# Reload im Manager
		_orchestrator_manager.load_orchestrator_config()
