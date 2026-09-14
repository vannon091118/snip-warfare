extends RefCounted
class_name Welt_RaumErkenner
## Einzige Rechenstelle für geschlossene Räume in der Welt.
## Sie liest nur Welt_Model (objekt_feld und Raster) und kennt die
## Platzierungsdaten der Wände/Türen aus der Registry. Sie tickt nicht,
## rechnet nur auf Aufruf und liefert wertabgeschlossene Welt_Raum-Instanzen.
##
## Verantwortlichkeit: Aus dem Weltzustand (Kachel-Raster und Wand-/Tür-Objekte)
## zusammenhängende, vollständig umschlossene Innenflächen bestimmen, deren
## Tür-Besitz und Mindestgröße prüfen. Keine Persistenz, kein Signal-Bus.

const WAND_IDS := ["wand_holz", "wand_stein", "felswand", "tuer"]
const BLOCKADE_IDS := ["wand_holz", "wand_stein", "felswand"]
const TUER_IDS := ["tuer"]

## Kategorie logik: Erkennung.

func raeume_erkennen(model: Welt_Model) -> Array[Welt_Raum]:
	if model == null:
		return []
	var kante := maxi(model.kachel_groesse, 1)
	var wand_kacheln := _wand_kacheln_sammeln(model, kante)
	var tuer_kacheln := _tuer_kacheln_sammeln(model, kante)
	var besuchte_aussen := _aussen_flood(model, wand_kacheln, kante)
	var ergebnis: Array[Welt_Raum] = []
	var gesehen_innen: Dictionary = {}
	for y in model.raster_hoehe:
		for x in model.raster_breite:
			var kachel := Vector2i(x, y)
			var kachel_schluessel := "%d:%d" % [kachel.x, kachel.y]
			if gesehen_innen.has(kachel_schluessel):
				continue
			if wand_kacheln.has(kachel_schluessel):
				continue
			if besuchte_aussen.has(kachel_schluessel):
				continue
			var innen_kacheln := _flood_innen(kachel, model, wand_kacheln)
			for k in innen_kacheln:
				gesehen_innen["%d:%d" % [k.x, k.y]] = true
			if innen_kacheln.is_empty():
				continue
			if not _geschlossen(innen_kacheln, wand_kacheln, besuchte_aussen):
				continue
			var raum := _raum_aus_innen(innen_kacheln, tuer_kacheln, wand_kacheln, model, kante)
			raum.geschlossen = true
			raum.id = "raum_%d" % ergebnis.size()
			ergebnis.append(raum)
	return ergebnis

func erster_gueltiger_raum(model: Welt_Model, innen_mindest_flaeche: int = 16, braucht_tuer: bool = true) -> Welt_Raum:
	for raum in raeume_erkennen(model):
		if raum.innen_flaeche < innen_mindest_flaeche:
			continue
		if raum.breite < 4 or raum.hoehe < 4:
			continue
		if braucht_tuer and not raum.hat_tuer:
			continue
		if not raum.geschlossen:
			continue
		return raum
	return null

func raum_an_position(welt_position: Vector2, model: Welt_Model) -> Welt_Raum:
	if model == null:
		return null
	for raum in raeume_erkennen(model):
		if raum.enthaelt_welt_position(welt_position, model.kachel_groesse):
			return raum
	return null

func alle_gueltigen_raeume(model: Welt_Model, innen_mindest_flaeche: int = 16, braucht_tuer: bool = true) -> Array[Welt_Raum]:
	var gueltig: Array[Welt_Raum] = []
	for raum in raeume_erkennen(model):
		if raum.innen_flaeche < innen_mindest_flaeche:
			continue
		if raum.breite < 4 or raum.hoehe < 4:
			continue
		if braucht_tuer and not raum.hat_tuer:
			continue
		if not raum.geschlossen:
			continue
		gueltig.append(raum)
	return gueltig

func _wand_kacheln_sammeln(model: Welt_Model, kante: int) -> Dictionary:
	var kacheln: Dictionary = {}
	for index in model.objekt_anzahl():
		var element_id := model.objekt_element_id(index)
		if not WAND_IDS.has(element_id):
			continue
		var welt_position := model.objekt_position(index)
		var kachel := Vector2i(floori(welt_position.x / float(kante)), floori(welt_position.y / float(kante)))
		kacheln["%d:%d" % [kachel.x, kachel.y]] = true
	return kacheln

func _tuer_kacheln_sammeln(model: Welt_Model, kante: int) -> Dictionary:
	var kacheln: Dictionary = {}
	for index in model.objekt_anzahl():
		if model.objekt_element_id(index) != "tuer":
			continue
		var welt_position := model.objekt_position(index)
		var kachel := Vector2i(floori(welt_position.x / float(kante)), floori(welt_position.y / float(kante)))
		kacheln["%d:%d" % [kachel.x, kachel.y]] = true
	return kacheln

