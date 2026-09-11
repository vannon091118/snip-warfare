extends RefCounted
class_name Welt_NetzwerkPlaner
## Planungsmaschine für das Vor-Spiel-Netzwerk und die Fraktionsplatzierung.
## Genau eine Verantwortung: Platziert Fraktionen deterministisch aus dem Welt-Seed
## auf passenden Makro-Regionen der World Map und verbindet sie über reale
## Netzwerkbeziehungen (Handels- und Militärpfade).
## Stellt sicher, dass der Spielerbereich mindestens zwei direkte Nachbarn besitzt.

## Kategorie daten: Platzierte Fraktionen, Wege und Spieler-Startknoten.
var _fraktionen: Array[Welt_Fraktion] = []
var _wege: Array[Dictionary] = []
var _spieler_region := Vector2i.ZERO
var _spieler_nachbarn: Array[String] = []

## Kategorie logik: Planung, Pfadberechnung und Abfragen.

func netzwerk_planen(model: Welt_Model, registry: Welt_GeneratorRegistry, seed_offset: int = 0) -> bool:
	if model == null or registry == null:
		return false
	_fraktionen.clear()
	_wege.clear()
	_spieler_nachbarn.clear()

	var effektiver_seed := (model.welt_seed + seed_offset * 1337) & 0x7FFFFFFF
	var zufall := Kern_Zufall.new()
	zufall.start_zustand_setzen(effektiver_seed)

	var f_ids := registry.ids_der_kategorie("fraktionen")
	if f_ids.is_empty():
		return false

	var regionen_x := ceili(float(model.raster_breite) / float(maxi(model.region_kante, 1)))
	var regionen_y := ceili(float(model.raster_hoehe) / float(maxi(model.region_kante, 1)))

	# Spieler-Startregion standardmäßig nahe dem Zentrum
	_spieler_region = Vector2i(regionen_x / 2, regionen_y / 2)

	var belegte_regionen: Array[Vector2i] = [_spieler_region]

	for f_id in f_ids:
		var wort := registry.eintrag_wort_fuer(f_id)
		var fraktion := Welt_Fraktion.new()
		fraktion.aus_konfig_eintrag(f_id, wort)

		var beste_region := Vector2i.ZERO
		var beste_bewertung := -INF

		# Beste Region für Fraktion anhand Biom-Vorliebe und Abstand suchen
		for ry in regionen_y:
			for rx in regionen_x:
				var reg_pos := Vector2i(rx, ry)
				if belegte_regionen.has(reg_pos):
					continue
				var region := model.region_an_kachel(rx * model.region_kante, ry * model.region_kante)
				var r_biom := str(region.get("biom_id", model.biom_id))
				var bewertung := 0.0
				if fraktion.bevorzugte_biome.has(r_biom):
					bewertung += 50.0
				var abstand_spieler := Vector2(reg_pos).distance_to(Vector2(_spieler_region))
				bewertung -= abstand_spieler * 2.0
				bewertung += float(zufall.naechste_zahl() % 20)

				if bewertung > beste_bewertung:
					beste_bewertung = bewertung
					beste_region = reg_pos

		fraktion.position_kachel = beste_region * model.region_kante + Vector2i(model.region_kante / 2, model.region_kante / 2)
		belegte_regionen.append(beste_region)
		_fraktionen.append(fraktion)

	_wege_berechnen(model)
	return not _fraktionen.is_empty()

func _wege_berechnen(model: Welt_Model) -> void:
	_wege.clear()
	_spieler_nachbarn.clear()
	for f: Welt_Fraktion in _fraktionen:
		f.nachbarn.clear()
	var spieler_pos_kachel := _spieler_region * model.region_kante + Vector2i(model.region_kante / 2, model.region_kante / 2)

	# Distanzen aller Fraktionen zum Spieler ermitteln
	var distanzen: Array[Dictionary] = []
	for f in _fraktionen:
		var dist_spieler := Vector2(f.position_kachel).distance_to(Vector2(spieler_pos_kachel))
		distanzen.append({"fraktion": f, "distanz": dist_spieler})
	distanzen.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distanz"]) < float(b["distanz"])
	)

	# Mindestens 2 nächste Nachbarn direkt mit dem Spieler verbinden
	var min_nachbarn := mini(2, distanzen.size())
	for i in min_nachbarn:
		var f: Welt_Fraktion = distanzen[i]["fraktion"]
		_wege.append({
			"von": spieler_pos_kachel,
			"nach": f.position_kachel,
			"von_id": "spieler",
			"nach_id": f.fraktion_id,
			"typ": "hauptweg"
		})
		f.nachbarn.append("spieler")
		_spieler_nachbarn.append(f.fraktion_id)

	# Fraktionen untereinander vernetzen (nächster Nachbar jeder Fraktion)
	for i in _fraktionen.size():
		var f1 := _fraktionen[i]
		var naechste_f: Welt_Fraktion = null
		var min_d := INF
		for j in _fraktionen.size():
			if i == j:
				continue
			var f2 := _fraktionen[j]
			var dist_fraktion := Vector2(f1.position_kachel).distance_to(Vector2(f2.position_kachel))
			if dist_fraktion < min_d:
				min_d = dist_fraktion
				naechste_f = f2
		if naechste_f != null and not _hat_weg(f1.fraktion_id, naechste_f.fraktion_id):
			_wege.append({
				"von": f1.position_kachel,
				"nach": naechste_f.position_kachel,
				"von_id": f1.fraktion_id,
				"nach_id": naechste_f.fraktion_id,
				"typ": "handelsweg"
			})
			f1.nachbarn.append(naechste_f.fraktion_id)
			naechste_f.nachbarn.append(f1.fraktion_id)

func _hat_weg(id_a: String, id_b: String) -> bool:
	for w in _wege:
		var v := str(w.get("von_id", ""))
		var n := str(w.get("nach_id", ""))
		if (v == id_a and n == id_b) or (v == id_b and n == id_a):
			return true
	return false

func fraktionen() -> Array[Welt_Fraktion]:
	return _fraktionen

func wege() -> Array[Dictionary]:
	return _wege

func spieler_region() -> Vector2i:
	return _spieler_region

func spieler_region_setzen(region_pos: Vector2i, model: Welt_Model) -> void:
	_spieler_region = region_pos
	if model != null and not _fraktionen.is_empty():
		_wege_berechnen(model)

func nachbarn_fuer(fraktion_oder_spieler_id: String) -> Array[String]:
	if fraktion_oder_spieler_id == "spieler":
		return _spieler_nachbarn
	for f in _fraktionen:
		if f.fraktion_id == fraktion_oder_spieler_id:
			return f.nachbarn
	return []

func nach_array() -> Array[Dictionary]:
	var daten: Array[Dictionary] = []
	for f in _fraktionen:
		daten.append(f.nach_woerterbuch())
	return daten
