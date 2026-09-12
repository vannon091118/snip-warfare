extends Node2D
class_name Welt_Renderer
## Renderer, der ein Welt_Model in Node2D-Knoten übersetzt.
## Bietet neben dem vollen Neuaufbau inkrementelle Operationen, damit der
## Editor beim Drag & Drop nicht die ganze Karte neu zeichnet.
## Enthält keine Simulationslogik und keine Zustandsübergänge.
## Er liest ausschließlich die Datenklassen (Objekt_Basis und Unterklassen).
## Funktions-Animationen von Objekten laufen über den zentralen
## Welt_ObjektDarsteller, den die Registry-Einträge steuern.
## Tiefensortierung: Der Objekt-Container sortiert seine Kinder nach ihrem
## Fußpunkt. Die Reihenfolge im Modell entscheidet damit nichts mehr über die
## Zeichenreihenfolge; jeder Weltobjekt-Knoten trägt den Fußpunkt als Ursprung
## und das Bewegtbild als eigenes Kind, damit es mit seinem Standbild zusammen
## sortiert wird.
##
## Z-Layer Erweiterung: Pro Z-Ebene (0, -1, -2, -3, -4) ein eigener
## _fliesen_knoten als Geschwister-Knoten. Sichtbarkeit wird über
## z_ebene_setzen() umgeschaltet. Nur die aktive Ebene wird gerendert.

const OBJEKT_DARSTELLER_SKRIPT := preload("res://world/logic/kategorie_welt/welt_objekt_darsteller.gd")
const SWAY_AKTUALISIERER_SKRIPT := preload("res://world/logic/kategorie_atmosphaere/welt_sway_aktualisierer.gd")
const STUFEN_BILDER_SKRIPT := preload("res://world/logic/kategorie_progression/welt_stufen_bilder.gd")
const PROGRESSIONS_REGISTRY_SKRIPT := preload("res://world/logic/kategorie_progression/welt_progressions_registry.gd")
const RESSOURCEN_ZUSTAND_SKRIPT := preload("res://world/logic/kategorie_progression/welt_ressourcen_zustand.gd")
const BAUSTELLEN_BEDARF_SKRIPT := preload("res://world/logic/kategorie_welt/welt_baustellen_bedarf.gd")
const BAU_GEIST_SKRIPT := preload("res://world/logic/kategorie_welt/welt_bau_geist.gd")

var _model: Welt_Model
var _registry: Welt_Registry
var _biome: Welt_BiomRegistry = null
## Dictionary: z_ebene (0, -1, -2, ...) -> Node2D (Fliesen-Container für diese Ebene)
var _fliesen_knoten_pro_ebene: Dictionary = {}
var _objekte_knoten: Node2D
var _objekt_darsteller: Welt_ObjektDarsteller
var _sway_aktualisierer := SWAY_AKTUALISIERER_SKRIPT.new()
var _sway_material_quelle: Callable = func() -> RefCounted: return null
var _stufen_bilder := STUFEN_BILDER_SKRIPT.new()
var _terrain_blatt := Welt_TerrainBlatt.new()
var _progressions_registry := PROGRESSIONS_REGISTRY_SKRIPT.new()
var _ressourcen_zustand := RESSOURCEN_ZUSTAND_SKRIPT.new()
var _baustellen_bedarf := BAUSTELLEN_BEDARF_SKRIPT.new()
## Rueckschnitt: Die Szene reicht die Progressions-Maschine herein, damit
## der Renderer jeden echten Stadiumswechsel sofort am Sprite zeigt.
var _progressions_maschine: Object = null

## Aktuell sichtbare Z-Ebene (0 = Oberfläche, negativ = Untergrund)
var _aktive_z_ebene: int = 0

## Sichtbarkeits-Scheibe: Nur Objekte im Kamera-Bereich haengen als Knoten.
## Das Modell bleibt die volle Wahrheit; der Knotenbestand folgt dem Blick.
## Ohne gesetzten Bereich (Editor) haengt der Renderer alles, wie bisher.
const SICHT_RAND_PX := 384.0
const SCAN_SCHRITT_PX := 64.0
const MAX_ANHAENGE_PRO_RUF := 256
var _sichtbereich := Rect2()
var _scan_mitte := Vector2.INF
var _sichtgebiet_dirty := true
var _knoten_nach_id: Dictionary = {}
## Slice B: Räumlicher Vorfilter – ersetzt linearen Vollscan in _sichtbar_anwenden().
var _objekt_gitter := Welt_ObjektGitter.new()


