extends RefCounted
class_name Gebaeude_BauplatzPruefer
## Einzige Prüfstelle für Bauplatz und Freigabe: Sie fragt das Weltmodell,
## nie eine zweite Wahrheit, und beantwortet genau zwei Fragen. Ist die
## Kachel dieses Bauplatzes frei, und sind die Voraussetzungen erfüllt.
## Sie bucht nichts und tickt nichts; der Manager reicht nur durch.

## Kategorie daten: Modell und Definitionsquelle.
var _model: Welt_Model = null
var _definitionen := Gebaeude_DefinitionRegistry.new()
## Möbel-Bedarf: eigener Leser des Datenvertrags benötigt_tags.
var _moebelbedarf := Gebaeude_MoebelBedarf.new()

func einrichten(model: Welt_Model, definitionen: Gebaeude_DefinitionRegistry, registry: Welt_Registry = null) -> void:
	_model = model
	_definitionen = definitionen
	_moebelbedarf.einrichten(model, registry)

func model_setzen(model: Welt_Model) -> void:
	## Kartenwechsel-Handshake: Das Modell wird atomar ausgetauscht.
	_model = model
	_moebelbedarf.model_setzen(model)

func moebelbedarf_erfuellt(gebaeude_id: String, welt_position: Vector2) -> Dictionary:
	## Zweite Freigabe-Frage des Bau-Gates: Stehen die verlangten Möbel-Tags
	## im Umkreis. Die Antwort kommt aus dem eigenen Leser, nie aus dieser
	## Prüfstelle selbst.
	var definition := _definitionen.definition_fuer(gebaeude_id)
	if definition == null:
		return {"ok": false, "grund": "unbekanntes Gebaeude"}
	return _moebelbedarf.erfuellt(definition, welt_position)

func voraussetzung_erfuellt(gebaeude_id: String) -> Dictionary:
	## Freigabe-Voraussetzungen aus der Definition: Jedes Gebäude kann andere
	## Gebäude verlangen; unbekannte Voraussetzungen zählen nur, wenn sie als
	## gebaute Objekte fehlen.
	var definition := _definitionen.definition_fuer(gebaeude_id)
	if definition == null:
		return {"ok": false, "grund": "unbekanntes Gebaeude"}
	for voraussetzung: String in definition.voraussetzungen:
		if not _existiert_im_modell(voraussetzung):
			return {"ok": false, "grund": "braucht zuerst: %s" % voraussetzung}
	return {"ok": true}

func bauplatz_frei(welt_position: Vector2, definition: Gebaeude_Definition) -> bool:
	## Ein Bauplatz ist frei, solange kein anderes Gebäude dieselbe Kachel
	## belegt. Die Kachelkante kommt aus dem Modell, nie aus einer zweiten Zahl.
	if _model == null or definition == null or not definition.belegt_kachel:
		return true
	var kante := maxi(_model.kachel_groesse, 1)
	var ziel_kachel := _kachel_von(welt_position, kante)
	for index in _model.objekt_anzahl():
		var andere_id := str(_model.objekt_feld(index, "gebaeude_id", ""))
		if andere_id == "":
			continue
		var andere_definition := _definitionen.definition_fuer(andere_id)
		if andere_definition == null or not andere_definition.belegt_kachel:
			continue
		if _kachel_von(_model.objekt_position(index), kante) == ziel_kachel:
			return false
	return true

func _kachel_von(welt_position: Vector2, kante: int) -> Vector2i:
	return Vector2i(int(welt_position.x / float(kante)), int(welt_position.y / float(kante)))

func _existiert_im_modell(gebaeude_id: String) -> bool:
	if _model == null:
		return false
	for index in _model.objekt_anzahl():
		if str(_model.objekt_feld(index, "gebaeude_id", "")) == gebaeude_id:
			return true
	return false
