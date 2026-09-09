extends RefCounted
class_name Welt_Ladevorgang
## Spitze: Welt laden oder erzeugen. Einzige Stelle, die Speicher,
## Generator und Legacy-Standardwelt kennt. Sie schreibt ausschließlich
## über Welt_Model und persistiert die erzeugte Welt. Keine Darstellung,
## keine Eingabe, keine Lager- oder Tier-Logik.

const STANDARD_WELT_PFAD := "res://world/data/standard_welt.json"

var _model: Welt_Model = null
var _generator: Welt_Generator = null

func einrichten(model: Welt_Model, generator: Welt_Generator) -> void:
	_model = model
	_generator = generator

func ausfuehren(welt_name: String, seed_wunsch: int, biom_id: String) -> bool:
	if _model == null or _generator == null:
		return false
	var geladen := false
	if welt_name != "":
		var speicher := Welt_Speicher.new()
		geladen = _model.aus_woerterbuch(speicher.laden(welt_name))
	if not geladen:
		geladen = _welt_generieren(welt_name, seed_wunsch, biom_id)
	if not geladen:
		geladen = _model.aus_woerterbuch(_standard_welt_laden())
	if not geladen:
		push_warning("Keine Welt ladbar, benutze leeres Raster")
		return false
	return true

func _standard_welt_laden() -> Dictionary:
	if not FileAccess.file_exists(STANDARD_WELT_PFAD):
		return {}
	var datei := FileAccess.open(STANDARD_WELT_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) == TYPE_DICTIONARY:
		return daten
	return {}

func _welt_generieren(welt_name: String, seed_wunsch: int, biom_id: String) -> bool:
	var basis_seed := seed_wunsch
	if basis_seed == 0:
		# Autoritativer Seed ohne Uhrzeit: deterministisch aus bestehendem
		# Weltbestand und Namen abgeleitet, damit gleiche Eingabe immer die
		# gleiche Welt liefert und keine zweite Zeitquelle entsteht.
		var speicher := Welt_Speicher.new()
		var anzahl := speicher.welt_namen().size()
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
	var speicher_welt_name := welt_name
	if speicher_welt_name == "":
		speicher_welt_name = "generiert_" + str(seed_wert)
	var speicher := Welt_Speicher.new()
	speicher.speichern(speicher_welt_name, _model.nach_woerterbuch())
	WeltSitzung.welt_name = speicher_welt_name
	return true
