extends Control
## Hauptmenü-Ansicht: Start, Laden, Map-Editor.
## Die Ansicht bedient nur die Menüführung; Simulationslogik bleibt außen vor.

const SZENE_KARTE := "res://world/scenes/welt.tscn"
const SZENE_WORLD_MAP := "res://world/scenes/welt_map.tscn"
const SZENE_EDITOR := "res://world/scenes/karten_editor.tscn"
const SZENE_UEBERGANG := "res://ui/scenes/uebergang.tscn"
const GRENZE_RECHTS := 2200.0
const GRENZE_LINKS := -140.0

## Kategorie daten: Menü-Zustand und Darsteller-Listen der Läufer.
var _zustaende := Ui_MenueZustaende.new()
var _zustand: Ui_MenueZustaende.Zustand = Ui_MenueZustaende.Zustand.HAUPTMENUE
var _laeufer: Array[AnimatedSprite2D] = []
var _story_regisseur: Menue_StoryRegisseur = null

## Kategorie logik: Menüführung, Dialoge und Läufer-Darstellung.

@onready var _start_knopf: Button = %StartKnopf
@onready var _laden_knopf: Button = %LadenKnopf
@onready var _editor_knopf: Button = %EditorKnopf
@onready var _laeufer_ebene: Node2D = %LaeuferEbene
@onready var _dialog_laden: Ui_WeltAuswahlDialog = %DialogLaden
@onready var _dialog_editor: Ui_WeltAuswahlDialog = %DialogEditor

func _ready() -> void:
	_start_knopf.pressed.connect(_auf_start)
	_laden_knopf.pressed.connect(_auf_laden)
	_editor_knopf.pressed.connect(_auf_editor)
	_dialog_laden.welt_gewaehlt.connect(_auf_welt_geladen)
	_dialog_editor.welt_gewaehlt.connect(_auf_editor_welt_gewaehlt)
	_erzeuge_laeufer()
	_story_einrichten()
	_menue_gegenpruefung()

func _story_einrichten() -> void:
	# Die Story lebt hinter den Knöpfen: Die Bühne liegt unter der Knopfleiste,
	# der Erzähler sitzt unten ins Papier. Genau ein Takt: die Weltuhr.
	var buehne := Menue_BuehnenMeister.new()
	var ebene := Node2D.new()
	ebene.name = "StoryEbene"
	ebene.y_sort_enabled = true
	add_child(ebene)
	# Die Buehne liegt hinter den Knoepfen: direkt hinter dem Hintergrund.
	move_child(ebene, 1)
	ebene.add_child(buehne)
	var unterschrift := Menue_Unterschrift.new()
	unterschrift.name = "StoryUnterschrift"
	unterschrift.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	unterschrift.offset_top = -110.0
	unterschrift.offset_bottom = -60.0
	unterschrift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(unterschrift)
	buehne.unterschrift = unterschrift
	var regisseur := Menue_StoryRegisseur.new()
	regisseur.name = "StoryRegisseur"
	add_child(regisseur)
	regisseur.anstupsen(buehne)
	_story_regisseur = regisseur

func _unhandled_input(event: InputEvent) -> void:
	# Spieler-Eingabe atmet gegen die Story: Sie bleibt als Bühne stehen,
	# aber ihre Uhr beginnt wieder bei null, sobald der Spieler etwas tut.
	if _story_regisseur == null:
		return
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
		_story_regisseur.von_vorn()

func _menue_gegenpruefung() -> void:
	# Menü-Gegenprüfung: Das Öffnen meldet sich über den Signalbus, damit
	# die Modifikator-Maschinen ihre Faktoren neu ziehen und die Anzeige
	# zum aktuellen Balancing passt.
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_menue_geoeffnet()

func _erzeuge_laeufer() -> void:
	var textur_rechts: Texture2D = load("res://world/assets/ui/laeufer_rechts.svg")
	var textur_links: Texture2D = load("res://world/assets/ui/laeufer_links.svg")
	var konfigurationen := [
		{"textur": textur_rechts, "y": 150.0, "geschwindigkeit": 65.0},
		{"textur": textur_rechts, "y": 250.0, "geschwindigkeit": 85.0},
		{"textur": textur_links, "y": 360.0, "geschwindigkeit": -75.0},
	]
	for konfig: Dictionary in konfigurationen:
		var laeufer := AnimatedSprite2D.new()
		laeufer.sprite_frames = _frames_aus_quelle(konfig["textur"])
		laeufer.animation = "laufen"
		laeufer.position = _heimat_fuer(konfig["geschwindigkeit"], konfig["y"])
		laeufer.play()
		_laeufer.append(laeufer)
		_laeufer_ebene.add_child(laeufer)
		_patrouille_starten(laeufer, konfig["geschwindigkeit"])