func _aussen_flood(model: Welt_Model, wand_kacheln: Dictionary, _kante: int) -> Dictionary:
	var besucht: Dictionary = {}
	var schlange: Array[Vector2i] = []
	# Außenrand als Start: alle Randkacheln, die nicht gerade Wand sind
	for x in model.raster_breite:
		var unten := Vector2i(x, 0)
		var oben := Vector2i(x, model.raster_hoehe - 1)
		for start in [unten, oben]:
			var schluessel := "%d:%d" % [start.x, start.y]
			if not wand_kacheln.has(schluessel) and not besucht.has(schluessel):
				schlange.append(start)
				besucht[schluessel] = true
	for y in model.raster_hoehe:
		var links := Vector2i(0, y)
		var rechts := Vector2i(model.raster_breite - 1, y)
		for start in [links, rechts]:
			var schluessel2 := "%d:%d" % [start.x, start.y]
			if not wand_kacheln.has(schluessel2) and not besucht.has(schluessel2):
				schlange.append(start)
				besucht[schluessel2] = true
	var kopf := 0
	while kopf < schlange.size():
		var kachel := schlange[kopf]
		kopf += 1
		for versatz in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nachbar := kachel + versatz
			if nachbar.x < 0 or nachbar.y < 0 or nachbar.x >= model.raster_breite or nachbar.y >= model.raster_hoehe:
				continue
			var schluessel3 := "%d:%d" % [nachbar.x, nachbar.y]
			if besucht.has(schluessel3):
				continue
			if wand_kacheln.has(schluessel3):
				continue
			besucht[schluessel3] = true
			schlange.append(nachbar)
	return besucht

func _flood_innen(start: Vector2i, model: Welt_Model, wand_kacheln: Dictionary) -> Array[Vector2i]:
	var besucht: Dictionary = {}
	var schlange: Array[Vector2i] = [start]
	besucht["%d:%d" % [start.x, start.y]] = true
	var kopf := 0
	while kopf < schlange.size():
		var kachel := schlange[kopf]
		kopf += 1
		for versatz in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nachbar := kachel + versatz
			if nachbar.x < 0 or nachbar.y < 0 or nachbar.x >= model.raster_breite or nachbar.y >= model.raster_hoehe:
				continue
			var schluessel := "%d:%d" % [nachbar.x, nachbar.y]
			if besucht.has(schluessel):
				continue
			if wand_kacheln.has(schluessel):
				continue
			besucht[schluessel] = true
			schlange.append(nachbar)
	return schlange

func _geschlossen(innen_kacheln: Array[Vector2i], _wand_kacheln: Dictionary, besuchte_aussen: Dictionary) -> bool:
	# Ein Innen-Raum, der bis zum Kartenrand reicht, gilt als nicht geschlossen
	# (es sei denn, der Rand ist durch Wand blockiert — das ist durch das
	# Aussen-Flood bereits bestimmt: berührt er das Außen, berührt er eine
	# Außen-Kachel).
	for kachel in innen_kacheln:
		var schluessel := "%d:%d" % [kachel.x, kachel.y]
		if besuchte_aussen.has(schluessel):
			return false
	# Ein weiterer Indikator: jede Innenkachel muss vollständig von Wänden
	# oder weiteren Innenkacheln umgeben sein. Das ist durch das Flood schon
	# erfüllt, solange kein Leck zum Rand besteht. Nur noch Lücken prüfen:
	# Gibt es eine Kachel des Raums, deren Nachbar kein Wand-Block und kein
	# Innen ist, aber auch nicht besuchte_aussen — dann läge ein Pfad offen,
	# der nie den Rand erreichte (Insel) — dieser gilt als geschlossen.
	# Für den Auftrag gilt: geschlossen heißt nicht mit der Außenwelt verbunden.
	return innen_kacheln.size() > 0

func _raum_aus_innen(innen_kacheln: Array[Vector2i], tuer_kacheln: Dictionary, _wand_kacheln: Dictionary, model: Welt_Model, kante: int) -> Welt_Raum:
	var raum := Welt_Raum.new()
	raum.innen_kacheln = innen_kacheln
	raum.innen_flaeche = innen_kacheln.size()
	if innen_kacheln.is_empty():
		return raum
	var min_x := innen_kacheln[0].x
	var min_y := innen_kacheln[0].y
	var max_x := min_x
	var max_y := min_y
	for kachel in innen_kacheln:
		min_x = mini(min_x, kachel.x)
		min_y = mini(min_y, kachel.y)
		max_x = maxi(max_x, kachel.x)
		max_y = maxi(max_y, kachel.y)
	raum.min_kachel = Vector2i(min_x, min_y)
	raum.max_kachel = Vector2i(max_x, max_y)
	raum.breite = (max_x - min_x + 1)
	raum.hoehe = (max_y - min_y + 1)
	raum.zentrum = Vector2(float(min_x + max_x + 1) * 0.5 * float(kante), float(min_y + max_y + 1) * 0.5 * float(kante))
	raum.z_ebene = model.aktive_z_ebene
	# Hat eine Tür den Raum am Rand berührt? Türen liegen auf den Wandkacheln;
	# sie zählen als Wand, öffnen aber den Durchgang. Ein Raum, der eine Tür
	# an seiner Hülle trägt, gilt als betretbar.
	for versatz in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		for innen in innen_kacheln:
			var rand := innen + versatz
			var schluessel := "%d:%d" % [rand.x, rand.y]
			if tuer_kacheln.has(schluessel):
				if not raum.hat_tuer:
					raum.hat_tuer = true
				var tuer_kachel := Vector2i(rand.x, rand.y)
				if not raum.tuer_kacheln.has(tuer_kachel):
					raum.tuer_kacheln.append(tuer_kachel)
	return raum