func _ready() -> void:
	y_sort_enabled = true
	_objekte_knoten = Node2D.new()
	_objekte_knoten.name = "Objekte"
	# Der Objekt-Container sortiert nach der Fußposition und reicht die
	# Sortierung über den gemeinsamen Y-Sort-Knoten an die Szene weiter.
	_objekte_knoten.y_sort_enabled = true
	_objekt_darsteller = OBJEKT_DARSTELLER_SKRIPT.new()
	add_child(_objekte_knoten)
	# Fliesen-Knoten für alle Z-Ebenen erstellen (0 bis -4)
	for z in range(Welt_Model.MAX_Z_EBENEN):
		var z_ebene := -z
		var knoten := Node2D.new()
		knoten.name = "Fliesen_Z%d" % z_ebene
		knoten.z_index = -1
		knoten.visible = (z_ebene == 0)  # Nur Oberfläche initial sichtbar
		_fliesen_knoten_pro_ebene[z_ebene] = knoten
		add_child(knoten)

func _fliesen_knoten_fuer_ebene(z_ebene: int) -> Node2D:
	return _fliesen_knoten_pro_ebene.get(z_ebene, null)

func z_ebene_setzen(z_ebene: int) -> void:
	# Schaltet die sichtbare Z-Ebene um: Blendet alle Fliesen-Knoten aus,
	# zeigt nur den der angeforderten Ebene.
	_aktive_z_ebene = clampi(z_ebene, -Welt_Model.MAX_Z_EBENEN + 1, 0)
	for ebene in _fliesen_knoten_pro_ebene:
		var knoten: Node2D = _fliesen_knoten_pro_ebene[ebene] as Node2D
		knoten.visible = (ebene == _aktive_z_ebene)
	# Modell auch auf die Ebene setzen für kachel_ersetzen etc.
	if _model != null:
		_model.z_ebene_setzen(_aktive_z_ebene)

func z_ebene_holen() -> int:
	return _aktive_z_ebene

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

func _auf_folge_objekt(index: int, element_id: String) -> void:
	_sichtgebiet_dirty = true
	# Der Rest ist wiedergeboren: Das Standbild braucht seine neue Textur und
	# der Knoten an dieser Stelle ein frisches Bewegtbild.
	_zeige_stadium(index)
	var knoten := _knoten_fuer(index)
	if knoten == null or _objekt_darsteller == null or _registry == null or _model == null:
		return
	# Die neue Kennung kommt aus dem Ereignis; fehlt sie, gilt der Modellwert.
	var neue_kennung := element_id if element_id != "" else _model.objekt_element_id(index)
	var eintrag := _registry.finde_objekt(neue_kennung)
	knoten.bewegtbild_setzen(_objekt_darsteller.objekt_darstellen(eintrag, knoten.fusspunkt()))

func _auf_saemling(_element_id: String, _position: Vector2) -> void:
	_sichtgebiet_dirty = true
	# Ein neuer Saemling steht irgendwo: Der naechste volle Neuaufbau waere
	# teuer, deshalb haengt der Renderer nur das eine neue Objekt an. Der
	# Behälter des Modells entscheidet, ob es diesen Knoten schon gibt.
	if _model == null:
		return
	var index := _model.objekt_anzahl() - 1
	if index < 0 or _knoten_fuer(index) != null:
		return
	objekt_knoten_anhaengen(index)

func _knoten_fuer(index: int) -> Welt_ObjektKnoten:
	# Der Datenbehälter des Modells ist der Schlüssel: Er bleibt derselbe, auch
	# wenn sich die Reihenfolge der Objektliste verschiebt. Die Id des Objekts
	# ist der direkte Weg zum Knoten, ohne Kinderlauf je Anfrage.
	if _model == null or index < 0 or index >= _model.objekt_anzahl():
		return null
	var id := str(_model.objekt_feld(index, "id", index))
	var knoten := _knoten_nach_id.get(id) as Welt_ObjektKnoten
	if knoten != null and is_instance_valid(knoten):
		return knoten
	return null

