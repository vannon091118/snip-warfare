extends RefCounted
class_name Kern_PathNetz
## Netz aus begehbaren Knoten über das Welt-Raster. Es verbindet die zwei
## Quellen: das Welt_Model liefert die Kachel-IDs, die Kern_PathRegistry
## liefert Bonus, Malus und Sperrung. Es hält keine Logik jenseits des Aufbaus
## und wird von der Szene an den Wegfinder gereicht.

## Kategorie daten: alle Knoten nach Rasterposition.
var knoten_nach_position: Dictionary = {}
var breite: int = 0
var hoehe: int = 0

## Kategorie logik: Aufbau aus Modell und Registry, Kollisionsanreicherung.

func aufbauen(model: Welt_Model, registry: Kern_PathRegistry, kollisions_positionen: Array[Vector2]) -> void:
	knoten_nach_position.clear()
	if model == null or registry == null:
		return
	breite = model.raster_breite
	hoehe = model.raster_hoehe
	for y in hoehe:
		for x in breite:
			var kachel_id := model.fliese(x, y)
			var knoten := Kern_PathKnoten.new()
			knoten.x = x
			knoten.y = y
			knoten.kachel_id = kachel_id
			knoten.gesperrt = registry.ist_gesperrt(kachel_id)
			knoten.weg_bonus = registry.weg_bonus_fuer(kachel_id)
			knoten.ebenen_malus = registry.ebenen_malus_fuer(kachel_id)
			knoten_nach_position[Vector2i(x, y)] = knoten
	# Kollisionsboxen der Weltobjekte sperren ihre Kacheln, ohne sie zu löschen.
	for position: Vector2 in kollisions_positionen:
		var kante := float(model.kachel_groesse) if model != null else float(Welt_Model.KACHEL_GROESSE)
		var kachel := Vector2i(int(position.x / kante), int(position.y / kante))
		var kollision_knoten: Kern_PathKnoten = knoten_nach_position.get(kachel)
		if kollision_knoten != null:
			kollision_knoten.gesperrt = true

func knoten_bei(pos: Vector2i) -> Kern_PathKnoten:
	return knoten_nach_position.get(pos)
