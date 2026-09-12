extends RefCounted
class_name Welt_StadiumGeste
## Die sichtbare Geste eines Stadiums-Wechsels: Der kurze Hauch, mit dem
## frisches Papier auf dem Tisch landet. Genau eine Verantwortung: Der
## Standbild-Sprite eines Objekts stoesst kurz auf und kehrt in seine
## Ruheposition zurueck. Keine Domänenlogik, keine Zeit außer der eigenen
## Tween-Laufzeit, keine zweite Zeichenstelle.

## Höhe des Aufstoßens in Pixeln und Dauer der Geste in Sekunden.
const HAUCH_HOEHE := 4.0
const DAUER := 0.3

## Kategorie logik: Ausspielen der Geste auf einem bestehenden Sprite.

func platzieren(sprite: Sprite2D) -> void:
	# Ein echter Blattwechsel verdient einen Hauch. Der Sprite kehrt exakt
	# in seine Ruheposition zurueck, damit die Tiefensortierung am Fußpunkt
	# nicht driftet. Ein laufender Hauch wird uebersteuert, nicht gestapelt.
	if sprite == null or not is_instance_valid(sprite):
		return
	var ruhe := sprite.position
	sprite.position = ruhe + Vector2(0.0, -HAUCH_HOEHE)
	var verwandlung := sprite.create_tween()
	verwandlung.tween_property(sprite, "position", ruhe, DAUER).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
