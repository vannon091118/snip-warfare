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
const KACHEL_GESTE_SKRIPT := preload("res://world/logic/kategorie_welt/welt_kachel_geste.gd")
const STADIUM_GESTE_SKRIPT := preload("res://world/logic/kategorie_welt/welt_stadium_geste.gd")
const WUCHS_GESTE_SKRIPT := preload("res://world/logic/kategorie_welt/welt_wuchs_geste.gd")
const RISS_GESTE_SKRIPT := preload("res://world/logic/kategorie_welt/welt_riss_geste.gd")
const UMSTURZ_GESTE_SKRIPT := preload("res://world/logic/kategorie_welt/welt_umsturz_geste.gd")

var _model: Welt_Model
var _registry: Welt_Registry
var _biome: Welt_BiomRegistry = null
## Biom-Farben je Biom-Kennung: Die Farbe hängt nur am Biom-Id, nicht an
## der Kachel; der Cache erspart je Kachel die Wörterbuch-Suche und das
## Color.from_string.
var _biom_farbe_cache: Dictionary = {}
## Dictionary: z_ebene (0, -1, -2, ...) -> Node2D (Fliesen-Container für diese Ebene)
var _fliesen_knoten_pro_ebene: Dictionary = {}
var _fliesen_erbaut: Dictionary = {}
## Fauler Sprite-Aufbau: Bei frischer Generierung erzeugt erst der
## zeitgeslicene Lader die Kachel-Sprites je Füllung; der Start-Frame baut
## keine tausend Sprites mehr. Editor und Save-Lauf behalten den sofortigen
## Vollbau, weil dort kein Lader läuft.
var _sprites_faul: bool = false
## Merker der faul gestellten Ebenen: Der Repaint je Füllung darf sie
## bespriteln, der Ebenen-Wechsel darf sie trotzdem synchron nachbauen.
var _faul_gestellt: Dictionary = {}
var _objekte_knoten: Node2D
var _objekt_darsteller: Welt_ObjektDarsteller
var _sway_aktualisierer := SWAY_AKTUALISIERER_SKRIPT.new()
var _sway_material_quelle: Callable = func() -> RefCounted: return null
var _kachel_geste := KACHEL_GESTE_SKRIPT.new()
var _stadium_geste := STADIUM_GESTE_SKRIPT.new()
var _wuchs_geste := WUCHS_GESTE_SKRIPT.new()
var _riss_geste := RISS_GESTE_SKRIPT.new()
var _umsturz_geste := UMSTURZ_GESTE_SKRIPT.new()
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
## Die Rechnung darüber trägt der Welt_SichtbereichSammler; der Renderer
## führt nur die Knoten und fragt den Sammler, was zu tun ist.
var _sicht_sammler := Welt_SichtbereichSammler.new()
var _knoten_nach_id: Dictionary = {}
## Slice B: Räumlicher Vorfilter – ersetzt linearen Vollscan in _sichtbar_anwenden().
var _objekt_gitter := Welt_ObjektGitter.new()
## Textur-Zwischenspeicher je Katalog-Kennung: Dieselbe Kennung liefert
## dieselbe Texture2D-Instanz statt je Knoten ein neues AtlasTexture.
## Gleiches Bild heißt gleiche Materiallage, das Canvas-Batching fasst
## benachbarte Knoten zu einem Drawcall zusammen.
var _textur_cache: Dictionary = {}
## Platzhalter-Bilder je Farbe, statt je Kachel ein neues Image.
var _platzhalter_cache: Dictionary = {}
## Sanfte Einblendung: Frisch angehängte Objekt-Knoten steigen aus dem
## Boden, statt hart zu ploppen. Der Wert steuert die Dauer in Sekunden;
## 0 schaltet die Geste still (Prüfläufe, Editor).
var _einblend_dauer: float = 0.25


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

func sprites_faul_setzen(faul: bool) -> void:
	## Die Szene stellt den Faulbau vor der Generierung scharf; das Ende
	## meldet faulbau_abschliessen, nachdem der Lader die letzte Füllung
	## gebracht hat.
	_sprites_faul = faul

