extends Node2D
class_name Gebaeude_Manager
## Manager der Gebäude: Er tickt Bau- und Produktionsmaschinen über die
## zentrale Weltuhr, prüft und entnimmt Kosten über Einheit_Ressourcen und
## Lager_Manager und lagert Ausgänge ein. Er greift nie direkt in fremde
## Daten ein: Das Weltmodell schreibt er nur über eigene Funktionen, die
## Bestände nur über die Ressourcen-Schnittstelle.

signal gebaeude_meldung(text: String)
signal gebaeude_fertiggestellt(gebaeude_id: String)

## Kategorie daten: Definitionen und die zwei Zustandsmaschinen.
var _definitionen := Gebaeude_DefinitionRegistry.new()
var _bau_maschine := Gebaeude_BauMaschine.new()
var _produktions_maschine := Gebaeude_ProduktionsMaschine.new()
var _fortschritt: Welt_FortschrittsMaschine = null

## Kategorie logik: Verbindungen zu anderen Domänen und Tick.
var _model: Welt_Model = null
var _registry: Welt_Registry = null
var _ressourcen: Einheit_Ressourcen = null
var _lager: Lager_Manager = null

func _ready() -> void:
	# Die Weltuhr wird zur Laufzeit aufgelöst statt über den Autoload-Globalnamen,
	# damit der Manager auch in Headless-Testläufen ohne Autoloads kompilierbar
	# bleibt. Im Spiel ist es dieselbe zentrale Uhr aus project.godot.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)
	# Menü-Gegenprüfung: Ein geöffnetes Menü stößt die Abstimmung aller
	# Gebäude-Fortschritte an, damit Anzeige und Zeiten präzise bleiben.
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("menue_geoeffnet") and not bus.menue_geoeffnet.is_connected(_auf_menue_geoeffnet):
		bus.menue_geoeffnet.connect(_auf_menue_geoeffnet)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("menue_geoeffnet") and bus.menue_geoeffnet.is_connected(_auf_menue_geoeffnet):
		bus.menue_geoeffnet.disconnect(_auf_menue_geoeffnet)

func einrichten(model: Welt_Model, registry: Welt_Registry, ressourcen: Einheit_Ressourcen, lager: Lager_Manager, fortschritt: Welt_FortschrittsMaschine = null) -> void:
	_model = model
	_registry = registry
	_ressourcen = ressourcen
	_lager = lager
	_fortschritt = fortschritt

func bauen_anfordern(gebaeude_id: String, welt_position: Vector2) -> Dictionary:
	# Spieler löst den Bau aus: Freigabe, Kosten und Lager werden vorher
	# vollständig geprüft und dann entnommen; das Gebäude erscheint im
	# Modell mit Bauzustand.
	if _model == null or _ressourcen == null or _lager == null:
		return {"ok": false, "grund": "nicht bereit"}
	if _fortschritt != null:
		var zugang := voraussetzung_erfuellt(gebaeude_id)
		if not zugang.get("ok", false):
			return zugang
	if not _definitionen.hat_gebaeude(gebaeude_id):
		return {"ok": false, "grund": "unbekanntes Gebaeude"}
	var definition := _definitionen.definition_fuer(gebaeude_id)
	var lager_index := _lager.naechstes_lager_fuer(welt_position)
	if lager_index < 0:
		return {"ok": false, "grund": "kein Lager in der Naehe"}
	# Atomare Buchung: Die kumulative Pruefung deckt alle Kosten zusammen
	# ab, erst dann wird entnommen; eine Teil-Entnahme ohne Rollback ist
	# damit ausgeschlossen (ein Schritt statt Pruefen und dann Entnehmen).
	if not _ressourcen.mehrfach_entnehmen(definition.baukosten_paare(), lager_index):
		return {"ok": false, "grund": "Kosten fehlen"}
	var objekt_index := _model.objekt_hinzufuegen(definition.welt_objekt_id, welt_position)
	_model.objekt_feld_setzen(objekt_index, "gebaeude_id", gebaeude_id)
	var bau_zustand := _bau_maschine.starten(Gebaeude_BauMaschine.neuer_zustand())
	_model.objekt_feld_setzen(objekt_index, "bau_phase", int(bau_zustand["phase"]))
	_model.objekt_feld_setzen(objekt_index, "bau_fortschritt", 0)
	_model.objekt_feld_setzen(objekt_index, "bau_ziel_ticks", _bau_maschine.zeit_ticks_fuer(definition.bauzeit_ticks))
	_model.objekt_feld_setzen(objekt_index, "prod_phase", int(Gebaeude_ProduktionsMaschine.Phase.DEAKTIVIERT))
	_model.objekt_feld_setzen(objekt_index, "prod_fortschritt", 0)
	_model.objekt_feld_setzen(objekt_index, "prod_ziel_ticks", _produktions_maschine.zeit_ticks_fuer(definition.dauer_ticks))
	gebaeude_meldung.emit("Bau angefordert: %s (%d Ticks)" % [definition.angezeigter_name, definition.bauzeit_ticks])
	return {"ok": true}

