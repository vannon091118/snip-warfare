extends RefCounted
class_name Welt_RaumAnalyser
## Fassade der Raumerkennung: Dünner Kompatibilitäts-Adapter um Welt_RaumErkenner.
## Wer nach Möbel-Tags fragte, ruft weiter analysiere(position); intern läuft
## derselbe Erkenner wie die Fortschritts- und Lager-Logik über die echten
## Wände (wand_holz, wand_stein) und Türen. Kein direkter Bus, keine zweite
## Wahrheit. Die Details liegen in Welt_RaumErkenner, die Domäne hier nur
## als benanntes Einfallstor.

var _welt_modell: Welt_Model
var _objekt_gitter: Welt_ObjektGitter
var _moebel_tags: Dictionary
var _erkenner := Welt_RaumErkenner.new()

func _init(welt_modell: Welt_Model, objekt_gitter: Welt_ObjektGitter, moebel_registry: Objekt_MoebelRegistry = null) -> void:
	_welt_modell = welt_modell
	_objekt_gitter = objekt_gitter
	_moebel_tags = _lade_moebel_tags(moebel_registry)

func analysiere(start_position: Vector2) -> Array[String]:
	if _welt_modell == null:
		return []
	var raum := _erkenner.raum_an_position(start_position, _welt_modell)
	if raum == null:
		return []
	# In diesem Raum stehende Möbel: ihre Tags als Schnittmenge der Quelle.
	var kante := float(maxi(_welt_modell.kachel_groesse, 1))
	var ergebnis: Array[String] = []
	for index in _welt_modell.objekt_anzahl():
		var element_id := _welt_modell.objekt_element_id(index)
		if element_id == "":
			continue
		var tags := _moebel_tags.get(element_id, null)
		if tags == null:
			continue
		var position := _welt_modell.objekt_position(index)
		var kachel := Vector2i(floori(position.x / kante), floori(position.y / kante))
		if raum.enthaelt_kachel(kachel):
			for tag in tags as Array:
				if not ergebnis.has(str(tag)):
					ergebnis.append(str(tag))
	return ergebnis

func _lade_moebel_tags(moebel_registry: Objekt_MoebelRegistry) -> Dictionary:
	var tags_dict := Dictionary.new()
	if moebel_registry == null:
		return tags_dict
	for moebel_objekt: Objekt_Basis in moebel_registry.eintraege:
		if moebel_objekt == null:
			continue
		var str_tags: Array[String] = []
		for tag: String in moebel_objekt.ziel_tags:
			str_tags.append(tag)
		tags_dict[moebel_objekt.id] = str_tags
	return tags_dict