func z_ebene_setzen(z_ebene: int) -> void:
	# Schaltet die sichtbare Z-Ebene um: Blendet alle Fliesen-Knoten aus,
	# zeigt nur den der angeforderten Ebene. Fehlende Ebenen werden faul
	# beim ersten Betreten aufgebaut, damit darstellen() nicht 5 Ebenen
	# synchron stemmen muss.
	_aktive_z_ebene = clampi(z_ebene, -Welt_Model.MAX_Z_EBENEN + 1, 0)
	if not _fliesen_erbaut.get(_aktive_z_ebene, false):
		_fliesen_ebene_erneuern(_aktive_z_ebene)
	for ebene in _fliesen_knoten_pro_ebene:
		var knoten: Node2D = _fliesen_knoten_pro_ebene[ebene] as Node2D
		knoten.visible = (ebene == _aktive_z_ebene)
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
	var knoten := _knoten_fuer(index)
	if knoten == null or knoten.standbild() == null:
		return
	# Jede sichtbare Stufe landet mit dem Platzier-Gestus auf dem Tisch;
	# Riss und Wuchs folgen demselben echten Zustand aus dem Modell.
	_stadium_geste.platzieren(knoten.standbild())
	_risse_und_wuchs_aktualisieren(index, knoten)

func _auf_folge_objekt(index: int, element_id: String) -> void:
	_sicht_sammler.dirty_setzen()
	# Das alte Blatt kommt vor dem Tausch in den Umsturz-Hauch: Die Krone
	# kippt und schwindet, während der Knoten schon den Rest-Zustand zeigt.
	var knoten := _knoten_fuer(index)
	var alte_textur: Texture2D = null
	if knoten != null and knoten.standbild() != null:
		alte_textur = knoten.standbild().texture
	# Der Rest ist wiedergeboren: Das Standbild braucht seine neue Textur und
	# der Knoten an dieser Stelle ein frisches Bewegtbild.
	_zeige_stadium(index)
	if knoten == null or _objekt_darsteller == null or _registry == null or _model == null:
		return
	# Die neue Kennung kommt aus dem Ereignis; fehlt sie, gilt der Modellwert.
	var neue_kennung := element_id if element_id != "" else _model.objekt_element_id(index)
	var eintrag := _registry.finde_objekt(neue_kennung)
	knoten.bewegtbild_setzen(_objekt_darsteller.objekt_darstellen(eintrag, knoten.fusspunkt()))
	# Der Identitätswechsel räumt die alten Spuren und setzt den neuen
	# Wuchs: Der Stumpf trägt keinen Riss und keinen Baum-Maßstab weiter.
	_risse_und_wuchs_aktualisieren(index, knoten)
	if knoten.standbild() != null:
		_stadium_geste.platzieren(knoten.standbild())
	if alte_textur != null:
		_umsturz_geste.umsturz_spielen(knoten, alte_textur)

func _auf_saemling(_element_id: String, _position: Vector2) -> void:
	_sicht_sammler.dirty_setzen()
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

func _risse_und_wuchs_aktualisieren(index: int, knoten: Welt_ObjektKnoten) -> void:
	# Schaden und Wuchs stehen als Felder im Modell; die Gesten übersetzen
	# sie nur ins Bild. Ohne Registry-Definition bleibt beides still.
	if _model == null or not _progressions_registry.hat_definition(_model.objekt_element_id(index)):
		return
	var sprite := knoten.standbild()
	if sprite == null or sprite.texture == null:
		return
	_ressourcen_zustand.zustand_erneuern(index, _model)
	var staerke := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_STAERKE, 1))
	var bestand := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_BESTAND, staerke))
	var schaden := clampf(1.0 - float(bestand) / float(maxi(staerke, 1)), 0.0, 1.0)
	_riss_geste.risse_anwenden(knoten, sprite, schaden)
	var definition := _progressions_registry.definition_fuer(_model.objekt_element_id(index))
	if str(definition.get("kategorie", "")) == "wachsend":
		var wachstum := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_WACHSTUM, 0))
		var dauer := maxi(int(definition.get("wachstums_ticks", 0)), 1)
		_wuchs_geste.wuchs_anwenden(sprite, float(wachstum) / float(dauer))
	else:
		# Ein Rest-Zustand steht wieder in vollem Maß: Der Stumpf erbt
		# keinen Stufen-Maßstab seiner gefällten Kette.
		sprite.scale = Vector2.ONE

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