func _zeige_stadium(index: int) -> void:
	# Tauscht nur das Blatt des Objekt-Knotens am gegebenen Index: keine
	# Neuanlage, kein Neuaufbau, der Zustand wohnt weiter im Modell.
	var knoten := _knoten_fuer(index)
	if knoten == null:
		return
	var textur := _stufen_textur_fuer(index)
	if textur == null:
		textur = _textur_fuer(_model.objekt_element_id(index))
	if textur != null:
		knoten.standbild_setzen(textur)

func darstellen(model: Welt_Model, registry: Welt_Registry, biome: Welt_BiomRegistry = null) -> void:
	_progressions_registry.laden()
	# Die Blattgeometrie der Stufen-Sheets kommt aus demselben Datenpool wie
	# die Stufen selbst: keine zweite Zellgröße im Renderer.
	_stufen_bilder.einrichten(_progressions_registry)
	_ressourcen_zustand.einrichten(_progressions_registry)
	_model = model
	_registry = registry
	_baustellen_bedarf.einrichten(_model)
	_biome = biome if biome != null else Welt_BiomRegistry.new()
	# Sway-Spitze der Atmosphären-Domäne: Der Renderer kennt nur den
	# Aktualisierer, die Wind-Details liegen in der eigenen Domäne. Jeder
	# Neuaufbau sammelt die Materials der frischen Sprites neu.
	_sway_aktualisierer.einrichten(_sway_material_quelle.call())
	# Fliesen für ALLE Z-Ebenen aufbauen (einmalig bei darstellen()), sichtbar wird nur aktive
	_fliesen_alle_ebenen_erneuern()
	_objekte_erneuern()
	## Slice B: Gitter nach vollständigem Neuaufbau initialisieren.
	_objekt_gitter.aufbauen(_model)


func kachel_ersetzen(x: int, y: int, z_ebene: int = 0) -> void:
	if _model == null:
		return
	var z := z_ebene if z_ebene != 0 else _aktive_z_ebene
	var fliesen_knoten := _fliesen_knoten_fuer_ebene(z)
	if fliesen_knoten == null:
		return
	var kachel_index := y * _model.raster_breite + x
	if kachel_index < 0 or kachel_index >= fliesen_knoten.get_child_count():
		return
	# Einzelkachel: derselbe Weg wie beim vollen Aufbau, damit Variante und
	# Maßstab nie auseinanderlaufen. Der Knoten bleibt an seinem Platz, weil
	# der Index die Kachelposition im Raster ist.
	var sprite := fliesen_knoten.get_child(kachel_index) as Sprite2D
	if sprite == null:
		return
	sprite.position = Vector2(x, y) * float(_model.kachel_groesse)
	_fliese_anwenden(sprite, x, y, z, float(_model.kachel_groesse))

func _fliesen_alle_ebenen_erneuern() -> void:
	# Baut Fliesen für ALLE Z-Ebenen auf (einmalig bei darstellen())
	if _model == null:
		return
	var kante := float(_model.kachel_groesse)
	for z in range(Welt_Model.MAX_Z_EBENEN):
		var z_ebene := -z
		var fliesen_knoten := _fliesen_knoten_fuer_ebene(z_ebene)
		if fliesen_knoten == null:
			continue
		# Kinder löschen
		for kind: Node in fliesen_knoten.get_children():
			kind.queue_free()
		# Neu aufbauen
		for y in _model.raster_hoehe:
			for x in _model.raster_breite:
				_fliese_anhaengen(fliesen_knoten, x, y, z_ebene, kante)

func _fliese_anhaengen(fliesen_knoten: Node2D, x: int, y: int, z_ebene: int, kante: float) -> void:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = Vector2(x, y) * kante
	_fliese_anwenden(sprite, x, y, z_ebene, kante)
	fliesen_knoten.add_child(sprite)

func _fliese_anwenden(sprite: Sprite2D, x: int, y: int, z_ebene: int, kante: float) -> void:
	# Eine Kachel: Bild aus dem Katalog, Variante aus dem Terrain-Blatt,
	# Tönung aus Biom und Kachel-Daten. Fehlt das Bild, tritt ein sichtbarer
	# Platzhalter an seine Stelle (Regel 7: lieber sichtbar als leer).
	if sprite == null or _model == null:
		return
	var element_id := _model.fliese(x, y, z_ebene)
	var kachel := _kachel_daten(element_id)
	var biom_farbe := _biom_farbe_fuer_kachel(x, y, z_ebene)
	var textur := _textur_fuer(element_id)
	if textur == null:
		textur = _platzhalter_textur(biom_farbe)
	sprite.texture = textur
	if textur.get_width() > 0 and textur.get_height() > 0:
		sprite.scale = Vector2(kante / float(textur.get_width()), kante / float(textur.get_height()))
	var entscheidung := _terrain_blatt.entscheidung_fuer(kachel, x, y, _model.welt_seed)
	sprite.flip_h = bool(entscheidung.get("spiegel_x", false))
	sprite.flip_v = bool(entscheidung.get("spiegel_y", false))
	sprite.self_modulate = biom_farbe * (entscheidung.get("toenumg", Color.WHITE) as Color)

