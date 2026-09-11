extends Node2D
class_name Welt_Renderer
## Renderer, der ein Welt_Model in Node2D-Knoten übersetzt.
## Bietet neben dem vollen Neuaufbau inkrementelle Operationen, damit der
## Editor beim Drag & Drop nicht die ganze Karte neu zeichnet.
## Enthält keine Simulationslogik und keine Zustandsübergänge.
## Er liest ausschließlich die Datenklassen (Objekt_Basis und Unterklassen).
## Funktions-Animationen von Objekten laufen über den zentralen
## Welt_ObjektDarsteller, den die Registry-Einträge steuern.

const OBJEKT_DARSTELLER_SKRIPT := preload("res://world/logic/kategorie_welt/welt_objekt_darsteller.gd")
const SWAY_AKTUALISIERER_SKRIPT := preload("res://world/logic/kategorie_atmosphaere/welt_sway_aktualisierer.gd")
const STUFEN_BILDER_SKRIPT := preload("res://world/logic/kategorie_progression/welt_stufen_bilder.gd")
const PROGRESSIONS_REGISTRY_SKRIPT := preload("res://world/logic/kategorie_progression/welt_progressions_registry.gd")
const RESSOURCEN_ZUSTAND_SKRIPT := preload("res://world/logic/kategorie_progression/welt_ressourcen_zustand.gd")

var _model: Welt_Model
var _registry: Welt_Registry
var _biome: Welt_BiomRegistry = null
var _fliesen_knoten: Node2D
var _objekte_knoten: Node2D
var _objekt_darsteller: Welt_ObjektDarsteller
var _sway_aktualisierer := SWAY_AKTUALISIERER_SKRIPT.new()
var _sway_material_quelle: Callable = func() -> RefCounted: return null
var _stufen_bilder := STUFEN_BILDER_SKRIPT.new()
var _progressions_registry := PROGRESSIONS_REGISTRY_SKRIPT.new()
var _ressourcen_zustand := RESSOURCEN_ZUSTAND_SKRIPT.new()
## Rueckschnitt: Die Szene reicht die Progressions-Maschine herein, damit
## der Renderer jeden echten Stadiumswechsel sofort am Sprite zeigt.
var _progressions_maschine: Object = null

func _ready() -> void:
	_fliesen_knoten = Node2D.new()
	_fliesen_knoten.name = "Fliesen"
	_objekte_knoten = Node2D.new()
	_objekte_knoten.name = "Objekte"
	_objekt_darsteller = OBJEKT_DARSTELLER_SKRIPT.new()
	_objekt_darsteller.name = "ObjektDarsteller"
	add_child(_fliesen_knoten)
	add_child(_objekte_knoten)
	add_child(_objekt_darsteller)

func sway_material_quelle_setzen(quelle: Callable) -> void:
	# Die Atmosphären-Domäne reicht ihre Sway-Material-Spitze herein; der
	# Renderer ruft sie beim Aufbau der Sprites, ohne die Domäne zu kennen.
	_sway_material_quelle = quelle

func progressions_maschine_setzen(maschine: Object) -> void:
	# Die Progressions-Domäne meldet jedes echte Stadiums-Ereignis; der
	# Renderer tauscht dann nur das Blatt des betroffenen Sprites.
	_progressions_maschine = maschine as Object
	if _progressions_maschine != null and _progressions_maschine.has_signal("stadium_geaendert"):
		_progressions_maschine.connect("stadium_geaendert", _auf_stadium_geaendert)
		_progressions_maschine.connect("folge_objekt_entstanden", _auf_folge_objekt)
		_progressions_maschine.connect("saemling_gespawnt", _auf_saemling)

func sway_aktualisierer() -> RefCounted:
	return _sway_aktualisierer

func _auf_stadium_geaendert(index: int, _element_id: String, _stadium: String) -> void:
	_zeige_stadium(index)

func _auf_folge_objekt(index: int, _element_id: String) -> void:
	# Der Rest ist wiedergeboren: Das Sprite braucht seine neue Textur und
	# der Darsteller an dieser Stelle einen Neustart.
	_zeige_stadium(index)
	if _objekt_darsteller != null and _model != null:
		_objekt_darsteller.objekt_entfernen(_model.objekt_position(index))
		var eintrag := _registry.finde_objekt(_model.objekt_element_id(index))
		if eintrag != null and eintrag.funktions_animation != "":
			_objekt_darsteller.objekt_darstellen(eintrag, _model.objekt_position(index))

