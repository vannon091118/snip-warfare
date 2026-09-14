extends RefCounted
class_name Gebaeude_MoebelBedarf
## Einziger Leser des Datenvertrags benötigt_tags aus world/data/gebaeude.json.
## Er beantwortet genau eine Frage: Stehen alle verlangten Objekt-Tags im
## Umkreis des Bauplatzes. Er bucht nichts, tickt nichts und kennt keine
## Szene. Ohne ihn waere der Vertrag tot: Möbel liessen sich setzen, der Bau
## wuerde trotzdem nie freigegeben, weil niemand die Tags liest.

## Kategorie daten: Umkreis, in dem ein Objekt als "am Bauplatz" gilt.
var naehe: float = 192.0

## Kategorie logik: Modell und Registry als einzige Wahrheitsquellen.
var _model: Welt_Model = null
var _registry: Welt_Registry = null

func einrichten(model: Welt_Model, registry: Welt_Registry) -> void:
	_model = model
	_registry = registry

func model_setzen(model: Welt_Model) -> void:
	## Kartenwechsel-Handshake: nur das Modell wird getauscht.
	_model = model

func fehlende_tags(definition: Gebaeude_Definition, welt_position: Vector2) -> Array[String]:
	## Leere Liste heisst frei. Ohne Definition oder ohne Bedarf ist der Bau
	## nicht durch Möbel gesperrt; die Prüfung erfindet keinen Bedarf.
	var fehlend: Array[String] = []
	if definition == null or _model == null:
		return fehlend
	if definition.benoetigt_tags.is_empty():
		return fehlend
	var vorhanden := _tags_am_platz(welt_position)
	for tag: String in definition.benoetigt_tags:
		if not vorhanden.has(tag):
			fehlend.append(tag)
	return fehlend

func erfuellt(definition: Gebaeude_Definition, welt_position: Vector2) -> Dictionary:
	## Antwort für das Bau-Gate: entweder frei oder mit den fehlenden Tags.
	var fehlend := fehlende_tags(definition, welt_position)
	if fehlend.is_empty():
		return {"ok": true, "fehlend": fehlend}
	fehlend.sort()
	return {
		"ok": false,
		"grund": "Moebel fehlt: %s" % ", ".join(fehlend),
		"fehlend": fehlend,
	}

func _tags_am_platz(welt_position: Vector2) -> Dictionary:
	var vorhanden: Dictionary = {}
	for index in _model.objekt_anzahl():
		if _model.objekt_position(index).distance_to(welt_position) > naehe:
			continue
		for tag: String in _tags_von(index):
			vorhanden[tag] = true
	return vorhanden

func _tags_von(index: int) -> Array[String]:
	## Die Tags eines Objekts kommen ausschliesslich aus der Registry, nie
	## aus einer zweiten Tabelle in dieser Klasse.
	var leer: Array[String] = []
	if _registry == null:
		return leer
	return _registry.ziel_tags_fuer(_model.objekt_element_id(index))