func _biom_farbe_fuer_kachel(x: int, y: int, z_ebene: int) -> Color:
	# Biom-Tönung aus der Biom-Registry: Jede Kachel trägt die Farbe ihres
	# Region-Bioms. Keine zweite Biomlogik, nur das gefrorene farbe-Feld.
	if _biome == null or _model == null:
		return Color.WHITE
	var biom := _biome.biom_fuer(_model.biom_an_kachel(x, y, z_ebene))
	if biom == null:
		return Color.WHITE
	return Color.from_string(biom.farbe, Color.WHITE)

func _kachel_daten(element_id: String) -> Objekt_Kachel:
	if _registry == null:
		return null
	var eintrag := _registry.finde_objekt(element_id)
	if eintrag is Objekt_Kachel:
		return eintrag as Objekt_Kachel
	return null

func _platzhalter_textur(farbe: Color) -> Texture2D:
	var bild := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	bild.fill(farbe)
	return ImageTexture.create_from_image(bild)

func objekt_knoten_anhaengen(index: int) -> Welt_ObjektKnoten:
	if _model == null:
		return null
	# Tiere (typ bewegt) zeichnet der Tier_Manager selbst mit Status und
	# Bewegung; der Renderer darf sie nicht doppelt malen.
	var eintrag := _registry.finde_objekt(_model.objekt_element_id(index)) if _registry != null else null
	if eintrag != null and eintrag.typ == &"bewegt":
		return null
	# Ein Knoten je Objekt: Sein Ursprung ist der Fußpunkt, damit der
	# tiefensortierte Container nach Fußposition zeichnet.
	var fusspunkt := _model.objekt_position(index)
	var knoten := Welt_ObjektKnoten.new()
	knoten.name = "Objekt_%d" % int(_model.objekt_feld(index, "id", index))
	knoten.daten_setzen(_model.objekt_daten(index))
	knoten.fusspunkt_setzen(fusspunkt)
	_objekte_knoten.add_child(knoten)
	_knoten_nach_id[str(_model.objekt_feld(index, "id", index))] = knoten
	var textur := _stufen_textur_fuer(index)
	if textur == null:
		textur = _textur_fuer(_model.objekt_element_id(index))
	var sprite := knoten.standbild_setzen(textur)
	var bau_phase := int(_model.objekt_feld(index, "bau_phase", Gebaeude_BauMaschine.Phase.NICHT_GEBAUT))
	if bau_phase == Gebaeude_BauMaschine.Phase.BAUPLAN:
		var geist: Node2D = BAU_GEIST_SKRIPT.new()
		geist.name = "BauGeist"
		geist.call("einrichten", textur)
		var anteil: float = _baustellen_bedarf.bedarf_anteil(index) if _baustellen_bedarf != null else 0.0
		geist.call("bedarf_aktualisieren", anteil)
		knoten.add_child(geist)
		if sprite != null:
			sprite.visible = false
	# Wind-Sway als Datenentscheidung des Katalogs: Nur Eintraege mit
	# wind_sway erhalten ein Material und wedeln spaeter; Details in der
	# Sway-Spitze der Atmosphaeren-Domaene.
	if eintrag != null and _sway_aktualisierer != null:
		(_sway_aktualisierer as Object).call("sprite_verwenden", sprite, eintrag)
	# Funktions-Animation über die zentrale Objekt-Darstellungs-Spitze:
	# Nur Einträge mit Registry-Animation erhalten ein Bewegtbild. Es hängt
	# am Objekt-Knoten und wird deshalb mit seinem Standbild zusammen
	# sortiert; das Standbild bleibt immer der erste Frame desselben Sheets.
	if eintrag != null and _objekt_darsteller != null:
		knoten.bewegtbild_setzen(_objekt_darsteller.objekt_darstellen(eintrag, fusspunkt))
	return knoten