func _auf_saemling(_element_id: String, _position: Vector2) -> void:
	# Ein neuer Saemling steht irgendwo: Der naechste volle Neuaufbau waere
	# teuer, deshalb haengt der Renderer nur das eine neue Objekt an.
	if _model == null:
		return
	var frische_zahl := _model.objekt_anzahl()
	for schritt in mini(8, frische_zahl):
		var pruef_index := frische_zahl - 1 - schritt
		if _objekte_knoten.get_child_count() <= pruef_index:
			objekt_knoten_anhaengen(pruef_index)

func _zeige_stadium(index: int) -> void:
	# Tauscht nur das Blatt des Sprites am gegebenen Objekt-Index: keine
	# Neuanlage, kein Neuaufbau, der Zustand wohnt weiter im Modell.
	if _model == null or index < 0 or index >= _objekte_knoten.get_child_count():
		return
	var sprite := _objekte_knoten.get_child(index) as Sprite2D
	if sprite == null:
		return
	var textur := _stufen_textur_fuer(index)
	if textur != null:
		sprite.texture = textur

func darstellen(model: Welt_Model, registry: Welt_Registry, biome: Welt_BiomRegistry = null) -> void:
	_progressions_registry.laden()
	_ressourcen_zustand.einrichten(_progressions_registry)
	_model = model
	_registry = registry
	_biome = biome if biome != null else Welt_BiomRegistry.new()
	# Sway-Spitze der Atmosphären-Domäne: Der Renderer kennt nur den
	# Aktualisierer, die Wind-Details liegen in der eigenen Domäne. Jeder
	# Neuaufbau sammelt die Materials der frischen Sprites neu.
	_sway_aktualisierer.einrichten(_sway_material_quelle.call())
	_fliesen_erneuern()
	_objekte_erneuern()

func kachel_ersetzen(x: int, y: int) -> void:
	if _model == null:
		return
	var kachel_index := y * _model.raster_breite + x
	if kachel_index < 0 or kachel_index >= _fliesen_knoten.get_child_count():
		return
	var sprite := _fliesen_knoten.get_child(kachel_index) as Sprite2D
	sprite.texture = _textur_fuer(_model.fliese(x, y))

func objekt_knoten_anhaengen(index: int) -> Sprite2D:
	if _model == null:
		return null
	# Tiere (typ bewegt) zeichnet der Tier_Manager selbst mit Status und
	# Bewegung; der Renderer darf sie nicht doppelt malen.
	var eintrag := _registry.finde_objekt(_model.objekt_element_id(index)) if _registry != null else null
	if eintrag != null and eintrag.typ == &"bewegt":
		return null
	var sprite := Sprite2D.new()
	sprite.texture = _textur_fuer(_model.objekt_element_id(index))
	var stufen_textur := _stufen_textur_fuer(index)
	if stufen_textur != null:
		sprite.texture = stufen_textur
	sprite.position = _model.objekt_position(index)
	_objekte_knoten.add_child(sprite)
	# Wind-Sway als Datenentscheidung des Katalogs: Nur Eintraege mit
	# wind_sway erhalten ein Material und wedeln spaeter; Details in der
	# Sway-Spitze der Atmosphaeren-Domaene.
	if eintrag != null and _sway_aktualisierer != null:
		(_sway_aktualisierer as Object).call("sprite_verwenden", sprite, eintrag)
	# Funktions-Animation über die zentrale Objekt-Darstellungs-Spitze:
	# Nur Einträge mit Registry-Animation erhalten ein Bewegtbild; das
	# Standbild bleibt immer der erste Frame desselben Sheets.
	if eintrag != null and _objekt_darsteller != null:
		_objekt_darsteller.objekt_darstellen(eintrag, sprite.position)
	return sprite

func objekt_knoten_verschieben(index: int, neue_position: Vector2) -> void:
	if index < 0 or index >= _objekte_knoten.get_child_count():
		return
	(_objekte_knoten.get_child(index) as Sprite2D).position = neue_position