func _frames_aus_quelle(textur: Texture2D) -> SpriteFrames:
	# Schneidet die vier Frames (je 48x64) aus dem Sprite-Sheet.
	var frames := SpriteFrames.new()
	frames.add_animation("laufen")
	frames.set_animation_speed("laufen", 8.0)
	frames.set_animation_loop("laufen", true)
	for frame_index in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = textur
		atlas.region = Rect2(frame_index * 48, 0, 48, 64)
		frames.add_frame("laufen", atlas)
	return frames

func _heimat_fuer(geschwindigkeit: float, y: float) -> Vector2:
	# Der Start liegt an der Grenze, in die der Läufer hineinläuft.
	if geschwindigkeit > 0.0:
		return Vector2(GRENZE_LINKS, y)
	return Vector2(GRENZE_RECHTS, y)

func _patrouille_starten(laeufer: AnimatedSprite2D, geschwindigkeit: float) -> void:
	# Die Deko-Patrouille gehört dem Tween der Engine: konstante Fahrt
	# bis zur gegenüberliegenden Grenze, dort der Sprung zur Heimat, im Loop.
	# Die Höhe bleibt unverändert, nur die X-Achse patrouilliert.
	var ziel_x := GRENZE_RECHTS if geschwindigkeit > 0.0 else GRENZE_LINKS
	var heimat_x := GRENZE_LINKS if geschwindigkeit > 0.0 else GRENZE_RECHTS
	var dauer := absf(ziel_x - heimat_x) / absf(geschwindigkeit)
	var tween := laeufer.create_tween().set_loops()
	tween.tween_property(laeufer, "position:x", ziel_x, dauer)
	tween.tween_callback(_auf_grenze_angekommen.bind(laeufer, heimat_x))

func _auf_grenze_angekommen(laeufer: AnimatedSprite2D, heimat_x: float) -> void:
	laeufer.position.x = heimat_x

func _auf_start() -> void:
	# Neues Spiel startet über die World Map: Der Spieler wählt zuerst
	# seinen Startbereich und prüft das Fraktionsnetzwerk.
	WeltSitzung.welt_name = ""
	WeltSitzung.seed_wunsch = 0
	WeltSitzung.kommt_vom_editor = false
	WeltSitzung.world = null
	WeltSitzung.aktive_map_id = ""
	_uebergang_einlaeuten(SZENE_WORLD_MAP, "Die Weltkarte wird entfaltet …")

func _auf_laden() -> void:
	_wechsle_zu(Ui_MenueZustaende.Zustand.WELT_AUSWAHL_LADEN)
	_dialog_laden.popup_centered()
	_menue_gegenpruefung()

func _auf_editor() -> void:
	_wechsle_zu(Ui_MenueZustaende.Zustand.WELT_AUSWAHL_EDITOR)
	_dialog_editor.popup_centered()
	_menue_gegenpruefung()

func _auf_welt_geladen(welt_name: String) -> void:
	WeltSitzung.welt_name = welt_name
	WeltSitzung.kommt_vom_editor = false
	# Die World wird beim Kartenaufbau aus dem Speicher geladen; die aktive
	# Map wählt der Ladevorgang aus (zuerst die zuletzt gespielte, sonst Basis).
	WeltSitzung.world = null
	WeltSitzung.aktive_map_id = ""
	_uebergang_einlaeuten(SZENE_KARTE, "Die gespeicherte Welt wird geladen …")

func _auf_editor_welt_gewaehlt(welt_name: String) -> void:
	WeltSitzung.welt_name = welt_name
	WeltSitzung.kommt_vom_editor = true
	_uebergang_einlaeuten(SZENE_EDITOR, "Der Kreativmodus wird geöffnet …")

func _uebergang_einlaeuten(ziel: String, menue_text: String) -> void:
	# Verbindungs-Stelle: Jeder Szenenwechsel läuft über die Zwischen-Szene,
	# damit später Events und Cutscenes zwischen Szenen eingefügt werden.
	WeltSitzung.uebergang_ziel = ziel
	WeltSitzung.uebergang_text = menue_text
	get_tree().change_scene_to_file(SZENE_UEBERGANG)

func _wechsle_zu(nach: Ui_MenueZustaende.Zustand) -> void:
	if not _zustaende.ist_gueltiger_uebergang(_zustand, nach):
		return
	_zustand = nach
