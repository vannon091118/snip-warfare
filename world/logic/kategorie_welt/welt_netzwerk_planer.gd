extends RefCounted
class_name Welt_NetzwerkPlaner
## Planungsmaschine für das Vor-Spiel-Netzwerk und die Fraktionsplatzierung.
## Genau eine Verantwortung: Platziert Fraktionen deterministisch aus dem Welt-Seed
## auf passenden Makro-Regionen der World Map und verbindet sie über reale
## Netzwerkbeziehungen (Handels- und Militärpfade).
## Barrieren: Regionen mit einem Barriere-Biom (Gebirge, Ozean) tragen keine
## Fraktion, dienen nie als Startbereich und werden von keinem Weg gekreuzt.
## Der Startbereich bekommt mindestens zwei direkte Nachbarn, sofern die
## Landschaft es zulässt.

## Kategorie daten: Platzierte Fraktionen, Wege und Spieler-Startknoten.
var _fraktionen: Array[Welt_Fraktion] = []
var _wege: Array[Dictionary] = []
var _wege_index: Dictionary = {}
var _spieler_region := Vector2i.ZERO
var _spieler_nachbarn: Array[String] = []
var _biome: Welt_BiomRegistry = null

## Kategorie logik: Planung, Pfadberechnung und Abfragen.

func netzwerk_planen(model: Welt_Model, registry: Welt_GeneratorRegistry, seed_offset: int = 0, biome: Welt_BiomRegistry = null) -> bool:
	if model == null or registry == null:
		return false
	_biome = biome
	# Die Listen sind der Zustand dieses Planers: Jede Planung beginnt bei Null,
	# damit ein zweiter Lauf (oder ein Regionswechsel) die Nachbarliste nicht
	# um dieselben Einträge aufbläht.
	_fraktionen.clear()
	_wege.clear()
	_wege_index.clear()
	_spieler_nachbarn.clear()

	var effektiver_seed := (model.welt_seed + seed_offset * 1337) & 0x7FFFFFFF
	var zufall := Kern_Zufall.new()
	zufall.start_zustand_setzen(effektiver_seed)

	var f_ids := registry.ids_der_kategorie("fraktionen")
	if f_ids.is_empty():
		return false

	var regionen_x := ceili(float(model.raster_breite) / float(maxi(model.region_kante, 1)))
	var regionen_y := ceili(float(model.raster_hoehe) / float(maxi(model.region_kante, 1)))
	var regionen := Vector2i(regionen_x, regionen_y)

	var belegte_regionen: Array[Vector2i] = []

	for f_id in f_ids:
		var wort := registry.eintrag_wort_fuer(f_id)
		var fraktion := Welt_Fraktion.new()
		fraktion.aus_konfig_eintrag(f_id, wort)

		var beste_region := Vector2i.ZERO
		var beste_bewertung := -INF

		# Beste Region für Fraktion anhand Biom-Vorliebe und Abstand suchen;
		# Barrieren kommen nie in Frage.
		for ry in regionen_y:
			for rx in regionen_x:
				var reg_pos := Vector2i(rx, ry)
				if belegte_regionen.has(reg_pos) or ist_barriere_region(model, reg_pos):
					continue
				var region := model.region_an_kachel(rx * model.region_kante, ry * model.region_kante)
				var r_biom := str(region.get("biom_id", model.biom_id))
				var bewertung := 0.0
				if fraktion.bevorzugte_biome.has(r_biom):
					bewertung += 50.0
				var abstand_mitte := Vector2(reg_pos).distance_to(Vector2(regionen) * 0.5)
				bewertung -= abstand_mitte * 2.0
				bewertung += float(zufall.naechste_zahl() % 20)

				if bewertung > beste_bewertung:
					beste_bewertung = bewertung
					beste_region = reg_pos

		fraktion.position_kachel = beste_region * model.region_kante + Vector2i(int(model.region_kante * 0.5), int(model.region_kante * 0.5))
		belegte_regionen.append(beste_region)
		_fraktionen.append(fraktion)

	_spieler_region = _start_region_waehlen(model, regionen, belegte_regionen)
	_wege_berechnen(model)
	return not _fraktionen.is_empty()

