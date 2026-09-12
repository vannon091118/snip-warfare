extends RefCounted
class_name Welt_WaermeSammler
## Spitze: Wärmequellen aus Welt-Objekten sammeln. Liest nur
## Welt_Model und reicht die Feuer-Positionen an den Einheit_Manager.
## Berechnet zusätzlich den aggregierten Wärme-Wert für den Shader.

func sammeln(model: Welt_Model, stockmaenner: Einheit_Manager, waerme_overlay: CanvasLayer = null) -> void:
	if model == null or stockmaenner == null:
		return
	var feuer: Array[Vector2] = []
	for index in model.objekt_anzahl():
		if model.objekt_element_id(index) == "lagerfeuer":
			feuer.append(model.objekt_position(index))
	stockmaenner.waerme_quellen_aktualisieren(feuer)
	# Aggregierter Wärme-Wert für Fullscreen-Shader: Maximum der Feuer-Beiträge
	# am Bildschirmzentrum als Proxy. Ohne Feuer bleibt Wert 0.
	if waerme_overlay != null and feuer.size() > 0:
		var kachel_groesse := float(Welt_Model.KACHEL_GROESSE)
		var max_wert: float = 0.0
		var bildschirm_mitte := Vector2(model.groesse()) * kachel_groesse * 0.5
		for quelle in feuer:
			var abstand_kacheln := bildschirm_mitte.distance_to(quelle) / kachel_groesse
			if abstand_kacheln <= 5.0:
				var beitrag := 1.0 * (1.0 - abstand_kacheln / 5.0)
				if quelle.distance_to(bildschirm_mitte) < kachel_groesse * 0.5:
					beitrag += 0.4
				max_wert = maxf(max_wert, beitrag)
		max_wert = clampf(max_wert, 0.0, 1.0)
		var material := waerme_overlay.get_node_or_null("WaermeRect")
		if material != null and material.material is ShaderMaterial:
			(material.material as ShaderMaterial).set_shader_parameter("waerme_wert", max_wert)
