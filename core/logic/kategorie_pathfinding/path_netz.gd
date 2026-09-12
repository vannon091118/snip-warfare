extends RefCounted
class_name Kern_PathNetz
## Netz aus begehbaren Knoten über das Welt-Raster: Das AStarGrid2D der
## Engine ist die einzige Weg-Wahrheit, die Knoten-Datenklasse spiegelt
## die Kachel-Eigenschaften je Zelle für Abfragen und Kosten. Die zwei
## Quellen bleiben dieselben: das Welt_Model liefert die Kachel-IDs, die
## Kern_PathRegistry liefert Bonus, Malus, Sperrung und Diagonal-Faktor.

## Kategorie daten: das Engine-Raster und der Knoten-Spiegel.
var raster := AStarGrid2D.new()
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
	raster.region = Rect2i(0, 0, breite, hoehe)
	raster.cell_size = Vector2(float(model.kachel_groesse), float(model.kachel_groesse))
	raster.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	raster.diagonal_weight = registry.diagonal_faktor()
	raster.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	raster.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	raster.update()
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
			raster.set_point_weight_scale(Vector2i(x, y), knoten.effektive_kosten())
			if knoten.gesperrt:
				raster.set_point_solid(Vector2i(x, y), true)
	# Kollisionsboxen der Weltobjekte sperren ihre Kacheln, ohne sie zu löschen.
	for position: Vector2 in kollisions_positionen:
		var kante := float(model.kachel_groesse) if model != null else float(Welt_Model.KACHEL_GROESSE)
		var kachel := Vector2i(int(position.x / kante), int(position.y / kante))
		var kollision_knoten: Kern_PathKnoten = knoten_nach_position.get(kachel)
		if kollision_knoten != null:
			kollision_knoten.gesperrt = true
			raster.set_point_solid(kachel, true)

func knoten_bei(pos: Vector2i) -> Kern_PathKnoten:
	return knoten_nach_position.get(pos)

func zelle_ent_sperren(pos: Vector2i, gesperrt_neu: bool) -> void:
	# Ziel-Spiegel: Das Arbeitsobjekt steht auf einer gesperrten Kachel;
	# die Planung hebt die Sperre nur für die Suche und meldet sie hier
	# zurück, damit Raster und Knoten-Spiegel dieselbe Wahrheit tragen.
	var knoten: Kern_PathKnoten = knoten_nach_position.get(pos)
	if knoten != null:
		knoten.gesperrt = gesperrt_neu
	raster.set_point_solid(pos, gesperrt_neu)

func ist_verbindbar(start: Vector2i, ziel: Vector2i) -> bool:
	return raster.is_in_bounds(start.x, start.y) and raster.is_in_bounds(ziel.x, ziel.y) \
			and not raster.is_point_solid(start) and not raster.is_point_solid(ziel)
