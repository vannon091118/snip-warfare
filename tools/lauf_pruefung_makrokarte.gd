extends SceneTree
## Lauf-Prüfung der Makrokarte: beweist am echten Datenmodell, dass die
## Weltkarte nur Regionen plant, dass Gebirge und Ozean als Barrieren
## erscheinen, dass keine Fraktion darauf sitzt, kein Weg sie kreuzt und die
## Nachbarliste bei mehrfacher Planung nicht wächst.
## Aufruf: godot --headless --path . --script tools/lauf_pruefung_makrokarte.gd

func _init() -> void:
	var fehler := 0
	var registry := Welt_GeneratorRegistry.new()
	var biome := Welt_BiomRegistry.new()
	var makro := Welt_MakroGenerator.new()
	if not makro.laden():
		print("FEHLER: Makrokarte-Definition nicht ladbar.")
		quit(1)
		return
	var regionen := makro.regionen_groesse()
	var barrieren_je_lauf := 0
	var nachbarn_je_lauf := 0
	var unter_zwei := 0
	for lauf in 12:
		var seed_wert := 424242 + lauf * 977
		var model := Welt_Model.new()
		if not makro.karte_planen(model, registry, seed_wert):
			print("FEHLER: Makrokarte konnte für Seed %d nicht geplant werden." % seed_wert)
			fehler += 1
			continue
		# 1) Die Makrokarte plant nur Regionen und keine Inhalte.
		if model.objekt_anzahl() != 0:
			print("FEHLER: Die Makrokarte trägt %d Objekte statt nur Regionen." % model.objekt_anzahl())
			fehler += 1
		if model.regionen.size() != regionen.x * regionen.y:
			print("FEHLER: %d Regionen statt %d." % [model.regionen.size(), regionen.x * regionen.y])
			fehler += 1
		# 2) Barrieren erscheinen wirklich auf der Karte.
		var barrieren: Array[Vector2i] = []
		for region: Dictionary in model.regionen:
			var biom := biome.biom_fuer(str(region.get("biom_id", "")))
			if biom != null and biom.barriere:
				barrieren.append(Vector2i(int(region.get("region_x", 0)), int(region.get("region_y", 0))))
		barrieren_je_lauf += barrieren.size()
		# 3) Netzwerk planen und die Regeln prüfen.
		var planer := Welt_NetzwerkPlaner.new()
		if not planer.netzwerk_planen(model, registry, 0, biome):
			print("FEHLER: Netzwerk für Seed %d nicht planbar." % seed_wert)
			fehler += 1
			continue
		var spieler_region := planer.spieler_region()
		if planer.ist_barriere_region(model, spieler_region):
			print("FEHLER: Der Startbereich liegt auf einer Barriere (Seed %d)." % seed_wert)
			fehler += 1
		for fraktion: Welt_Fraktion in planer.fraktionen():
			var f_region := Vector2i(fraktion.position_kachel.x / model.region_kante, fraktion.position_kachel.y / model.region_kante)
			if planer.ist_barriere_region(model, f_region):
				print("FEHLER: Fraktion %s sitzt auf einer Barriere (Seed %d)." % [fraktion.fraktion_id, seed_wert])
				fehler += 1
		for weg: Dictionary in planer.wege():
			var von_kachel: Vector2i = weg.get("von", Vector2i.ZERO)
			var nach_kachel: Vector2i = weg.get("nach", Vector2i.ZERO)
			if _kreuzt_barriere(planer, model, von_kachel, nach_kachel):
				print("FEHLER: Weg %s -> %s kreuzt eine Barriere (Seed %d)." % [str(weg.get("von_id", "")), str(weg.get("nach_id", "")), seed_wert])
				fehler += 1
		# 4) Nachbarliste wächst bei erneuter Planung nicht.
		var vorher := planer.nachbarn_fuer("spieler").size()
		planer.netzwerk_planen(model, registry, 0, biome)
		var nachher := planer.nachbarn_fuer("spieler").size()
		if nachher != vorher:
			print("FEHLER: Nachbarliste wuchs von %d auf %d (Seed %d)." % [vorher, nachher, seed_wert])
			fehler += 1
		nachbarn_je_lauf += nachher
		if nachher < 2:
			unter_zwei += 1
	# 5) Gegenprobe der lokalen Karte: Sie zieht keine Barriere-Biome und
	# bleibt damit bewohnbar, obwohl beide Ebenen dieselben Gewichte lesen.
	var lokal := Welt_Generator.new()
	var lokal_model := Welt_Model.new()
	if not lokal.welt_erzeugen(lokal_model, 20260901, "gemaaessigt"):
		print("FEHLER: Lokale Karte konnte nicht erzeugt werden.")
		fehler += 1
	else:
		var lokale_barrieren := 0
		for region: Dictionary in lokal_model.regionen:
			var lokales_biom := biome.biom_fuer(str(region.get("biom_id", "")))
			if lokales_biom != null and lokales_biom.barriere:
				lokale_barrieren += 1
		if lokale_barrieren != 0:
			print("FEHLER: Die lokale Karte trägt %d Barriere-Regionen." % lokale_barrieren)
			fehler += 1
		if lokal_model.objekt_anzahl() <= 0:
			print("FEHLER: Die lokale Karte blieb leer.")
			fehler += 1
	if barrieren_je_lauf == 0:
		print("FEHLER: Auf keiner Makrokarte erschien eine Barriere.")
		fehler += 1
	if unter_zwei > 0:
		print("HINWEIS: In %d von 12 Läufen hatte der Startbereich weniger als zwei Nachbarn." % unter_zwei)
	if fehler == 0:
		print("OK: Makrokarte plant nur Regionen; %d Barrierenregionen über 12 Seeds, durchschnittlich %d direkte Nachbarn, kein Weg kreuzt eine Barriere, die Nachbarliste bleibt stabil." % [barrieren_je_lauf, int(round(float(nachbarn_je_lauf) / 12.0))])
	quit(fehler)

func _kreuzt_barriere(planer: Welt_NetzwerkPlaner, model: Welt_Model, von_kachel: Vector2i, nach_kachel: Vector2i) -> bool:
	# Unabhängige Gegenrechnung des Testlaufs: Die Kachelkoordinaten werden in
	# Regionen umgerechnet und die Zellen dazwischen einzeln geprüft.
	var kante := maxi(model.region_kante, 1)
	var von := Vector2i(von_kachel.x / kante, von_kachel.y / kante)
	var nach := Vector2i(nach_kachel.x / kante, nach_kachel.y / kante)
	var schritte := maxi(absi(nach.x - von.x), absi(nach.y - von.y))
	for schritt in range(1, schritte):
		var anteil := float(schritt) / float(schritte)
		var zelle := Vector2i(
			int(round(float(von.x) + float(nach.x - von.x) * anteil)),
			int(round(float(von.y) + float(nach.y - von.y) * anteil)))
		if planer.ist_barriere_region(model, zelle):
			return true
	return false
