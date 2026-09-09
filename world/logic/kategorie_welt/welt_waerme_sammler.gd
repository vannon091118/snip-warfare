extends RefCounted
class_name Welt_WaermeSammler
## Spitze: Wärmequellen aus Welt-Objekten sammeln. Liest nur
## Welt_Model und reicht die Feuer-Positionen an den Einheit_Manager.

func sammeln(model: Welt_Model, stockmaenner: Einheit_Manager) -> void:
	if model == null or stockmaenner == null:
		return
	var feuer: Array[Vector2] = []
	for index in model.objekt_anzahl():
		if model.objekt_element_id(index) == "lagerfeuer":
			feuer.append(model.objekt_position(index))
	stockmaenner.waerme_quellen_aktualisieren(feuer)