func objekt_knoten_verschieben(index: int, neue_position: Vector2) -> void:
	# Der Fußpunkt ist die einzige Wahrheit der Zeichnung: Das Standbild und
	# das Bewegtbild des Knotens hängen daran und wandern mit.
	var knoten := _knoten_fuer(index)
	if knoten == null:
		return
	knoten.fusspunkt_setzen(neue_position)

func objekt_knoten_entfernen(index: int) -> void:
	# Der Knoten wird über die Objekt-Id gesucht: Der muss zum Zeitpunkt
	# des Entfernens noch im Modell stehen, sonst gibt es keine Zuordnung mehr.
	var knoten := _knoten_fuer(index)
	if knoten == null:
		return
	_knoten_nach_id.erase(str(_model.objekt_feld(index, "id", index)))
	knoten.queue_free()

func objekt_knoten_anzahl() -> int:
	# Anzahl der tatsächlich gezeichneten Objekt-Knoten. Tiere (typ bewegt)
	# zählt der Tier_Manager, deshalb ist das nicht die Objektzahl des Modells.
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

func _objekte_erneuern() -> void:
	# Der Objekt-Container trägt ausschließlich Weltobjekt-Knoten; die
	# alten werden vor dem Neuaufbau freigegeben.
	for kind: Node in _objekte_knoten.get_children():
		kind.queue_free()
	_knoten_nach_id.clear()
	if _model == null:
		return
	if _sichtbereich.size != Vector2.ZERO:
		# Spielbetrieb: Der Knotenbestand entsteht aus dem Sichtbereich;
		# der nächste sichtbereich_setzen-Ruf hängt die sichtbaren an.
		_sichtgebiet_dirty = true
		return
	for index in _model.objekt_anzahl():
		objekt_knoten_anhaengen(index)

## Kategorie logik: Sichtbarkeits-Scheibe des Knotenbestands.

func sichtbereich_setzen(rechteck: Rect2) -> void:
	# Die Szene reicht je Rahmen den Kamera-Bereich samt Rand hinein. Ein
	# neuer Abgleich läuft nur bei echtem Blickwechsel oder Modelländerung,
	# nicht bei stillstehender Kamera.
	_sichtbereich = rechteck
	var mitte := rechteck.get_center()
	if _sichtgebiet_dirty or _scan_mitte.distance_to(mitte) >= SCAN_SCHRITT_PX:
		_scan_mitte = mitte
		_sichtgebiet_dirty = false
		_sichtbar_anwenden()

func sichtbereich_deaktivieren() -> void:
	# Der Editor und Prüfläufe ohne Kamera hängen alles an, wie bisher.
	_sichtbereich = Rect2()

func sichtgebiet_aktualisieren() -> void:
	# Erzwingt den Neuabgleich der sichtbaren Objekte bei Gebäudeplatzierung
	# oder Spawn-Ereignissen, ohne auf Kamerabewegung warten zu müssen.
	## Slice B: Gitter nach Gebäudeplatzierung neu aufbauen, damit das neue
	## Objekt in den richtigen Zellen auftaucht.
	_objekt_gitter.aufbauen(_model)
	_sichtgebiet_dirty = true
	if _sichtbereich.size != Vector2.ZERO:
		_sichtbar_anwenden()


func _sichtbar_anwenden() -> void:
	if _model == null or _sichtbereich.size == Vector2.ZERO:
		return
	if _objekt_gitter.ist_leer():
		_objekt_gitter.aufbauen(_model)
	var anhaenge := 0
	var kandidaten := _objekt_gitter.kandidaten_in(_sichtbereich)
	for index in kandidaten:
		if anhaenge >= MAX_ANHAENGE_PRO_RUF:
			break
		if not _sichtbereich.has_point(_model.objekt_position(index)):
			continue
		var id := str(_model.objekt_feld(index, "id", index))
		if _knoten_nach_id.has(id):
			continue
		objekt_knoten_anhaengen(index)
		anhaenge += 1
	for id: String in _knoten_nach_id.keys():
		var knoten := _knoten_nach_id[id] as Welt_ObjektKnoten
		if knoten == null or not is_instance_valid(knoten):
			_knoten_nach_id.erase(id)
			continue
		if not _sichtbereich.has_point(knoten.fusspunkt()):
			_knoten_nach_id.erase(id)
			knoten.queue_free()