extends Welt_ModellRegionen
class_name Welt_ModellBiom
## Fuenfte Stufe der Kette: Der Griff zum Biom-Manager, die Biom-Analyse
## der Noise-Raster und die Mutation als Tick-Zustand.

var _biom_manager: Welt_BiomManager = null
var _biom_analyser: Welt_BiomAnalyser = null

func biom_raster_anlegen(z_ebene: int = 0) -> void:
	# Initialisiert biom_raster fuer die angegebene Z-Ebene.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	for y in range(raster_hoehe):
		for x in range(raster_breite):
			biom_raster["%d:%d:%d" % [x, y, z]] = "gemaaessigt"

func biom_setzen(neues_biom_id: String) -> bool:
	if _biom_manager == null:
		_biom_manager = Welt_BiomManager.new()
	if not _biom_manager.biom_wechseln(neues_biom_id):
		return false
	biom_id = neues_biom_id
	return true

func biom_manager() -> Welt_BiomManager:
	if _biom_manager == null:
		_biom_manager = Welt_BiomManager.new()
		_biom_manager.biom_wechseln(biom_id)
	return _biom_manager

func biom_zustand() -> Dictionary:
	# Einziger Ort der die Biom Mutation als Zustand ausfuehrt.
	var manager := biom_manager()
	var basis := {"biom_id": biom_id, "raster_breite": raster_breite, "raster_hoehe": raster_hoehe}
	return manager.zustand_fuer_tick(basis)

func biom_raster_schreiben(hoehe_raster: Array[float], feuchtigkeit_raster: Array[float], temperatur_raster: Array[float], z_ebene: int = 0) -> void:
	# Wendet die Biom-Analyse auf jedes Tile an und schreibt das biom_id
	# in das biom_raster. Dies ist das "separate Dictionary" parallel zum raster.
	if hoehe_raster.size() < raster_breite * raster_hoehe or feuchtigkeit_raster.size() < raster_breite * raster_hoehe or temperatur_raster.size() < raster_breite * raster_hoehe:
		push_warning("Biom-Analyzer: Noise-Rastergroesse stimmt nicht mit Welt-Raster überein.")
		return
	if _biom_analyser == null:
		_biom_analyser = Welt_BiomAnalyser.new()
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	for y in range(raster_hoehe):
		for x in range(raster_breite):
			var index := y * raster_breite + x
			var height := hoehe_raster[index]
			var moisture := feuchtigkeit_raster[index]
			var temperature := temperatur_raster[index]
			var ermitteltes_biom_id: String = _biom_analyser.analysiere_biom(height, moisture, temperature)
			biom_raster["%d:%d:%d" % [x, y, z]] = ermitteltes_biom_id