func einblend_dauer_setzen(dauer: float) -> void:
	## Die Szene oder ein Prüflauf drosselt oder stillt die Einblend-Geste.
	_einblend_dauer = maxf(dauer, 0.0)

func darstellen(model: Welt_Model, registry: Welt_Registry, biome: Welt_BiomRegistry = null) -> void:
	_progressions_registry.laden()
	# Die Blattgeometrie der Stufen-Sheets kommt aus demselben Datenpool wie
	# die Stufen selbst: keine zweite Zellgröße im Renderer.
	_stufen_bilder.einrichten(_progressions_registry)
	_ressourcen_zustand.einrichten(_progressions_registry)
	# Koppelung der beiden Spitzen über die Szene: Das Modell meldet am Bus,
	# der Renderer lauscht und zieht genau die eine Kachel nach. Die Geste
	# kennt weder Modell noch Domäne, nur den Sichtbefehl des Renderers.
	_kachel_geste.einrichten(func(x: int, y: int, _element_id: String, z_ebene: int) -> void:
		kachel_ersetzen(x, y, z_ebene))
	_kachel_geste.verbinden()
	_model = model
	_registry = registry
	_baustellen_bedarf.einrichten(_model)
	_biome = biome if biome != null else Welt_RegistryZugriff.biom()
	# Sway-Spitze der Atmosphären-Domäne: Der Renderer kennt nur den
	# Aktualisierer, die Wind-Details liegen in der eigenen Domäne. Jeder
	# Neuaufbau sammelt die Materials der frischen Sprites neu.
	_sway_aktualisierer.einrichten(_sway_material_quelle.call())
	# Fliesen nur für die aktive Ebene synchron aufbauen; die übrigen Ebenen
	# entstehen faul beim ersten z_ebene_setzen. Verhindert 5*34k Sprites
	# im selben Frame und damit den Hänger auf "wird generiert".
	_fliesen_ebene_erneuern(_aktive_z_ebene)
	_objekte_erneuern()
	## Slice B: Gitter nach vollständigem Neuaufbau initialisieren.
	_objekt_gitter.aufbauen(_model)


func kachel_ersetzen(x: int, y: int, z_ebene: int = 0) -> void:
	if _model == null:
		return
	var z := z_ebene if z_ebene != 0 else _aktive_z_ebene
	# Die Kachel wohnt in ihrem Chunk-Knoten: Genau dort wird sie gesucht
	# und ersetzt, gleich ob ihr Chunk gerade im Baum hängt oder ruht.
	var fliesen_knoten := _fliesen_knoten_fuer_ebene(z)
	if fliesen_knoten == null:
		return
	# Sprites tragen ihre Kachel-Adresse im Namen, damit kein Index-Buch
	# geführt werden muss; die Adresse bleibt dieselbe wie beim Aufbau.
	var sprite := fliesen_knoten.get_node_or_null(NodePath("Kachel_%d_%d" % [x, y])) as Sprite2D
	if sprite == null:
		return
	sprite.position = Vector2(x, y) * float(_model.kachel_groesse)
	var vorherige_textur := sprite.texture
	_fliese_anwenden(sprite, x, y, z, float(_model.kachel_groesse))
	# Die Geste folgt nur einem echten Bildwechsel: Sie überlagert kurz die
	# frische Kachel und löst sich dann auf, sonst bleibt der Ruhigstand still.
	_kachel_geste.platzieren_falls_neu(sprite, vorherige_textur)

func fliesen_aktive_ebene_erneuern() -> void:
	## Öffentlicher Nachbau der aktiven Ebene: Der Abschluss-Pass des
	## Generators schreibt Gewässer und Fels nach der Chunk-Füllung; die
	## Szene lässt die Ebene deshalb einmal ganz neu zeichnen.
	_fliesen_ebene_erneuern(_aktive_z_ebene)