func ist_barriere_region(model: Welt_Model, region_pos: Vector2i) -> bool:
	# Barriere heißt: Das Biom dieser Region ist unpassierbar. Die Eigenschaft
	# steht am Biom, die Frage beantwortet nur diese Stelle.
	if model == null or _biome == null:
		return false
	var region := model.region_an_kachel(region_pos.x * model.region_kante, region_pos.y * model.region_kante)
	if region.is_empty():
		return false
	var biom := _biome.biom_fuer(str(region.get("biom_id", "")))
	return biom != null and biom.barriere

func _start_region_waehlen(model: Welt_Model, regionen: Vector2i, belegte: Array[Vector2i]) -> Vector2i:
	# Startbereich: möglichst nahe der Mitte, niemals auf einer Barriere und
	# möglichst mit zwei offenen Wegen zu Fraktionen. Die Wahl ist
	# deterministisch, damit dieselbe Karte denselben Start liefert.
	var mitte := Vector2i(int(float(regionen.x) * 0.5), int(float(regionen.y) * 0.5))
	var kandidaten: Array[Vector2i] = []
	for ry in regionen.y:
		for rx in regionen.x:
			var pos := Vector2i(rx, ry)
			if belegte.has(pos) or ist_barriere_region(model, pos):
				continue
			kandidaten.append(pos)
	kandidaten.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := Vector2(a).distance_squared_to(Vector2(mitte))
		var db := Vector2(b).distance_squared_to(Vector2(mitte))
		if absf(da - db) > 0.001:
			return da < db
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)
	for kandidat: Vector2i in kandidaten:
		if _offene_nachbarn(model, kandidat).size() >= 2:
			return kandidat
	if not kandidaten.is_empty():
		return kandidaten[0]
	return mitte

func _offene_nachbarn(model: Welt_Model, region_pos: Vector2i) -> Array[Welt_Fraktion]:
	# Fraktionen, zu denen ein Weg ohne Barriere führt; nur lesend, ohne
	# Nebenwirkung auf Wege oder Nachbarlisten.
	var treffer: Array[Welt_Fraktion] = []
	for f: Welt_Fraktion in _fraktionen:
		if _linie_frei(model, region_pos, _region_von_fraktion(model, f)):
			treffer.append(f)
	return treffer

func _region_von_fraktion(model: Welt_Model, fraktion: Welt_Fraktion) -> Vector2i:
	var kante := maxi(model.region_kante, 1)
	return Vector2i(int(float(fraktion.position_kachel.x) / float(kante)), int(float(fraktion.position_kachel.y) / float(kante)))

func _linie_frei(model: Welt_Model, von: Vector2i, nach: Vector2i) -> bool:
	# Wege umgehen Barrieren: Die Zellen zwischen zwei Regionen werden
	# abgeschritten; liegt eine Barriere dazwischen, gibt es keinen Weg.
	var schritte := maxi(absi(nach.x - von.x), absi(nach.y - von.y))
	if schritte <= 1:
		return true
	for schritt in range(1, schritte):
		var anteil := float(schritt) / float(schritte)
		var zelle := Vector2i(
			int(round(float(von.x) + float(nach.x - von.x) * anteil)),
			int(round(float(von.y) + float(nach.y - von.y) * anteil)))
		if zelle == von or zelle == nach:
			continue
		if ist_barriere_region(model, zelle):
			return false
	return true

