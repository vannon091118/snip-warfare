extends RefCounted
class_name Welt_RissGeste
## Die sichtbare Geste des Schadens: Ein Riss-Decal liegt als neues Papier
## über das Objekt, je zwei Schlägen eine Stufe. Genau eine Verantwortung:
## Das Decal-Kind am Objekt-Knoten setzen, stufenweise wechseln oder
## entfernen. Das Muster ist das bewährte Beeren-Overlay: ein zweites Bild
## auf demselben Fuß, Datenentscheidung bleibt außen.

## Die zwei Decal-Bilder in Steigfolge der Schwere.
const RISS_BILDER: Array[String] = [
	"res://world/assets/progression/riss_leicht.svg",
	"res://world/assets/progression/riss_schwer.svg",
]

## Kategorie logik: Decal aus dem Schadens-Anteil setzen und räumen.

func risse_anwenden(knoten: Node2D, sprite: Sprite2D, schadens_anteil: float) -> void:
	# Anteil 0 rumt das Decal, die Stufen 0,34 und 0,67 wählen leicht und
	# schwer. Das Decal teilt die Höhe seines Trägers, damit es auf dem
	#selben Fuß steht; geloeschte Knoten nehmen kein neues Decal an.
	if knoten == null or not is_instance_valid(knoten) or sprite == null:
		return
	var stufe := 0
	if schadens_anteil >= 0.67:
		stufe = 2
	elif schadens_anteil >= 0.34:
		stufe = 1
	var decal := knoten.get_node_or_null("RissDecal") as Sprite2D
	if stufe == 0:
		if decal != null:
			knoten.remove_child(decal)
			decal.queue_free()
		return
	var textur: Texture2D = load(RISS_BILDER[stufe - 1])
	if decal == null:
		decal = Sprite2D.new()
		decal.name = "RissDecal"
		knoten.add_child(decal)
	decal.texture = textur
	decal.centered = true
	# Derselbe Fuß wie das Standbild: Unterkante auf dem Knoten-Ursprung.
	decal.offset = Vector2(0.0, -sprite.texture.get_height() * 0.5)
	decal.z_index = 1