func _fliesen_ebene_erneuern(z_ebene: int) -> void:
	# Baut Fliesen genau einer Z-Ebene synchron auf und merkt sie als erbaut.
	# Im Faulbau bleibt die Ebene leer; die Sprites entstehen je Lader-Füllung
	# in kachel_erneuern_fuer_chunk, bis faulbau_abschliessen den Endstand trägt.
	if _model == null:
		return
	var fliesen_knoten := _fliesen_knoten_fuer_ebene(z_ebene)
	if fliesen_knoten == null:
		return
	for kind: Node in fliesen_knoten.get_children():
		kind.queue_free()
	if _sprites_faul:
		_fliesen_erbaut[z_ebene] = false
		_faul_gestellt[z_ebene] = true
		return
	_faul_gestellt.erase(z_ebene)
	var kante := float(_model.kachel_groesse)
	for y in _model.raster_hoehe:
		for x in _model.raster_breite:
			_fliese_anhaengen(fliesen_knoten, x, y, z_ebene, kante)
	_fliesen_erbaut[z_ebene] = true

func kachel_erneuern_fuer_chunk(chunk: Vector2i, z_ebene: int) -> void:
	## Nachschub aus dem zeitgeslicenen Lader: Genau die Kacheln des
	## gefüllten Chunks entstehen oder tragen ihr frisches Bild, ohne dass
	## die Ebene als Ganzes neu baut. Im Faulbau erzeugt dieser Ruf die
	## Sprites erstmals; danach hängt die Ebene wieder voll.
	if _model == null:
		return
	var fliesen_knoten := _fliesen_knoten_fuer_ebene(z_ebene)
	if fliesen_knoten == null:
		return
	var kante := float(_model.kachel_groesse)
	var kante_chunk := maxi(_model.chunk_groesse, 1)
	var start_x := chunk.x * kante_chunk
	var start_y := chunk.y * kante_chunk
	for dy in kante_chunk:
		for dx in kante_chunk:
			var x := start_x + dx
			var y := start_y + dy
			if x >= _model.raster_breite or y >= _model.raster_hoehe:
				continue
			var sprite := fliesen_knoten.get_node_or_null(NodePath("Kachel_%d_%d" % [x, y])) as Sprite2D
			if sprite == null:
				sprite = Sprite2D.new()
				sprite.name = "Kachel_%d_%d" % [x, y]
				sprite.centered = false
				sprite.position = Vector2(x, y) * kante
				fliesen_knoten.add_child(sprite)
			_fliese_anwenden(sprite, x, y, z_ebene, kante)
	# Die Ebene trägt wieder Kacheln; der Abschluss kann den Rest nachbauen,
	# ohne den Faulbau-Zustand zu ignorieren.
	_faul_gestellt.erase(z_ebene)

func faulbau_abschliessen() -> void:
	## Ende des zeitgeslicenen Laufs: Alle Sprites existieren bereits aus
	## den Füllungen; der Abschluss-Pass (Gewässer, Fels) wird nur noch
	## auf die bestehenden Kacheln neu bemalt, nichts wird weggeworfen.
	## Fehlende Sprites erzeugt der Lauf self-heilend nach.
	_sprites_faul = false
	_faul_gestellt.clear()
	if _model == null:
		return
	var kante_chunk := maxi(_model.chunk_groesse, 1)
	var chunk_x_zahl := ceili(float(_model.raster_breite) / float(kante_chunk))
	var chunk_y_zahl := ceili(float(_model.raster_hoehe) / float(kante_chunk))
	for cy in chunk_y_zahl:
		for cx in chunk_x_zahl:
			kachel_erneuern_fuer_chunk(Vector2i(cx, cy), _aktive_z_ebene)

func _fliesen_alle_ebenen_erneuern() -> void:
	# Legacy-Pfad: baut alle Ebenen synchron. Nur noch für Editor/Tests,
	# im Spiel wird die faule Variante genutzt.
	if _model == null:
		return
	for z in range(Welt_Model.MAX_Z_EBENEN):
		_fliesen_ebene_erneuern(-z)

func _fliese_anhaengen(fliesen_knoten: Node2D, x: int, y: int, z_ebene: int, kante: float) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Kachel_%d_%d" % [x, y]
	sprite.centered = false
	sprite.position = Vector2(x, y) * kante
	_fliese_anwenden(sprite, x, y, z_ebene, kante)
	fliesen_knoten.add_child(sprite)

