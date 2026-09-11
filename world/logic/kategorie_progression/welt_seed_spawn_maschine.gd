extends RefCounted
class_name Welt_SeedSpawnMaschine
## Taegliche Spawn-Maschine fuer neue Ressourcen-Saemlinge: Sie gewichtet die
## Kandidaten aus dem Progressions-Pool mit ihrer Verfuegbarkeit aus der
## bestehenden Generator-Gewichte-Datei und der Fruchtbarkeit des Biom an
## der Zielkachel. Die Ziehung laeuft ueber Kern_Zufall und bleibt damit
## deterministisch. Kein eigener Timer: Die Welt-Szene ruft sie je Tag.

## Kategorie daten: die Quellen der Ziehung und der Zustand.
var _progression: Welt_ProgressionsRegistry = null
var _gewichte: Welt_GeneratorRegistry = null
var _zufall := Kern_Zufall.new()
var _kachel_groesse: float = 512.0

## Kategorie logik: Einrichten und gewichtete Tag-Ziehung.

func einrichten(progression: Welt_ProgressionsRegistry, kachel_groesse: float, start_seed: int) -> void:
	_progression = progression
	_kachel_groesse = kachel_groesse
	_gewichte = Welt_GeneratorRegistry.new()
	_zufall.start_zustand_setzen(start_seed + 7919)

func fruchtbarkeit_fuer_biom(faktor: float) -> float:
	# Die Biom-Fruchtbarkeit kommt aus dem bestehenden Biom-Eintrag (faktor
	# des Biom-Pools); sie wird nur auf den Spawn-Bereich abgebildet.
	if _progression == null:
		return 1.0
	var minimum := _progression.fruchtbarkeit_min_faktor()
	var maximum := _progression.fruchtbarkeit_max_faktor()
	# Der Biom-Faktor 1.0 ist die neutrale Mitte: darunter trockener, daruber
	# fruchtbarer Boden, beide Richtungen bleiben im Pool-Rahmen.
	var ziel := 1.0 if faktor <= 0.0 else clampf(faktor, 0.5, 1.5)
	var anteil := (ziel - 0.5) / 1.0
	return lerpf(minimum, maximum, clampf(anteil, 0.0, 1.0))

func gewicht_fuer(element_id: String, biom_faktor: float) -> float:
	# SEED WEIGHT = Verfuegbarkeit aus den Generator-Gewichten mal der
	# Fruchtbarkeit des Biom; Objekte ohne Verfuegbarkeit fallen heraus.
	if _gewichte == null or _progression == null:
		return 0.0
	if not _progression.spawn_kandidaten().has(element_id):
		return 0.0
	var verfuegbarkeit := _gewichte.gewicht_fuer(element_id)
	if verfuegbarkeit <= 0.0:
		return 0.0
	return verfuegbarkeit * fruchtbarkeit_fuer_biom(biom_faktor)

func ziehe_kandidat(biom_faktor: float) -> String:
	var kandidaten := _progression.spawn_kandidaten() if _progression != null else []
	var summe := 0.0
	var effektive := {}
	for kandidat: String in kandidaten:
		var gewicht := gewicht_fuer(kandidat, biom_faktor)
		effektive[kandidat] = gewicht
		summe += gewicht
	if summe <= 0.0:
		return ""
	var wurf := _zufall.naechste_zahl() % 1000000
	var schwelle := float(wurf) / 1000000.0 * summe
	var lauf := 0.0
	for kandidat: String in effektive.keys():
		lauf += float(effektive[kandidat])
		if schwelle < lauf:
			return kandidat
	return ""

func tag_spawnen(model: Welt_Model, biom_registry: Welt_BiomRegistry) -> Array[Dictionary]:
	# Ein Tag ist vergangen: je Pool-Rate ein neuer Saemling an einer freien
	# Stelle der Karte. Liefert die gespawnten Ereignisse fuer die Szene.
	var ereignisse: Array[Dictionary] = []
	if model == null or _progression == null or biom_registry == null:
		return ereignisse
	var rate := _progression.spawn_je_tag()
	for _i in rate:
		var stelle := _freie_stelle(model, biom_registry)
		if stelle.is_empty():
			continue
		var biom_faktor := float(stelle.get("biom_faktor", 1.0))
		var kandidat := ziehe_kandidat(biom_faktor)
		if kandidat == "":
			continue
		var position := stelle.get("position", Vector2.ZERO) as Vector2
		var index := model.objekt_hinzufuegen(kandidat, position)
		ereignisse.append({"element_id": kandidat, "index": index, "position": position})
	return ereignisse

func _freie_stelle(model: Welt_Model, biom_registry: Welt_BiomRegistry) -> Dictionary:
	# Ort und Biom-Fruchtbarkeit eines freien Kachel-Feldes: Der Versuch
	# laeuft begrenzt, damit die Suche bei voller Karte endet.
	for _versuch in 24:
		var kachel_x := _zufall.zahl_bereich(0, maxi(model.raster_breite - 1, 0))
		var kachel_y := _zufall.zahl_bereich(0, maxi(model.raster_hoehe - 1, 0))
		var position := Vector2((float(kachel_x) + 0.5) * _kachel_groesse, (float(kachel_y) + 0.5) * _kachel_groesse)
		if model.objekt_bei(position, _kachel_groesse * 0.4) >= 0:
			continue
		var biom_id := model.biom_an_kachel(kachel_x, kachel_y)
		var biom := biom_registry.biom_fuer(biom_id)
		var biom_faktor := 1.0 if biom == null else biom.faktor
		return {"position": position, "biom_faktor": biom_faktor}
	return {}
