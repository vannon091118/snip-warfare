extends Control
## Hauptmenü-Ansicht: Start, Laden, Map-Editor.
## Die Ansicht bedient nur die Menüführung; Simulationslogik bleibt außen vor.

const SZENE_KARTE := "res://world/scenes/welt.tscn"
const SZENE_EDITOR := "res://world/scenes/karten_editor.tscn"
const SZENE_UEBERGANG := "res://ui/scenes/uebergang.tscn"
const GRENZE_RECHTS := 2200.0
const GRENZE_LINKS := -140.0

## Kategorie daten: Menü-Zustand und Darsteller-Listen der Läufer.
var _zustaende := Ui_MenueZustaende.new()
var _zustand: Ui_MenueZustaende.Zustand = Ui_MenueZustaende.Zustand.HAUPTMENUE
var _laeufer: Array[AnimatedSprite2D] = []
var _richtungen: Array[float] = []

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
	_menue_gegenpruefung()

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
		{"textur": textur_rechts, "start": Vector2(-60, 150), "geschwindigkeit": 65.0},
		{"textur": textur_rechts, "start": Vector2(-140, 250), "geschwindigkeit": 85.0},
		{"textur": textur_links, "start": Vector2(2100, 360), "geschwindigkeit": -75.0},
	]
	for konfig: Dictionary in konfigurationen:
		var laeufer := AnimatedSprite2D.new()
		laeufer.sprite_frames = _frames_aus_quelle(konfig["textur"])
		laeufer.animation = "laufen"
		laeufer.position = konfig["start"]
		laeufer.play()
		_laeufer.append(laeufer)
		_richtungen.append(signf(konfig["geschwindigkeit"]))
		_laeufer_ebene.add_child(laeufer)

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

func _process(delta: float) -> void:
	for index in _laeufer.size():
		var laeufer := _laeufer[index]
		laeufer.position.x += _richtungen[index] * 75.0 * delta
		if laeufer.position.x > GRENZE_RECHTS:
			laeufer.position.x = GRENZE_LINKS
		elif laeufer.position.x < GRENZE_LINKS:
			laeufer.position.x = GRENZE_RECHTS

func _auf_start() -> void:
	# Neues Spiel heißt immer neue Welt: Unabhängig von gespeicherten
	# Welten wird frisch aus dem Generator mit zufälligem Seed erzeugt.
	# Laden bleibt ausschließlich dem Laden-Knopf vorbehalten.
	WeltSitzung.welt_name = ""
	WeltSitzung.seed_wunsch = 0
	WeltSitzung.kommt_vom_editor = false
	WeltSitzung.world = null
	WeltSitzung.aktive_map_id = ""
	_uebergang_einlaeuten(SZENE_KARTE, "Eine neue Welt wird geboren …")

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

func _uebergang_einlaeuten(ziel: String, text: String) -> void:
	# Verbindungs-Stelle: Jeder Szenenwechsel läuft über die Zwischen-Szene,
	# damit später Events und Cutscenes zwischen Szenen eingefügt werden.
	WeltSitzung.uebergang_ziel = ziel
	WeltSitzung.uebergang_text = text
	get_tree().change_scene_to_file(SZENE_UEBERGANG)

func _wechsle_zu(nach: Ui_MenueZustaende.Zustand) -> void:
	if not _zustaende.ist_gueltiger_uebergang(_zustand, nach):
		return
	_zustand = nach
