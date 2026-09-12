extends RefCounted
class_name Welt_UmsturzGeste
## Die sichtbare Geste des Fällens: Der alte Baum wirft seine Krone als
## gekipptes Papierstück und schwindet, der neue Zustand (Stumpf) steht
## bereits. Genau eine Verantwortung: Ein einmaliges Kronen-Stueck am
## Objekt-Knoten aufstoßen lassen, kippen und auslaufen. Keine Domänenlogik,
## keine Zeit außer der eigenen Tween-Laufzeit.

## Maße und Dauer des Kronen-Hauchs, grob aus der Blatthöhe des Baums.
const DAUER := 0.7
const KIPP_WINKEL := 1.15
const SCHRUMPFGRADE := 0.25

## Kategorie logik: Das Kronen-Stueck ausspielen.

func umsturz_spielen(knoten: Node2D, textur: Texture2D) -> void:
	# Die Krone ist das alte Blatt als ein eigenes Stück: Sie stoesst auf,
	# kippt zur Seite und schwindet. Der Tween kennt nur sein Kind; fehlt
	# der Knoten oder das Blatt, bleibt die Geste still.
	if knoten == null or not is_instance_valid(knoten) or textur == null:
		return
	var krone := Sprite2D.new()
	krone.name = "UmsturzKrone"
	krone.texture = textur
	krone.centered = true
	# Der Kronen-Ursprung liegt am Boden des Objekts: Von dort kippt er.
	krone.offset = Vector2(0.0, -float(textur.get_height()) * 0.5)
	krone.position = Vector2.ZERO
	krone.rotation = -0.18
	krone.z_index = 2
	knoten.add_child(krone)
	var fall := krone.create_tween()
	fall.set_parallel(true)
	fall.tween_property(krone, "rotation", KIPP_WINKEL, DAUER).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(krone, "position", Vector2(float(textur.get_height()) * 0.4, 0.0), DAUER).set_ease(Tween.EASE_IN)
	fall.tween_property(krone, "modulate:a", 0.0, DAUER).set_ease(Tween.EASE_IN)
	fall.tween_property(krone, "scale", Vector2.ONE * SCHRUMPFGRADE, DAUER).set_ease(Tween.EASE_IN)
	fall.chain().tween_callback(krone.queue_free)
