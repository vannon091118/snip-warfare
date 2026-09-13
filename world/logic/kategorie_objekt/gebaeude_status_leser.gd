extends RefCounted
class_name Gebaeude_StatusLeser
## Lesesaal der Gebäude-Zeilen: Pro Gebäude eine kompakte Zeile für das HUD.
## Reine Beobachtung, kein Tick, kein Schreiben. Die Anteile rechnen die
## beiden Zustandsmaschinen; diese Klasse formt nur Text.

var _model: Welt_Model = null
var _definitionen: Gebaeude_DefinitionRegistry = null
var _bau_maschine: Gebaeude_BauMaschine = null
var _produktions_maschine: Gebaeude_ProduktionsMaschine = null

func einrichten(model: Welt_Model, definitionen: Gebaeude_DefinitionRegistry, bau_maschine: Gebaeude_BauMaschine, produktions_maschine: Gebaeude_ProduktionsMaschine) -> void:
	_model = model
	_definitionen = definitionen
	_bau_maschine = bau_maschine
	_produktions_maschine = produktions_maschine

func model_setzen(model: Welt_Model) -> void:
	_model = model

func zeilen() -> Array[String]:
	var zeilen_sammlung: Array[String] = []
	if _model == null:
		return zeilen_sammlung
	for index in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var definition := _definitionen.definition_fuer(gebaeude_id)
		if definition == null:
			continue
		if not _bau_maschine.ist_fertig(_bau_zustand(index)):
			zeilen_sammlung.append(_bau_zeile(index, definition))
			continue
		zeilen_sammlung.append(_produktions_zeile(index, definition))
	return zeilen_sammlung

func _bau_zustand(index: int) -> Dictionary:
	return {
		"phase": int(_model.objekt_feld(index, "bau_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "bau_fortschritt", 0)),
	}

func _prod_zustand(index: int) -> Dictionary:
	return {
		"phase": int(_model.objekt_feld(index, "prod_phase", 0)),
		"fortschritt": int(_model.objekt_feld(index, "prod_fortschritt", 0)),
	}

func _bau_zeile(index: int, definition: Gebaeude_Definition) -> String:
	var zustand := _bau_zustand(index)
	var anteil := int(_bau_maschine.fortschritt_anteil(zustand, definition.bauzeit_ticks) * 100.0)
	return "%s: %s %d%%" % [definition.angezeigter_name, _bau_maschine.phase_name(zustand), anteil]

func _produktions_zeile(index: int, definition: Gebaeude_Definition) -> String:
	var zustand := _prod_zustand(index)
	var phase_text := _produktions_maschine.phase_name(zustand)
	if int(zustand["phase"]) == Gebaeude_ProduktionsMaschine.Phase.LAEUFT:
		var anteil := int(_produktions_maschine.fortschritt_anteil(zustand, definition.dauer_ticks) * 100.0)
		return "%s: %s %d%%" % [definition.angezeigter_name, phase_text, anteil]
	return "%s: %s" % [definition.angezeigter_name, phase_text]