func _platzhalter_textur_cache(farbe: Color) -> Texture2D:
	## Statt je fehlender Textur ein neues 8x8-Bild zu erzeugen, teilen sich
	## alle Kacheln derselben Farbe einen Platzhalter aus dem Cache. Weniger
	## Bildobjekte, weniger Textur-Bindings, weniger Drawcalls.
	var schluessel := farbe.to_html()
	if _platzhalter_cache.has(schluessel):
		return _platzhalter_cache[schluessel] as Texture2D
	var bild := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	bild.fill(farbe)
	var textur := ImageTexture.create_from_image(bild)
	_platzhalter_cache[schluessel] = textur
	return textur

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
	# Biomfarbe nur für ausdrücklich markierte Makro-Kacheln: Der Filter in
	# element_katalog.json entscheidet, keine Ebene. Mikrokacheln behalten
	# ihr Papierlicht, die Tönung kommt allein aus der Kachel-Palette.
	var toenumg := (entscheidung.get("toenumg", Color.WHITE) as Color)
	if kachel != null and bool(kachel.schluessel_daten.get("makro_farbe", false)):
		toenumg = toenumg * biom_farbe
	if element_id == "wasser" or element_id == "ufer":
		# Stilles Wasser atmet minimal gegen den Himmel: dieselbe Idee wie der
		# Geste-Hauch, aber als Standfarbe, ohne Knoten und ohne Zeit.
		var hauch := 0.03 + 0.02 * sin(float((x * 31 + y * 17) % 16) * TAU / 16.0)
		toenumg = toenumg.lerp(Color(0.85, 0.94, 1.0), hauch)
	sprite.self_modulate = toenumg

func _biom_farbe_fuer_kachel(x: int, y: int, z_ebene: int) -> Color:
	# Biom-Tönung aus der Biom-Registry: Jede Kachel trägt die Farbe ihres
	# Region-Bioms. Keine zweite Biomlogik, nur das gefrorene farbe-Feld.
	# Der Cache hält je Biom-Kennung genau eine Farbe; Tausende Kacheln
	# desselben Bioms teilen sie, statt jedes Mal zu parsen.
	if _biome == null or _model == null:
		return Color.WHITE
	var biom_id := _model.biom_an_kachel(x, y, z_ebene)
	if _biom_farbe_cache.has(biom_id):
		return _biom_farbe_cache[biom_id] as Color
	var biom := _biome.biom_fuer(biom_id)
	var farbe := Color.WHITE
	if biom != null:
		farbe = Color.from_string(biom.farbe, Color.WHITE)
	_biom_farbe_cache[biom_id] = farbe
	return farbe

func _kachel_daten(element_id: String) -> Objekt_Kachel:
	if _registry == null:
		return null
	var eintrag := _registry.finde_objekt(element_id)
	if eintrag is Objekt_Kachel:
		return eintrag as Objekt_Kachel
	return null

func _platzhalter_textur(farbe: Color) -> Texture2D:
	return _platzhalter_textur_cache(farbe)

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
	# Die Schatten-Lage folgt der Katalog-Entscheidung schatten_wurf: Nur
	# Objekte werfen im Papierlicht, die Kacheln und Tiere bleiben flach.
	knoten.schatten_wurf_setzen(
		eintrag != null and bool(eintrag.schluessel_daten.get("schatten_wurf", false)),
		float(eintrag.anzeige_breite) if eintrag != null else 64.0,
		float(eintrag.anzeige_hoehe) if eintrag != null else 64.0)
	# Auch der Neuaufbau trägt die Gesten: Riss, Wuchs und Stadium stehen
	# aus dem Modell, nicht nur aus den Ereignissen.
	_risse_und_wuchs_aktualisieren(index, knoten)
	# Interpolierte Einblendung: Der Knoten steigt weich aus dem Boden, statt
	# hart zu ploppen, wenn sein Chunk im zeitgeslicenen Lauf frisch wird.
	if _einblend_dauer > 0.0 and sprite != null and sprite.visible:
		sprite.modulate.a = 0.0
		var einblend := sprite.create_tween()
		einblend.tween_property(sprite, "modulate:a", 1.0, _einblend_dauer).set_ease(Tween.EASE_OUT)
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
	# Die Zustands-Erneuerung arbeitet je Objekt Felder ab; die Ergebnis-
	# Werte reichen für die Blatt-Wahl, der Zustand selbst bleibt im Modell.
	_ressourcen_zustand.zustand_erneuern(index, _model)
	var definition := _progressions_registry.definition_fuer(element_id)
	var stadien: Array = definition.get("stadien", [])
	var kategorie := str(definition.get("kategorie", ""))
	if kategorie == "rest":
		# Ein Rest-Zustand zeigt sein eigenes Katalogbild und kein Blatt einer
		# fremden Kette: Der Stumpf ist der Stumpf und nicht der Keimling.
		return null
	var staerke := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_STAERKE, 1))
	var bestand := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_BESTAND, staerke))
	var wachstum := int(_model.objekt_feld(index, Welt_RessourcenZustand.FELD_WACHSTUM, 0))
	var dauer := int(definition.get("wachstums_ticks", 0))
	var stufen_index := _stufen_bilder.stadien_index_fuer(kategorie, stadien.size(), bestand, staerke, wachstum, dauer)
	return _stufen_bilder._blatt_fuer(element_id, stufen_index)