## Freigabe-Voraussetzungen aus der Definition: Jedes Gebäude kann andere
## Gebäude verlangen (z. B. das Haus verlangt das Lagerfeuer); unbekannte
## Voraussetzungen zählen nur, wenn sie als gebaute Objekte fehlen.
func voraussetzung_erfuellt(gebaeude_id: String) -> Dictionary:
	var definition := _definitionen.definition_fuer(gebaeude_id)
	if definition == null:
		return {"ok": false, "grund": "unbekanntes Gebaeude"}
	for voraussetzung: String in definition.voraussetzungen:
		if not _gebaeude_existiert_im_modell(voraussetzung):
			return {"ok": false, "grund": "braucht zuerst: %s" % voraussetzung}
	return {"ok": true}

func _gebaeude_existiert_im_modell(gebaeude_id: String) -> bool:
	if _model == null:
		return false
	for index in _model.objekt_anzahl():
		if str(_model.objekt_feld(index, "gebaeude_id", "")) == gebaeude_id:
			return true
	return false

func status_zeilen() -> Array[String]:
	# Reine Beobachtung für das HUD: pro Gebäude eine kompakte Zeile.
	var zeilen: Array[String] = []
	if _model == null:
		return zeilen
	for index in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition == null:
			continue
		var bau_zustand := {
			"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
			"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
		}
		if not _bau_maschine.ist_fertig(bau_zustand):
			var anteil := int(_bau_maschine.fortschritt_anteil(bau_zustand, definition.bauzeit_ticks) * 100.0)
			zeilen.append("%s: %s %d%%" % [definition.angezeigter_name, _bau_maschine.phase_name(bau_zustand), anteil])
			continue
		var prod_zustand := {
			"phase": int(_model.objekt_feld(index, "prod_phase", 0)),
			"fortschritt": int(_model.objekt_feld(index, "prod_fortschritt", 0)),
		}
		var phase_text := _produktions_maschine.phase_name(prod_zustand)
		if int(prod_zustand["phase"]) == Gebaeude_ProduktionsMaschine.Phase.LAEUFT:
			var prod_anteil := int(_produktions_maschine.fortschritt_anteil(prod_zustand, definition.dauer_ticks) * 100.0)
			zeilen.append("%s: %s %d%%" % [definition.angezeigter_name, phase_text, prod_anteil])
		else:
			zeilen.append("%s: %s" % [definition.angezeigter_name, phase_text])
	return zeilen

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	if _model == null or _ressourcen == null or _lager == null:
		return
	for index in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition == null:
			continue
		_bau_ticken(index, definition)
		if _bau_fertig(index):
			_produktion_ticken(index, definition)

func _bau_fertig(index: int) -> bool:
	var zustand := {
		"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
	}
	return _bau_maschine.ist_fertig(zustand)

func _bau_ticken(index: int, definition: Gebaeude_Definition) -> void:
	var zustand := {
		"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
	}
	if _bau_maschine.ist_fertig(zustand):
		return
	var neu := _bau_maschine.tick(zustand, definition.bauzeit_ticks)
	_model.objekt_feld_setzen(index, "bau_phase", int(neu["phase"]))
	_model.objekt_feld_setzen(index, "bau_fortschritt", int(neu["fortschritt"]))
	_model.objekt_feld_setzen(index, "bau_ziel_ticks", int(neu.get("ziel_ticks", definition.bauzeit_ticks)))
	if _bau_maschine.ist_fertig(neu):
		# Bau abgeschlossen: Produktion geht in den Wartezustand.
		var prod := _produktions_maschine.starten(Gebaeude_ProduktionsMaschine.neuer_zustand())
		_model.objekt_feld_setzen(index, "prod_phase", int(prod["phase"]))
		_model.objekt_feld_setzen(index, "prod_fortschritt", 0)
		_model.objekt_feld_setzen(index, "prod_ziel_ticks", _produktions_maschine.zeit_ticks_fuer(definition.dauer_ticks))
		gebaeude_meldung.emit("%s ist fertig gebaut und wartet auf Eingänge." % definition.angezeigter_name)
		# Die Progressions-Kette erfährt den Abschluss direkt: Wer dem Manager
		# eine Maschine reicht, muss sie nicht zusätzlich verdrahten; das
		# Signal bleibt für reine Beobachter wie das HUD daneben stehen.
		if _fortschritt != null:
			_fortschritt.gebaeude_fertiggestellt(definition.id)
		gebaeude_fertiggestellt.emit(definition.id)

