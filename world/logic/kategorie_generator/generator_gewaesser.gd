extends RefCounted
class_name Welt_GeneratorGewaesser
## Deterministischer Landschaftsgenerator fuer Gewaesser (Fluesse, Seen, Teiche).
## Berechnet zusammenhaengende Wasserlaeufe und organische Wasseransammlungen
## direkt aus dem weltweiten Seed und versieht die Uebergaenge mit Ufersaeumen.
## Entfernt kollidierende Landobjekte aus dem Modell, damit Baeume und Felsen
## nicht im tiefen Wasser schwimmen.

const KACHEL_WASSER := "wasser"
const KACHEL_UFER := "ufer"

func erzeugen(model: Welt_Model, biom_id: String, zufall: Kern_Zufall) -> void:
	if model == null or zufall == null:
		return
	var breite := model.raster_breite
	var hoehe := model.raster_hoehe
	if breite <= 4 or hoehe <= 4:
		return
	
	# Flussanzahl je nach Biom (1 im gemaessigten Biom / Tundra, seltener in Steppe)
	var fluss_chance := 0.85 if biom_id != "steppe" else 0.40
	var wurf := float(zufall.naechste_zahl() % 1000) / 1000.0
	if wurf < fluss_chance:
		_fluss_erzeugen(model, breite, hoehe, zufall)
	
	# 1 bis 2 Seen / Teiche
	var seen_anzahl := 1 + int(zufall.naechste_zahl() % 2)
	for i in seen_anzahl:
		_see_erzeugen(model, breite, hoehe, zufall)
	
	# Ufersaeume um alle Wasserkacheln legen
	_ufersaeume_bilden(model, breite, hoehe)

func _fluss_erzeugen(model: Welt_Model, breite: int, hoehe: int, zufall: Kern_Zufall) -> void:
	# Fluss startet an einer Kante und maeandriert zur gegenueberliegenden Kante
	var von_oben_nach_unten := (zufall.naechste_zahl() % 2) == 0
	var start_x := int(zufall.naechste_zahl() % breite)
	var start_y := int(zufall.naechste_zahl() % hoehe)
	
	var cur_x := float(start_x if von_oben_nach_unten else 0)
	var cur_y := float(0 if von_oben_nach_unten else start_y)
	
	var schritte := hoehe if von_oben_nach_unten else breite
	for s in schritte:
		var ix := clampi(int(round(cur_x)), 0, breite - 1)
		var iy := clampi(int(round(cur_y)), 0, hoehe - 1)
		_wasser_setzen(model, ix, iy)
		# Flussbreite (1-2 Kacheln)
		if (zufall.naechste_zahl() % 3) == 0:
			if von_oben_nach_unten and ix + 1 < breite:
				_wasser_setzen(model, ix + 1, iy)
			elif not von_oben_nach_unten and iy + 1 < hoehe:
				_wasser_setzen(model, ix, iy + 1)
		
		# Maeandrieren
		var drift := 0.0
		if von_oben_nach_unten:
			cur_y += 1.0
			drift = (float(zufall.naechste_zahl() % 3) - 1.0) * 0.8
			cur_x = clampf(cur_x + drift, 1.0, float(breite - 2))
		else:
			cur_x += 1.0
			drift = (float(zufall.naechste_zahl() % 3) - 1.0) * 0.8
			cur_y = clampf(cur_y + drift, 1.0, float(hoehe - 2))


func _see_erzeugen(model: Welt_Model, breite: int, hoehe: int, zufall: Kern_Zufall) -> void:
	var mitte_x := 3 + int(zufall.naechste_zahl() % (breite - 6))
	var mitte_y := 3 + int(zufall.naechste_zahl() % (hoehe - 6))
	var radius := 1.5 + float(zufall.naechste_zahl() % 20) / 10.0
	var r_int := ceili(radius)
	
	for dy in range(-r_int, r_int + 1):
		for dx in range(-r_int, r_int + 1):
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= radius:
				var tx := mitte_x + dx
				var ty := mitte_y + dy
				if tx >= 0 and tx < breite and ty >= 0 and ty < hoehe:
					_wasser_setzen(model, tx, ty)

func _wasser_setzen(model: Welt_Model, x: int, y: int) -> void:
	model.fliese_setzen(x, y, KACHEL_WASSER)
	# Keine Landobjekte im tiefen Wasser ertrinken lassen
	_kachel_bereinigen(model, x, y)

func _ufersaeume_bilden(model: Welt_Model, breite: int, hoehe: int) -> void:
	var ufer_kandidaten: Array[Vector2i] = []
	for y in hoehe:
		for x in breite:
			if model.fliese(x, y) == KACHEL_WASSER:
				continue
			# Nachbarpruefung: Grenzt ein Landfeld an Wasser?
			var grenzt_an_wasser := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx: int = x + dx
					var ny: int = y + dy
					if nx >= 0 and nx < breite and ny >= 0 and ny < hoehe:
						if model.fliese(nx, ny) == KACHEL_WASSER:
							grenzt_an_wasser = true
							break
				if grenzt_an_wasser:
					break
			if grenzt_an_wasser:
				ufer_kandidaten.append(Vector2i(x, y))
	
	for pos in ufer_kandidaten:
		model.fliese_setzen(pos.x, pos.y, KACHEL_UFER)

func _kachel_bereinigen(model: Welt_Model, x: int, y: int) -> void:
	var kante := float(model.kachel_groesse)
	var kachel_min := Vector2(float(x) * kante, float(y) * kante)
	var kachel_max := kachel_min + Vector2(kante, kante)
	var i := model.objekt_anzahl() - 1
	while i >= 0:
		var pos := model.objekt_position(i)
		if pos.x >= kachel_min.x and pos.x < kachel_max.x and pos.y >= kachel_min.y and pos.y < kachel_max.y:
			model.objekt_entfernen(i)
		i -= 1
