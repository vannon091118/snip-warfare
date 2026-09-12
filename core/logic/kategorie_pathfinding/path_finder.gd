extends RefCounted
class_name Kern_PathFinder
## Zustandsmaschine des Wegfindens: Sie delegiert die Suche an das
## AStarGrid2D des Netzes, der deterministische Oktile-Stern der Engine
## rechnet, das Netz trägt Sperren und Kosten aus der Pfad-Registry.
## Determinismus bleibt Pflicht: gleicher Start, gleiches Ziel, gleicher
## Zustand, gleicher Weg.

## Kategorie logik: Suche über das Engine-Raster des Netzes.

func weg_suchen(netz: Kern_PathNetz, start: Vector2i, ziel: Vector2i) -> Array[Vector2i]:
	# Das Netz trägt Raster, Sperren und Kosten; der Finder reicht nur
	# die Anfrage durch und übersetzt das Ergebnis in Zellen.
	if netz == null:
		return []
	if not netz.ist_verbindbar(start, ziel):
		return []
	var zellen: Array[Vector2i] = netz.raster.get_id_path(start, ziel)
	var weg: Array[Vector2i] = []
	for zelle: Vector2i in zellen:
		weg.append(zelle)
	return weg

static func heuristik(von: Vector2i, nach: Vector2i) -> float:
	# Oktile-Distanz als bewusster Vertrag der Planung; die Engine nutzt
	# dieselbe Schätzung als Standard über default_compute_heuristic.
	var dx := absi(von.x - nach.x)
	var dy := absi(von.y - nach.y)
	return float(maxi(dx, dy)) + 0.4142 * float(mini(dx, dy))

static func diagonalkosten(von: Vector2i, nach: Vector2i) -> float:
	# Diagonalschritte kosten den Diagonal-Faktor, gerade Schritte kosten 1.
	if von.x != nach.x and von.y != nach.y:
		return 1.4142
	return 1.0