func _produktion_ticken(index: int, definition: Gebaeude_Definition) -> void:
	var zustand := {
		"phase": int(_model.objekt_feld(index, "prod_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "prod_fortschritt", 0)),
	}
	var lager_index := _lager.naechstes_lager_fuer(_model.objekt_position(index))
	var eingang_ok := lager_index >= 0 and _eingang_verfuegbar(definition, lager_index)
	var lager_ok := lager_index >= 0 and _lager.hat_lagerplatz(lager_index, _output_menge(definition))
	var neu := _produktions_maschine.tick(zustand, definition, eingang_ok, lager_ok)
	match str(neu.get("aktion", "keine")):
		"input_ziehen":
			if _inputs_entnehmen(definition, lager_index):
				gebaeude_meldung.emit("%s beginnt zu produzieren." % definition.angezeigter_name)
			else:
				neu = _produktions_maschine.phase_erzwingen(neu, Gebaeude_ProduktionsMaschine.Phase.WARTET_EINGANG)
		"output_legen":
			if _outputs_einlagern(definition, index):
				var namen: Array[String] = []
				for output: Dictionary in definition.outputs:
					namen.append("%d %s" % [int(output.get("menge", 0)), str(output.get("ressource", ""))])
				gebaeude_meldung.emit("%s hat %s hergestellt und eingelagert." % [definition.angezeigter_name, ", ".join(namen)])
			else:
				neu = _produktions_maschine.phase_erzwingen(neu, Gebaeude_ProduktionsMaschine.Phase.WARTET_AUSGANG)
	_model.objekt_feld_setzen(index, "prod_phase", int(neu.get("phase", zustand["phase"])))
	_model.objekt_feld_setzen(index, "prod_fortschritt", int(neu.get("fortschritt", zustand["fortschritt"])))
	_model.objekt_feld_setzen(index, "prod_ziel_ticks", int(neu.get("ziel_ticks", definition.dauer_ticks)))

func _eingang_verfuegbar(definition: Gebaeude_Definition, lager_index: int) -> bool:
	# Kumulative Pruefung ueber die Ressourcen-Zustaendigkeit: Gleiche
	# Eingangsressourcen werden summiert, bevor gegen den Bestand geprueft
	# wird, damit doppelte Eingaenge nicht faelschlich als gedeckt gelten.
	return _ressourcen.kann_mehrfach_entnehmen(definition.inputs, lager_index)

func _inputs_entnehmen(definition: Gebaeude_Definition, lager_index: int) -> bool:
	# Atomare Entnahme aller Eingaenge: Erst kumulativ geprueft, dann gebucht.
	return _ressourcen.mehrfach_entnehmen(definition.inputs, lager_index)

func _outputs_einlagern(definition: Gebaeude_Definition, index: int) -> bool:
	if _model == null or _ressourcen == null:
		return false
	# Outputs gehen über die Erntebuchung ins Lager, das der Produktions-
	# position am nächsten liegt; keine zweite Lagerlogik.
	for output: Dictionary in definition.outputs:
		var menge := int(output.get("menge", 0))
		if menge <= 0:
			continue
		_ressourcen.ernte_position_setzen(_model.objekt_position(index))
		_ressourcen.hinzufuegen(str(output.get("ressource", "")), menge)
	return true

func _output_menge(definition: Gebaeude_Definition) -> int:
	var summe := 0
	for output: Dictionary in definition.outputs:
		summe += int(output.get("menge", 0))
	return summe

func _auf_menue_geoeffnet() -> void:
	# Menü-Gegenprüfung: Alle Gebäude-Fortschritte werden prozentual auf die
	# aktuell geltenden effektiven Zeiten skaliert (nur bei Menü-Öffnung).
	if _model == null:
		return
	for index in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition == null:
			continue
		var bau_zustand := {
			"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
			"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
			"ziel_ticks": int(_model.objekt_feld(index, "bau_ziel_ticks", definition.bauzeit_ticks)),
		}
		var bau_neu := _bau_maschine.abstimmen(bau_zustand, definition.bauzeit_ticks)
		_model.objekt_feld_setzen(index, "bau_fortschritt", int(bau_neu["fortschritt"]))
		_model.objekt_feld_setzen(index, "bau_ziel_ticks", int(bau_neu.get("ziel_ticks", definition.bauzeit_ticks)))
		var prod_zustand := {
			"phase": int(_model.objekt_feld(index, "prod_phase", 0)),
			"fortschritt": int(_model.objekt_feld(index, "prod_fortschritt", 0)),
			"ziel_ticks": int(_model.objekt_feld(index, "prod_ziel_ticks", definition.dauer_ticks)),
		}
		var prod_neu := _produktions_maschine.abstimmen(prod_zustand, definition)
		_model.objekt_feld_setzen(index, "prod_fortschritt", int(prod_neu["fortschritt"]))
		_model.objekt_feld_setzen(index, "prod_ziel_ticks", int(prod_neu.get("ziel_ticks", definition.dauer_ticks)))