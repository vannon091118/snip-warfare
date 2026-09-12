extends RefCounted
class_name Gebaeude_Laufzeit
## Laufzeit der Gebäude: Sie tickt den Bau- und Produktionszustand jedes
## Gebäudes über die zentrale Weltzeit und führt die Aktionen aus, die die
## zwei Zustandsmaschinen anfordern. Die Zustandsübergänge rechnen
## Gebaeude_BauMaschine und Gebaeude_ProduktionsMaschine; diese Klasse
## bucht nur deren Beschlüsse: Eingänge über die Ressourcen-Zuständigkeit,
## Ausgänge über die Erntebuchung ins nächste Lager. Eigene Zahlen erfindet
## sie nicht, eigene Lagerlogik besitzt sie nicht.

## Kategorie daten: Die Verbindungen zu den eigenen Maschinen und Fremd-
## Zuständigkeiten. Das Modell wird beim Kartenwechsel ausgetauscht.
var _model: Welt_Model = null
var _ressourcen: Einheit_Ressourcen = null
var _lager: Lager_Manager = null
var _definitionen: Gebaeude_DefinitionRegistry = null
var _bau_maschine: Gebaeude_BauMaschine = null
var _produktions_maschine: Gebaeude_ProduktionsMaschine = null
var _fortschritt: Welt_FortschrittsMaschine = null
## Rückmelde-Kanäle des Managers: Meldungstexte und der Abschluss eines
## Baus. Der Manager behält seine Signale, die Laufzeit ruft sie.
var _meldung: Callable
var _fertig: Callable

func einrichten(model: Welt_Model, ressourcen: Einheit_Ressourcen, lager: Lager_Manager, definitionen: Gebaeude_DefinitionRegistry, bau_maschine: Gebaeude_BauMaschine, produktions_maschine: Gebaeude_ProduktionsMaschine, fortschritt: Welt_FortschrittsMaschine, meldung: Callable, fertig: Callable) -> void:
	_model = model
	_ressourcen = ressourcen
	_lager = lager
	_definitionen = definitionen
	_bau_maschine = bau_maschine
	_produktions_maschine = produktions_maschine
	_fortschritt = fortschritt
	_meldung = meldung
	_fertig = fertig

func model_setzen(model: Welt_Model) -> void:
	## Kartenwechsel-Handshake: Das Modell wird atomar ausgetauscht.
	_model = model

func bereit() -> bool:
	return _model != null and _ressourcen != null and _lager != null

func gebaeude_ticken(index: int, definition: Gebaeude_Definition) -> void:
	## Ein Gebäude: erst der Bau, danach nur bei abgeschlossenem Bau die
	## Produktion. Dieselbe Reihenfolge wie zuvor im Manager.
	_bau_ticken(index, definition)
	if _bau_fertig(index):
		_produktion_ticken(index, definition)

func abstimmen(index: int, definition: Gebaeude_Definition) -> void:
	## Menü-Gegenprüfung: Bau- und Produktions-Fortschritt werden auf die
	## aktuell geltenden effektiven Zeiten skaliert (nur bei Menü-Öffnung).
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

func _bau_fertig(index: int) -> bool:
	var zustand := {
		"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
	}
	return _bau_maschine.ist_fertig(zustand)

func _ist_material_vollstaendig(index: int) -> bool:
	var bedarf: Dictionary = _model.objekt_feld(index, "bedarf", {})
	if bedarf.is_empty():
		return true
	var geliefert: Dictionary = _model.objekt_feld(index, "geliefert", {})
	for ressource: String in bedarf.keys():
		var soll := int(bedarf.get(ressource, 0))
		var ist := int(geliefert.get(ressource, 0))
		if ist < soll:
			return false
	return true

func _bau_ticken(index: int, definition: Gebaeude_Definition) -> void:
	var zustand := {
		"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
	}
	if _bau_maschine.ist_fertig(zustand):
		return
	var material_voll := _ist_material_vollstaendig(index)
	var neu := _bau_maschine.tick(zustand, definition.bauzeit_ticks, material_voll)
	_model.objekt_feld_setzen(index, "bau_phase", int(neu["phase"]))
	_model.objekt_feld_setzen(index, "bau_fortschritt", int(neu["fortschritt"]))
	_model.objekt_feld_setzen(index, "bau_ziel_ticks", int(neu.get("ziel_ticks", definition.bauzeit_ticks)))
	if _bau_maschine.ist_fertig(neu):
		# Bau abgeschlossen: Produktion geht in den Wartezustand.
		var prod := _produktions_maschine.starten(Gebaeude_ProduktionsMaschine.neuer_zustand())
		_model.objekt_feld_setzen(index, "prod_phase", int(prod["phase"]))
		_model.objekt_feld_setzen(index, "prod_fortschritt", 0)
		_model.objekt_feld_setzen(index, "prod_ziel_ticks", _produktions_maschine.zeit_ticks_fuer(definition.dauer_ticks))
		_meldung.call("%s ist fertig gebaut und wartet auf Eingänge." % definition.angezeigter_name)
		# Die Progressions-Kette erfährt den Abschluss direkt: Wer dem
		# Manager eine Maschine reicht, muss sie nicht zusätzlich verdrahten;
		# das Signal bleibt für reine Beobachter wie das HUD daneben stehen.
		if _fortschritt != null:
			_fortschritt.gebaeude_fertiggestellt(definition.id)
		_fertig.call(definition.id)

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
				_meldung.call("%s beginnt zu produzieren." % definition.angezeigter_name)
			else:
				neu = _produktions_maschine.phase_erzwingen(neu, Gebaeude_ProduktionsMaschine.Phase.WARTET_EINGANG)
		"output_legen":
			if _outputs_einlagern(definition, index):
				var namen: Array[String] = []
				for output: Dictionary in definition.outputs:
					namen.append("%d %s" % [int(output.get("menge", 0)), str(output.get("ressource", ""))])
				_meldung.call("%s hat %s hergestellt und eingelagert." % [definition.angezeigter_name, ", ".join(namen)])
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
