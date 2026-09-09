extends Node2D
class_name Welt_Renderer
## Renderer, der ein Welt_Model in Node2D-Knoten übersetzt.
## Bietet neben dem vollen Neuaufbau inkrementelle Operationen, damit der
## Editor beim Drag & Drop nicht die ganze Karte neu zeichnet.
## Enthält keine Simulationslogik und keine Zustandsübergänge.
## Er liest ausschließlich die Datenklassen (Objekt_Basis und Unterklassen).

var _model: Welt_Model
var _registry: Welt_Registry
var _biome: Welt_BiomRegistry = null
var _fliesen_knoten: Node2D
var _objekte_knoten: Node2D

func _ready() -> void:
	_fliesen_knoten = Node2D.new()
	_fliesen_knoten.name = "Fliesen"
	_objekte_knoten = Node2D.new()
	_objekte_knoten.name = "Objekte"
	add_child(_fliesen_knoten)
	add_child(_objekte_knoten)

func darstellen(model: Welt_Model, registry: Welt_Registry, biome: Welt_BiomRegistry = null) -> void:
	_model = model
	_registry = registry
	_biome = biome if biome != null else Welt_BiomRegistry.new()
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
	sprite.position = _model.objekt_position(index)
	_objekte_knoten.add_child(sprite)
	return sprite

func objekt_knoten_verschieben(index: int, neue_position: Vector2) -> void:
	if index < 0 or index >= _objekte_knoten.get_child_count():
		return
	(_objekte_knoten.get_child(index) as Sprite2D).position = neue_position

func objekt_knoten_entfernen(index: int) -> void:
	if index < 0 or index >= _objekte_knoten.get_child_count():
		return
	_objekte_knoten.get_child(index).queue_free()

func objekt_knoten_anzahl() -> int:
	return _objekte_knoten.get_child_count()

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
	if _model == null:
		return
	for index in _model.objekt_anzahl():
		objekt_knoten_anhaengen(index)
