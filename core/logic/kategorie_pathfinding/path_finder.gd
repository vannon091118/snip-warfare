extends RefCounted
class_name Kern_PathFinder
## Zustandsmaschine des Wegfindens: A-Stern über die Knoten des Welt-Rasters.
## Sie kennt nur Knoten und Kosten; Kollisionsboxen, Weg-Boni und Unebenheits-
## Mali liest sie aus dem Knoten, die Werte kommen aus der Pfad-Registry.
## Deterministisch: gleicher Start, gleiches Ziel, gleicher Zustand, gleicher Weg.

## Kategorie daten: offene und geschlossene Mengen des aktuellen Laufs.
var _offen: Array[Kern_PathKnoten] = []
var _kosten_bis: Dictionary = {}
var _herkunft: Dictionary = {}

## Kategorie logik: A-Stern über die Knoten.

func weg_suchen(knoten_nach_position: Dictionary, start: Vector2i, ziel: Vector2i) -> Array[Vector2i]:
	_offen.clear()
	_kosten_bis.clear()
	_herkunft.clear()
	var start_knoten: Kern_PathKnoten = knoten_nach_position.get(start)
	var ziel_knoten: Kern_PathKnoten = knoten_nach_position.get(ziel)
	if start_knoten == null or ziel_knoten == null:
		return []
	if start_knoten.gesperrt or ziel_knoten.gesperrt:
		return []
	_kosten_bis[start] = 0.0
	_offen.append(start_knoten)
	while not _offen.is_empty():
		var aktueller := _billigster_offener(ziel)
		if aktueller == null:
			return []
		if aktueller.x == ziel.x and aktueller.y == ziel.y:
			return _weg_rueckverfolgen(ziel)
		_offen.erase(aktueller)
		var hier := Vector2i(aktueller.x, aktueller.y)
		for nachbar_pos: Vector2i in _nachbarn_von(hier, knoten_nach_position):
			var nachbar: Kern_PathKnoten = knoten_nach_position[nachbar_pos]
			if nachbar.gesperrt:
				continue
			var schritt := diagonalkosten(hier, nachbar_pos)
			var neu := float(_kosten_bis[hier]) + nachbar.effektive_kosten() * schritt
			var bekannt: float = _kosten_bis.get(nachbar_pos, INF)
			if neu < bekannt:
				_kosten_bis[nachbar_pos] = neu
				_herkunft[nachbar_pos] = hier
				if not _offen.has(nachbar):
					_offen.append(nachbar)
	return []

func _billigster_offener(ziel: Vector2i) -> Kern_PathKnoten:
	# Wählt den offenen Knoten mit der kleinsten geschätzten Gesamtkosten.
	var bester: Kern_PathKnoten = null
	var beste_schaetzung := INF
	for knoten: Kern_PathKnoten in _offen:
		var pos := Vector2i(knoten.x, knoten.y)
		var schaetzung := float(_kosten_bis.get(pos, INF)) + heuristik(pos, ziel)
		if schaetzung < beste_schaetzung:
			beste_schaetzung = schaetzung
			bester = knoten
	return bester

func _nachbarn_von(pos: Vector2i, knoten_nach_position: Dictionary) -> Array[Vector2i]:
	var nachbarn: Array[Vector2i] = []
	for versatz: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		var ziel_pos := pos + versatz
		if knoten_nach_position.has(ziel_pos):
			nachbarn.append(ziel_pos)
	return nachbarn

func _weg_rueckverfolgen(ziel: Vector2i) -> Array[Vector2i]:
	var weg: Array[Vector2i] = []
	var aktuell: Variant = ziel
	while aktuell != null and _herkunft.has(aktuell):
		weg.append(aktuell)
		aktuell = _herkunft[aktuell]
	if aktuell is Vector2i:
		weg.append(aktuell)
	weg.reverse()
	return weg

static func heuristik(von: Vector2i, nach: Vector2i) -> float:
	# Oktile-Distanz: deterministisch, zulässig für A-Stern.
	var dx := absi(von.x - nach.x)
	var dy := absi(von.y - nach.y)
	return float(maxi(dx, dy)) + 0.4142 * float(mini(dx, dy))

static func diagonalkosten(von: Vector2i, nach: Vector2i) -> float:
	# Diagonalschritte kosten Wurzel 2, gerade Schritte kosten 1.
	if von.x != nach.x and von.y != nach.y:
		return 1.4142
	return 1.0
