extends RefCounted
class_name Welt_GeneratorFelsmassive
## Deterministischer Landschaftsgenerator fuer Felsmassive und Klippenzuege.

## Strukturiert zusammenhaengende Felsformationen mit Kacheln des Typs fels
## und umschliessenden Geroellzonen und platziert dort natuerliche Bergbauelemente
## wie Berge, Felswaende und glitzernde Erzadern.

const KACHEL_FELS := "fels"
const KACHEL_GEROELL := "geroell"
const KACHEL_WASSER := "wasser"

func erzeugen(model: Welt_Model, biom_id: String, zufall: Kern_Zufall) -> void:
	if model == null or zufall == null:
		return
	var breite := model.raster_breite
	var hoehe := model.raster_hoehe
	if breite <= 4 or hoehe <= 4:
		return
	
	# Anzahl Massiv-Zentren (hoeher in Tundra/Steppe, normal im gemaessigten Biom)
	var zentren_basis := 2 if biom_id == "gemaaessigt" else 3
	var anzahl := zentren_basis + int(zufall.naechste_zahl() % 2)
	
	var fels_kacheln: Array[Vector2i] = []
	
	for i in anzahl:
		var zx := 4 + int(zufall.naechste_zahl() % (breite - 8))
		var zy := 4 + int(zufall.naechste_zahl() % (hoehe - 8))
		# Wasser nicht ueberbauen
		if model.fliese(zx, zy) == KACHEL_WASSER:
			continue
		
		var radius := 1.8 + float(zufall.naechste_zahl() % 15) / 10.0
		var r_int := ceili(radius)
		
		for dy in range(-r_int, r_int + 1):
			for dx in range(-r_int, r_int + 1):
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					var fx := zx + dx
					var fy := zy + dy
					if fx >= 0 and fx < breite and fy >= 0 and fy < hoehe:
						if model.fliese(fx, fy) != KACHEL_WASSER:
							model.fliese_setzen(fx, fy, KACHEL_FELS)
							var pos := Vector2i(fx, fy)
							if not fels_kacheln.has(pos):
								fels_kacheln.append(pos)
	
	# Geroellsaum um alle Felskacheln
	_geroellsaum_bilden(model, breite, hoehe, fels_kacheln)
	
	# Gezielt Bergbauelemente und Felsformationen platzieren
	_bergbau_elemente_platzieren(model, fels_kacheln, zufall)

func _geroellsaum_bilden(model: Welt_Model, breite: int, hoehe: int, fels_kacheln: Array[Vector2i]) -> void:
	var geroell_kandidaten: Array[Vector2i] = []
	for pos in fels_kacheln:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = pos.x + dx
				var ny: int = pos.y + dy
				if nx >= 0 and nx < breite and ny >= 0 and ny < hoehe:
					var fliese: String = model.fliese(nx, ny)
					if fliese != KACHEL_FELS and fliese != KACHEL_WASSER:
						var npos := Vector2i(nx, ny)
						if not geroell_kandidaten.has(npos):
							geroell_kandidaten.append(npos)
	
	for gpos in geroell_kandidaten:
		model.fliese_setzen(gpos.x, gpos.y, KACHEL_GEROELL)

func _bergbau_elemente_platzieren(model: Welt_Model, fels_kacheln: Array[Vector2i], zufall: Kern_Zufall) -> void:
	if fels_kacheln.is_empty():
		return
	var kante := float(model.kachel_groesse)
	
	for pos in fels_kacheln:
		var welt_pos := Vector2((float(pos.x) + 0.5) * kante, (float(pos.y) + 0.5) * kante)
		var wurf := zufall.naechste_zahl() % 100
		if wurf < 35:
			model.objekt_hinzufuegen("berg", welt_pos)
		elif wurf < 65:
			model.objekt_hinzufuegen("felswand", welt_pos)
		elif wurf < 85:
			model.objekt_hinzufuegen("erzader", welt_pos)
