extends RefCounted
class_name Welt_TierPlatzierer
## Spitze: Tiere aus Welt-Objekten beim Tier_Manager platzieren.
## Liest nur Welt_Model und Welt_Registry, schreibt nur in Tier_Manager.
## Keine Lager-, keine Job-, keine Kamera-Logik.

func platzieren(model: Welt_Model, registry: Welt_Registry, tiere: Tier_Manager) -> void:
	if model == null or registry == null or tiere == null:
		return
	for index in model.objekt_anzahl():
		var element_id := model.objekt_element_id(index)
		var eintrag := registry.finde_objekt(element_id)
		if eintrag == null or eintrag.typ != &"bewegt":
			continue
		tiere.tier_platzieren(element_id, model.objekt_position(index))
