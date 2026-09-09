extends RefCounted
class_name Welt_LagerFabrik
## Spitze: Lager aus Welt-Objekten anlegen. Liest nur Welt_Model
## und schreibt nur in Lager_Manager. Keine Einheiten-, keine
## Renderer-Logik.

func anlegen_aus_welt(model: Welt_Model, lager: Lager_Manager, fallback_position: Vector2) -> void:
	if model == null or lager == null:
		return
	for index in model.objekt_anzahl():
		var element_id := model.objekt_element_id(index)
		var welt_pos := model.objekt_position(index)
		if element_id == "haus":
			lager.lager_anlegen("kleines_lager", welt_pos)
		elif element_id == "haus_gross":
			lager.lager_anlegen("grosses_lager", welt_pos)
	if lager.lager_zahl() == 0:
		lager.lager_anlegen("kleines_lager", fallback_position)
