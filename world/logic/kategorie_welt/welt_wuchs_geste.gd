extends RefCounted
class_name Welt_WuchsGeste
## Die sichtbare Geste des Wachsens: Ein Objekt atmet in seiner Stufe, statt
## in Sprüngen zu stehen. Genau eine Verantwortung: Der Standbild-Sprite
## erhält seine Stufen-Maßstab aus der echten Wachstums-Fraktion des Modells
## und einen minimalen Atem um den Stufen-Wert, damit die Kette zwischen
## den Blättern sichtbar weiterläuft. Keine Domänenlogik, keine zweite Zeit.

## Atem-Amplitude um den Stufen-Maßstab und Fußanker des Sprites.
const ATEM := 0.04

## Kategorie logik: Maßstab aus der echten Wachstums-Fraktion.

func wuchs_anwenden(sprite: Sprite2D, fraktion: float) -> void:
	# Der Stufen-Maßstab folgt der Fraktion 0..1 zwischen 0,8 und 1,0, ein
	# kleiner Atem liegt darueber. Der Offset des Sprites bleibt unangetastet:
	# Er wächst aus dem Fußpunkt, nicht aus der Mitte, damit der Fuß steht.
	if sprite == null or not is_instance_valid(sprite):
		return
	var stufe := 0.8 + 0.2 * clampf(fraktion, 0.0, 1.0)
	var atem := ATEM * sin(clampf(fraktion, 0.0, 1.0) * TAU)
	sprite.scale = Vector2.ONE * (stufe + atem)