func _textur_fuer(element_id: String) -> Texture2D:
	## Nur Daten lesen: der Renderer kennt die Objekte über die Registry.
	## Der Cache liefert je Kennung genau eine Instanz; ohne ihn baut jeder
	## Knoten sein eigenes AtlasTexture und das Batching zerfällt.
	if _textur_cache.has(element_id):
		return _textur_cache[element_id] as Texture2D
	var textur := _textur_bauen(element_id)
	_textur_cache[element_id] = textur
	return textur

func _textur_bauen(element_id: String) -> Texture2D:
	# Tatsächlicher Aufbau einer Textur-Instanz für die Kennung.
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
	# Ab ~800 Objekten nie alles synchron bauen: Der Sichtbereich füllt
	# inkrementell (max 256 je Ruf über das Gitter), damit 6k Knoten +
	# Shadow-Occluder nicht den _ready-Frame sprengen. Bei kleiner Karte
	# (Editor/Tests) bleibt der alte Pfad für sofortige Vollsicht.
	if _sicht_sammler.ist_aktiv() or _model.objekt_anzahl() > 800:
		_sicht_sammler.dirty_setzen()
		return
	for index in _model.objekt_anzahl():
		objekt_knoten_anhaengen(index)

## Kategorie logik: Sichtbarkeits-Scheibe des Knotenbestands.

func sichtbereich_setzen(rechteck: Rect2) -> void:
	# Die Szene reicht je Rahmen den Kamera-Bereich hinein; der Sammler
	# entscheidet, ob ein Abgleich fällig ist. Nur der Objekt-Bestand folgt
	# der Scheibe; die Kacheln hängen voll am Ebenen-Knoten.
	if _sicht_sammler.bereich_setzen(rechteck):
		_sichtbar_anwenden()

func sichtbereich_deaktivieren() -> void:
	# Der Editor und Prüfläufe ohne Kamera hängen alles an, wie bisher.
	_sicht_sammler.deaktivieren()

func sicht_rand_px() -> float:
	return Welt_SichtbereichSammler.SICHT_RAND_PX

func sichtgebiet_aktualisieren() -> void:
	# Erzwingt den Neuabgleich der sichtbaren Objekte bei Gebäudeplatzierung
	# oder Spawn-Ereignissen, ohne auf Kamerabewegung warten zu müssen.
	_sicht_sammler.dirty_setzen()
	if _sicht_sammler.ist_aktiv():
		_sichtbar_anwenden()


func _sichtbar_anwenden() -> void:
	if _model == null or not _sicht_sammler.ist_aktiv():
		return
	if _objekt_gitter.ist_leer():
		_objekt_gitter.aufbauen(_model)
	var anhaenge := 0
	var kandidaten := _objekt_gitter.kandidaten_in(_sicht_sammler.rechteck())
	for index in kandidaten:
		if anhaenge >= Welt_SichtbereichSammler.MAX_ANHAENGE_PRO_RUF:
			break
		if not _sicht_sammler.enthaelt(_model.objekt_position(index)):
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
		if not _sicht_sammler.enthaelt(knoten.fusspunkt()):
			_knoten_nach_id.erase(id)
			knoten.queue_free()
