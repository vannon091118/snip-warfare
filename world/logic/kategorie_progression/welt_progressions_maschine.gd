extends Node2D
class_name Welt_ProgressionsMaschine
## Tick-Maschine der Ressourcen-Progression: Sie haengt an der zentralen
## Weltuhr, tickt das Wachstum wachsender Objekte mit dem Warmefaktor der
## Tageszyklus-Maschine, laesst Rest-Objekte regenerieren und ruft die
## Seed-Spawn-Maschine je Taktwechsel zum Tag. Der Zustand wohnt im
## Welt_Model, die Darstellung lesen Renderer und Darsteller daraus.

## Kategorie ausgang: sichtbare Ereignisse fuer Renderer und Feedback.
signal stadium_geaendert(index: int, element_id: String, stadium: String)
signal objekt_erschoepft(index: int, element_id: String, welt_position: Vector2)
signal folge_objekt_entstanden(index: int, element_id: String)
signal saemling_gespawnt(element_id: String, welt_position: Vector2)

## Kategorie daten: die kombinierten Maschinen und der Zyklen-Zustand.
var _registry := Welt_ProgressionsRegistry.new()
var _zustand := Welt_RessourcenZustand.new()
var _waerme := Welt_WaermeFaktor.new()
var _spawn := Welt_SeedSpawnMaschine.new()
var _model: Welt_Model = null
var _biome: Welt_BiomRegistry = null
var _tageszyklus: Welt_TageszyklusMaschine = null
var _takt_zaehler: int = 0
var _need_registry: Pop_NeedRegistry = null
var _takt_ticks: int = 1

## Kategorie logik: Einrichten, Tick und Tag-Wechsel.

func einrichten(model: Welt_Model, biome: Welt_BiomRegistry, tageszyklus: Welt_TageszyklusMaschine) -> void:
	_registry.laden()
	_zustand.einrichten(_registry)
	_waerme.einrichten(_registry)
	_need_registry = Pop_NeedRegistry.new()
	_takt_ticks = maxi(Kern_Weltuhr.ticks_aus_minuten(_need_registry.takt_minuten()), 1)
	_model = model
	_biome = biome
	_tageszyklus = tageszyklus
	var start_seed := model.welt_seed if model != null else 0
	_spawn.einrichten(_registry, float(model.kachel_groesse) if model != null else float(Welt_Model.KACHEL_GROESSE), start_seed)
	for index in model.objekt_anzahl():
		_zustand.zustand_erneuern(index, model)

func bestand(index: int) -> int:
	return _zustand.bestand(index, _model)

func stadium(index: int) -> String:
	return _zustand.stadium(index, _model)

func schlag(index: int) -> Dictionary:
	var ereignis := _zustand.schlag(index, _model)
	if ereignis.is_empty():
		return {}
	if bool(ereignis.get("erschoepft", false)):
		objekt_erschoepft.emit(index, str(ereignis.get("element_id", "")), ereignis.get("position", Vector2.ZERO) as Vector2)
		# Erschoepfte wachsende Objekte werden zu ihrem Rest-Objekt: Die
		# Identitaet wechselt an derselben Stelle, die Position bleibt.
		var element_id := str(ereignis.get("element_id", ""))
		var folge_id := _registry.folge_objekt_fuer(element_id)
		if folge_id != "" and _model != null and index >= 0 and index < _model.objekt_anzahl():
			_model.objekt_feld_setzen(index, "element_id", folge_id)
			_model.objekt_feld_setzen(index, "ressource_stadium", "")
			_model.objekt_feld_setzen(index, "ressource_bestand", -1)
			_model.objekt_feld_setzen(index, "ressource_staerke", -1)
			_model.objekt_feld_setzen(index, "ressource_wachstum", 0)
			_model.objekt_feld_setzen(index, "regeneration_fortschritt", 0)
			_zustand.zustand_erneuern(index, _model)
			folge_objekt_entstanden.emit(index, folge_id)
	return ereignis

func _enter_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_uhr_tick):
		weltuhr.tick.connect(_auf_uhr_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_uhr_tick):
		weltuhr.tick.disconnect(_auf_uhr_tick)

func _auf_uhr_tick(_tick_nummer: int, _delta: float) -> void:
	if _model == null or _registry == null:
		return
	_takt_zaehler += 1
	var helligkeit := 1.0 if _tageszyklus == null else _tageszyklus.helligkeit()
	var waerme_faktor := _waerme.faktor_fuer_helligkeit(helligkeit)
	for index in _model.objekt_anzahl():
		_zustand.zustand_erneuern(index, _model)
		var ereignis := _zustand.wachstum_ticken(index, _model, waerme_faktor)
		if not ereignis.is_empty():
			stadium_geaendert.emit(index, str(ereignis.get("element_id", "")), str(ereignis.get("stadium", "")))
			continue
		var folge := _zustand.regeneration_ticken(index, _model)
		if folge != "":
			stadium_geaendert.emit(index, folge, _zustand.stadium(index, _model))
			folge_objekt_entstanden.emit(index, folge)
	# Tag-Wechsel: Der Takt des Weltrhythmus aus der Need-Registry ist die
	# gemeinsame Tageslaenge; nach jedem vollen Takt spawnt der Nachwuchs.
	if _takt_zaehler % _takt_ticks != 0:
		return
	for ereignis: Dictionary in _spawn.tag_spawnen(_model, _biome):
		saemling_gespawnt.emit(str(ereignis.get("element_id", "")), ereignis.get("position", Vector2.ZERO) as Vector2)
