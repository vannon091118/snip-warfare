extends RefCounted
class_name Tier_DarstellerFabrik
## Fabrik der Tier-Darsteller: Sie hält die Darsteller-Ebene und erzeugt die
## Knoten eines Tieres. Das Regelwerk kommt bei jedem Ruf mit, damit die
## Fabrik keinen Zustand trägt, der vor dem ersten Rahmen fehlen kann; ohne
## erzeugten Knoten bleibt ein Tier ein reiner Logik-Eintrag. Die Fabrik
## kennt keinen Takt und keine Regel.

var _ebene: Node2D = null

func ebene_anlegen(halter: Node2D) -> void:
	# Der Anker wird faul angelegt, damit Platzierung auch ohne fertigen
	# Szenen-Kontext (Headless-Prüfungen) sicher funktioniert.
	if _ebene != null:
		return
	_ebene = Node2D.new()
	_ebene.name = "TierDarstellerEbene"
	_ebene.y_sort_enabled = true
	halter.add_child(_ebene)

func darsteller_erzeugen(halter: Node2D, tier_id: String, verhalten: Tier_Registry, status: Tier_Status, welt_position: Vector2) -> Tier_Darsteller:
	## Einer tritt an: Darsteller bauen und an die Ebene hängen. Das Regelwerk
	## reicht der Manager herein, weil er es besitzt.
	ebene_anlegen(halter)
	var darsteller := Tier_Darsteller.new()
	darsteller.einrichten(tier_id, verhalten, status)
	darsteller.position = welt_position
	_ebene.add_child(darsteller)
	return darsteller

func darsteller_freigeben(tiere: Array[Dictionary]) -> void:
	# Ein bereits freigegebener Knoten darf nicht angefasst werden; erst
	# prüfen, dann typisieren.
	for tier: Dictionary in tiere:
		var knoten: Variant = tier.get("darsteller")
		if knoten != null and is_instance_valid(knoten):
			(knoten as Node).queue_free()
