extends RefCounted
class_name Welt_Ladevorgang
## Spitze: Welt laden oder erzeugen. Einzige Stelle, die Speicher und
## Generator kennt. Die Produktionswelt kommt ausschließlich aus Save oder
## Generator; die Legacy-Standardwelt ist kein Fallback und nie Generator-
## oder Produktionswahrheit. Sie schreibt ausschließlich über Welt_Model
## und persistiert die erzeugte Welt. Keine Darstellung, keine Eingabe,
## keine Lager- oder Tier-Logik.

var _model: Welt_Model = null
var _generator: Welt_Generator = null
var _map_fabrik := Welt_MapFabrik.new()

func einrichten(model: Welt_Model, generator: Welt_Generator) -> void:
	_model = model
	_generator = generator
	_map_fabrik.einrichten(generator)

func ausfuehren(welt_name: String, seed_wunsch: int, biom_id: String) -> bool:
	if _model == null or _generator == null:
		return false
	var geladen := false
	var speicher := Welt_Speicher.new()
	if welt_name != "":
		# World-Ebene: Die Save-Datei ist eine World mit mehreren Maps. Die
		# geladene Instanz der aktiven Map wird zur laufenden Instanz der
		# Szene übernommen, statt sie als Kopie daneben bestehen zu lassen:
		# Genau eine Kartenwahrheit, die World zeigt auf dasselbe Welt_Model.
		var world := speicher.world_laden(welt_name)
		if world != null:
			var aktive_id := WeltSitzung.aktive_map_id
			if aktive_id == "" or not world.map_id_vorhanden(aktive_id):
				aktive_id = world.aktive_map_id()
			var aktive_map := world.map_model(aktive_id)
			if aktive_map != null and _model.aus_woerterbuch(aktive_map.nach_woerterbuch()):
				# Instanz-Übernahme: Die World zeigt ab hier auf das Szenen-
				# Modell, die Kopie im World-Eintrag stirbt mit dem Laden.
				world.model_uebernehmen(aktive_id, _model)
				WeltSitzung.world = world
				WeltSitzung.aktive_map_id = aktive_id
				geladen = true
			else:
				WeltSitzung.world = world
		if not geladen:
			# Abwärtskompatibel: Alte Einzelwelt-Dateien bleiben ladbar. Die
			# Welt wird als Ein-Map-World in die Sitzung genommen, damit
			# Speichern und Expansion über denselben Welt-Weg laufen.
			geladen = _model.aus_woerterbuch(speicher.laden(welt_name))
			if geladen:
				var erbe_world := Welt_World.new()
				erbe_world.world_name = welt_name
				erbe_world.map_hinzufuegen(_model, "karte_0", true)
				WeltSitzung.world = erbe_world
				WeltSitzung.aktive_map_id = "karte_0"
	if not geladen:
		geladen = _welt_generieren(welt_name, seed_wunsch, biom_id)
	if not geladen:
		push_warning("Keine Welt ladbar, benutze leeres Raster")
		return false
	return true

func _welt_generieren(welt_name: String, seed_wunsch: int, biom_id: String) -> bool:
	var effektives_biom := WeltSitzung.start_biom_id if WeltSitzung.start_biom_id != "" else biom_id
	var basis_seed := seed_wunsch
	if basis_seed == 0:
		# Autoritativer Seed ohne Uhrzeit: deterministisch aus bestehendem
		# Weltbestand und Namen abgeleitet, damit gleiche Eingabe immer die
		# gleiche Welt liefert und keine zweite Zeitquelle entsteht.
		var speicher_leser := Welt_Speicher.new()
		var anzahl := speicher_leser.welt_namen().size()
		var namens_hash := int(hash(welt_name) & 0x7FFFFFFF) if welt_name != "" else 841745713
		var ableitung := Kern_Zufall.abgeleitet_fuer(namens_hash, anzahl + 1)
		basis_seed = int(ableitung.naechste_zahl() % 1000000000)
		if basis_seed == 0:
			basis_seed = 13371337
	var kandidat_zufall := Kern_Zufall.new()
	kandidat_zufall.start_zustand_setzen(basis_seed)
	var seed_wert := basis_seed
	for _versuch in range(20):
		if _generator.welt_erzeugen(_model, seed_wert, effektives_biom) and _generator.verworfene_chunks == 0:
			break
		seed_wert = kandidat_zufall.naechste_zahl() % 1000000000
	if not _generator.welt_erzeugen(_model, seed_wert, effektives_biom):
		return false
	# World-Ebene: Die erzeugte Szene-Karte ist die Basis-Karte. Die World
	# übernimmt die laufende Instanz, es wird nicht ein zweites Mal
	# generiert: Genau eine Kartenwahrheit auch auf dem Erzeugungsweg.
	var world := Welt_World.new()
	var speicher_welt_name := welt_name
	if speicher_welt_name == "":
		speicher_welt_name = "generiert_" + str(seed_wert)
	world.world_name = speicher_welt_name
	world.map_hinzufuegen(_model, "karte_0", true)
	WeltSitzung.world = world
	WeltSitzung.aktive_map_id = "karte_0"
	var speicher := Welt_Speicher.new()
	speicher.world_speichern(speicher_welt_name, world)
	WeltSitzung.welt_name = speicher_welt_name
	return true

static func welt_speichern_aktiv(world: Welt_World, map_id: String) -> bool:
	## Persistiert die aktive Map in ihrer World. Einzige Speicher-Zustaendigkeit
	## bleibt diese Klasse; das Menue formuliert nur den Wunsch.
	if world == null or map_id == "" or not world.map_id_vorhanden(map_id):
		return false
	return Welt_Speicher.new().world_speichern(world.world_name, world)