func _wege_berechnen(model: Welt_Model) -> void:
	_wege.clear()
	_wege_index.clear()
	_spieler_nachbarn.clear()
	for f: Welt_Fraktion in _fraktionen:
		f.nachbarn.clear()
	var spieler_region := _spieler_region
	var spieler_pos_kachel := spieler_region * model.region_kante + Vector2i(int(model.region_kante * 0.5), int(model.region_kante * 0.5))

	# Distanzen aller Fraktionen zum Spieler ermitteln; Barrieren sortieren
	# Kandidaten aus, statt einen Weg quer durch den Fels zu ziehen.
	var distanzen: Array[Dictionary] = []
	for f in _fraktionen:
		if not _linie_frei(model, spieler_region, _region_von_fraktion(model, f)):
			continue
		var dist_spieler := Vector2(f.position_kachel).distance_to(Vector2(spieler_pos_kachel))
		distanzen.append({"fraktion": f, "distanz": dist_spieler})
	distanzen.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distanz"]) < float(b["distanz"])
	)

	# Mindestens 2 nächste Nachbarn direkt mit dem Spieler verbinden
	var min_nachbarn := mini(2, distanzen.size())
	for i in min_nachbarn:
		var f: Welt_Fraktion = distanzen[i]["fraktion"]
		_weg_hinzufuegen(spieler_pos_kachel, f.position_kachel, "spieler", f.fraktion_id, "hauptweg")
		f.nachbarn.append("spieler")
		_spieler_nachbarn.append(f.fraktion_id)

	# Fraktionen untereinander vernetzen (nächster Nachbar jeder Fraktion),
	# ebenfalls nur über freie Linien zwischen den Regionen.
	for i in _fraktionen.size():
		var f1 := _fraktionen[i]
		var naechste_f: Welt_Fraktion = null
		var min_d := INF
		for j in _fraktionen.size():
			if i == j:
				continue
			var f2 := _fraktionen[j]
			if not _linie_frei(model, _region_von_fraktion(model, f1), _region_von_fraktion(model, f2)):
				continue
			var dist_fraktion := Vector2(f1.position_kachel).distance_to(Vector2(f2.position_kachel))
			if dist_fraktion < min_d:
				min_d = dist_fraktion
				naechste_f = f2
		if naechste_f != null and not _hat_weg(f1.fraktion_id, naechste_f.fraktion_id):
			_weg_hinzufuegen(f1.position_kachel, naechste_f.position_kachel, f1.fraktion_id, naechste_f.fraktion_id, "handelsweg")
			f1.nachbarn.append(naechste_f.fraktion_id)
			naechste_f.nachbarn.append(f1.fraktion_id)

func _weg_hinzufuegen(von_pos: Vector2i, nach_pos: Vector2i, von_id: String, nach_id: String, typ: String) -> void:
	_wege.append({
		"von": von_pos,
		"nach": nach_pos,
		"von_id": von_id,
		"nach_id": nach_id,
		"typ": typ
	})
	_wege_index[_weg_schluessel(von_id, nach_id)] = true

func _weg_schluessel(id_a: String, id_b: String) -> String:
	return "%s:%s" % [id_a, id_b] if id_a < id_b else "%s:%s" % [id_b, id_a]

func _hat_weg(id_a: String, id_b: String) -> bool:
	return _wege_index.has(_weg_schluessel(id_a, id_b))

func fraktionen() -> Array[Welt_Fraktion]:
	return _fraktionen

func wege() -> Array[Dictionary]:
	return _wege

func spieler_region() -> Vector2i:
	return _spieler_region

func spieler_region_setzen(region_pos: Vector2i, model: Welt_Model) -> void:
	# Spielerwahl auf der Weltkarte: Eine Barriere ist kein Startbereich; der
	# Klick wird abgewiesen und der bisherige Start bleibt bestehen.
	if ist_barriere_region(model, region_pos):
		return
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

## Kategorie logik: Öffentliche Helfer für FraktionsGenerator-Integration.

func _berechne_regionen(model: Welt_Model) -> Vector2i:
	var regionen_x := ceili(float(model.raster_breite) / float(maxi(model.region_kante, 1)))
	var regionen_y := ceili(float(model.raster_hoehe) / float(maxi(model.region_kante, 1)))
	return Vector2i(regionen_x, regionen_y)

func _belegte_regionen_ermitteln(model: Welt_Model, eingehende_fraktionen: Array[Welt_Fraktion]) -> Array[Vector2i]:
	var belegte: Array[Vector2i] = []
	for f in eingehende_fraktionen:
		var region := _region_von_fraktion(model, f)
		if not belegte.has(region):
			belegte.append(region)
	return belegte

func _wege_berechnen_mit_fraktionen(model: Welt_Model, eingehende_fraktionen: Array[Welt_Fraktion]) -> void:
	# Weise übergebene Fraktionen dem internen Array zu
	_fraktionen.clear()
	for f in eingehende_fraktionen:
		_fraktionen.append(f)
	# Berechne Wege wie im Original
	_wege_berechnen(model)
