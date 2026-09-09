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

func einrichten(model: Welt_Model, generator: Welt_Generator) -> void:
	_model = model
	_generator = generator

func ausfuehren(welt_name: String, seed_wunsch: int, biom_id: String) -> bool:
	if _model == null or _generator == null:
		return false
	var geladen := false
	var speicher := Welt_Speicher.new()
	if welt_name != "":
		# World-Ebene: Die Save-Datei ist eine World mit mehreren Maps; das
		# Szenen-Modell wird aus der aktiven Map der Sitzung gespeist.
		var world := speicher.world_laden(welt_name)
		if world != null:
			WeltSitzung.world = world
			var aktive_id := WeltSitzung.aktive_map_id
			if aktive_id == "" or not world.map_id_vorhanden(aktive_id):
				aktive_id = world.aktive_map_id()
				WeltSitzung.aktive_map_id = aktive_id
			var aktive_map := world.map_model(aktive_id)
			if aktive_map != null:
				geladen = _model.aus_woerterbuch(aktive_map.nach_woerterbuch())
		if not geladen:
			# Abwärtskompatibel: Alte Einzelwelt-Dateien bleiben ladbar.
			geladen = _model.aus_woerterbuch(speicher.laden(welt_name))
	if not geladen:
		geladen = _welt_generieren(welt_name, seed_wunsch, biom_id)
	if not geladen:
		push_warning("Keine Welt ladbar, benutze leeres Raster")
		return false
	return true

func _welt_generieren(welt_name: String, seed_wunsch: int, biom_id: String) -> bool:
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
		if _generator.welt_erzeugen(_model, seed_wert, biom_id) and _generator.verworfene_chunks == 0:
			break
		seed_wert = kandidat_zufall.naechste_zahl() % 1000000000
	if not _generator.welt_erzeugen(_model, seed_wert, biom_id):
		return false
	# World-Ebene: Die neue Karte wird als Basis-Map in eine frische World
	# eingetragen, die Sitzung zeigt auf sie.
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
