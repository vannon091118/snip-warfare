extends RefCounted
class_name Welt_RaumAnalyser
## Analysiert einen Raum anhand von Möbel-Tags innerhalb von Wänden (felswand).
## Nutzt Flood-Fill über das Welt_ObjektGitter, wobei felswand-Objekte als
## Blockaden gelten. Gibt die Menge aller eindeutigen Tags der Möbel im Raum
## zurück.

var _welt_modell: Welt_Model
var _objekt_gitter: Welt_ObjektGitter
var _moebel_tags: Dictionary

func _init(welt_modell: Welt_Model, objekt_gitter: Welt_ObjektGitter) -> void:
	_welt_modell = welt_modell
	_objekt_gitter = objekt_gitter
	_moebel_tags = _lade_moebel_tags()

func analysiere(start_position: Vector2) -> Array[String]:
	## Führt Flood-Fill von der Startposition aus und sammelt alle Möbel-Tags.
	var besucht: Dictionary = {} # Schlüssel: "x:y" -> true
	var zu_besuchen: Array[Vector2i] = []
	var tags_set: Array[String] = []

	var start_tile := _welt_pos_to_tile(start_position)
	zu_besuchen.append(start_tile)

	while zu_besuchen.size() > 0:
		var tile := zu_besuchen.pop_back()
		var key := "%d:%d" % [tile.x, tile.y]
		if besucht.has(key):
			continue
		besucht[key] = true

		# Prüfe, ob die Tile durch eine Wand blockiert ist
		if _ist_wand_tile(tile):
			continue

		# Sammle Tags von Möbeln auf dieser Tile
		var objekte_auf_tile := _objekte_auf_tile(tile)
		for obj_index in objekte_auf_tile:
			var element_id := _welt_modell.objekt_element_id(obj_index)
			if element_id == "":
				continue
			var tags := _moebel_tags.get(element_id, [])
			for tag in tags:
				if not tags_set.has(tag):
					tags_set.append(tag)

		# Nachbarschaftstiles hinzufügen (4- oder 8-richtungsbasiert? Wir nutzen 4)
		for versatz: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nachbar := tile + versatz
			var nachbar_key := "%d:%d" % [nachbar.x, nachbar.y]
			if not besucht.has(nachbar_key) and not _ist_wand_tile(nachbar):
				zu_besuchen.append(nachbar)

	return tags_set

func _welt_pos_to_tile(position: Vector2) -> Vector2i:
	var tile_size := float(_welt_modell.kachel_groesse)
	return Vector2i(
		floori(position.x / tile_size),
		floori(position.y / tile_size)
	)

func _ist_wand_tile(tile: Vector2i) -> bool:
	## Prüft, ob irgendein felswand-Objekt diese Tile überlappt.
	var tile_size := float(_welt_modell.kachel_groesse)
	var tile_rect := Rect2(
		tile.x * tile_size,
		tile.y * tile_size,
		tile_size,
		tile_size
	)
	for i in _welt_modell.objekt_anzahl():
		if _welt_modell.objekt_element_id(i) == "felswand":
			var pos := _welt_modell.objekt_position(i)
			# Wir benötigen die Größe des objekts. Aus Objekt_Basis könnten wir
			# anzeige_breite/hoehe holen, aber dafür müssten wir die Registry
			# bemühen. Als Approximation nutzen wir einen festen Wert von 96x96
			# (wie in der SVG). Das reicht für die Erkennung von Blockaden.
			var obj_rect := Rect2(pos.x - 48.0, pos.y - 48.0, 96.0, 96.0) # zentriert
			if tile_rect.intersects(obj_rect):
				return true
	return false

func _objekte_auf_tile(tile: Vector2i) -> Array[int]:
	var tile_size := float(_welt_modell.kachel_groesse)
	var tile_rect := Rect2(
		tile.x * tile_size,
		tile.y * tile_size,
		tile_size,
		tile_size
	)
	var kandidaten := _objekt_gitter.kandidaten_in(tile_rect)
	var ergebnis: Array[int] = []
	for obj_index in kandidaten:
		var pos := _welt_modell.objekt_position(obj_index)
		# Prüfe, ob das Objekt tatsächlich innerhalb der Tile liegt
		# (einfachere Annahme: Objekt-Punkt liegt in Tile)
		var obj_tile := _welt_pos_to_tile(pos)
		if obj_tile == tile:
			ergebnis.append(obj_index)
	return ergebnis

func _lade_moebel_tags() -> Dictionary:
	var tags_dict := Dictionary.new()
	var moebel_pfad := "res://game/data/möbel.json"
	var datei := FileAccess.open(moebel_pfad, FileAccess.READ)
	if datei == null:
		push_warning("Möbel-JSON nicht gefunden: %s" % moebel_pfad)
		return tags_dict
	var text := datei.get_as_text()
	datei.close()
	var daten := JSON.parse_string(text)
	if typeof(daten) != TYPE_ARRAY:
		push_warning("Möbel-JSON hat ungueltiges Format")
		return tags_dict
	for eintrag in daten as Array:
		if typeof(eintrag) == TYPE_DICTIONARY:
			var eid := str(eintrag.get("id", ""))
			var tags := eintrag.get("tags", [])
			if typeof(tags) == TYPE_ARRAY:
				var str_tags: Array[String] = []
				for tag in tags:
					str_tags.append(str(tag))
				tags_dict[eid] = str_tags
	return tags_dict