func objekt_knoten_entfernen(index: int) -> void:
	if index < 0 or index >= _objekte_knoten.get_child_count():
		return
	_objekte_knoten.get_child(index).queue_free()
	if _objekt_darsteller != null:
		_objekt_darsteller.objekt_entfernen(_model.objekt_position(index))

func objekt_knoten_anzahl() -> int:
	return _objekte_knoten.get_child_count()

func _stufen_textur_fuer(index: int) -> Texture2D:
	# Sichtbare Stufe aus dem echten Zustand: Die Maschine liest nur die
	# Objekt-Felder des Modells; ohne Registry-Definition bleibt es das
	# normale Katalog-Bild.
	if _model == null or index < 0 or index >= _model.objekt_anzahl():
		return null
	var element_id := _model.objekt_element_id(index)
	if not _progressions_registry.hat_definition(element_id):
		return null
	_ressourcen_zustand.zustand_erneuern(index, _model)
	var definition := _progressions_registry.definition_fuer(element_id)
	var stadien: Array = definition.get("stadien", [])
	var kategorie := str(definition.get("kategorie", ""))
	var staerke := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_STAERKE, 1))
	var bestand := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_BESTAND, staerke))
	var wachstum := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_WACHSTUM, 0))
	var dauer := int(definition.get("wachstums_ticks", 0))
	var stufen_index := _stufen_bilder.stadien_index_fuer(kategorie, stadien.size(), bestand, staerke, wachstum, dauer)
	return _stufen_bilder._blatt_fuer(element_id, stufen_index)

func _textur_fuer(element_id: String) -> Texture2D:
	# Nur Daten lesen: der Renderer kennt die Objekte über die Registry.
	if _registry == null:
		return null
	var objekt := _registry.finde_objekt(element_id)
	if objekt == null:
		return null
	var pfad := objekt.textur_pfad
	if not ResourceLoader.exists(pfad):
		return null
	var textur: Texture2D = load(pfad)
	# Sprite-Sheets (bewegte Objekte): nur den ersten Frame darstellen.
	if objekt.schluessel_daten.has("frame_breite") and objekt.schluessel_daten.has("frame_hoehe"):
		var atlas := AtlasTexture.new()
		atlas.atlas = textur
		atlas.region = Rect2(0, 0, float(objekt.schluessel_daten["frame_breite"]), float(objekt.schluessel_daten["frame_hoehe"]))
		return atlas
	# Funktions-Animation: das Standbild bleibt der erste Frame des Sheets,
	# damit Editor, Vorschau und Karte dasselbe Bild zeigen.
	if objekt.funktions_animation != "":
		var anim_atlas := AtlasTexture.new()
		anim_atlas.atlas = textur
		anim_atlas.region = Rect2(0, 0, objekt.anzeige_breite, objekt.anzeige_hoehe)
		return anim_atlas
	return textur

func _biom_farbe_fuer_kachel(x: int, y: int) -> Color:
	# Biom-Tönung aus der Biom-Registry: Jede Kachel trägt die Farbe ihres
	# Region-Bioms. Keine zweite Biomlogik, nur das gefrorene farbe-Feld.
	if _biome == null or _model == null:
		return Color.WHITE
	var biom := _biome.biom_fuer(_model.biom_an_kachel(x, y))
	if biom == null:
		return Color.WHITE
	return Color.from_string(biom.farbe, Color.WHITE)

func _fliesen_erneuern() -> void:
	for kind: Node in _fliesen_knoten.get_children():
		kind.queue_free()
	if _model == null:
		return
	for y in _model.raster_hoehe:
		for x in _model.raster_breite:
			var sprite := Sprite2D.new()
			sprite.texture = _textur_fuer(_model.fliese(x, y))
			sprite.centered = false
			sprite.position = Vector2(x, y) * Welt_Model.KACHEL_GROESSE
			sprite.self_modulate = _biom_farbe_fuer_kachel(x, y)
			_fliesen_knoten.add_child(sprite)

func _objekte_erneuern() -> void:
	for kind: Node in _objekte_knoten.get_children():
		kind.queue_free()
	if _objekt_darsteller != null:
		for kind: Node in _objekt_darsteller.get_children():
			kind.queue_free()
	if _model == null:
		return
	for index in _model.objekt_anzahl():
		objekt_knoten_anhaengen(index)
