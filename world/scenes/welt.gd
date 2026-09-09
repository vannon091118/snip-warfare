extends Node2D
## Welt: reine Endzustands-Visualisierung. Sie besitzt keine fremde Logik:
## Kein Lager-Bau, kein Tier-Spawn, kein Generator-Loop, keine Kamera-Formel,
## keine Input-Entscheidung. Jede fachliche Aufgabe liegt in ihrer eigenen
## Spitze; diese Datei verdrahtet nur Observer und Visualisierungen.
## Fluss: Eingabe -> Ui_EingabeSteuerung/Ui_KameraSteuerung -> Maschinen
## -> Zustand -> Welt_Renderer/HUD/Karten-Beobachter lesen und zeigen.

const ORCHESTRATOR_PFAD := "res://game/data/orchestrator_config.json"
const _AuswahlManagerSkript := preload("res://ui/scenes/selection/auswahl_manager.gd")

## Kategorie daten: Modell und Registries als Quellen der Visualisierung.
## Kategorie logik: Verdrahtung der Observer- und Visualisierungs-Spitzen.
var _model := Welt_Model.new()
var _registry := Welt_Registry.new()
var _steuerung := Kern_SteuerungRegistry.new()
var _lager := Lager_Manager.new()
var _ressourcen := Einheit_Ressourcen.new()
var _job_registry := Job_Registry.new()
var _stockmaenner := Einheit_Manager.new()
var _tageszyklus := Welt_TageszyklusMaschine.new()
var _tages_overlay: CanvasLayer = null
var _auswahl := _AuswahlManagerSkript.new()
var _schnellwahl: Array[int] = []
var _orchestrator_registry := Orchestrator_Registry.new()
var _orchestrator_manager := Orchestrator_Manager.new()
var _biome := Welt_BiomRegistry.new()
var _generator := Welt_Generator.new()
var _karten_ebene: CanvasLayer = null
var _karten_viewer: Ui_KartenViewer = null
var _karten_info: Ui_WeltInfo = null

## Unter-Spitzen: Jede hält genau eine Zuständigkeit.
var _ladevorgang := Welt_Ladevorgang.new()
var _lager_fabrik := Welt_LagerFabrik.new()
var _tier_platzierer := Welt_TierPlatzierer.new()
var _waerme_sammler := Welt_WaermeSammler.new()
var _karten_beobachter := Welt_KartenBeobachter.new()
var _orchestrator_verdrahtung := Orchestrator_Verdrahtung.new()
var _kamera_steuerung := Ui_KameraSteuerung.new()
var _eingabe_steuerung := Ui_EingabeSteuerung.new()
var _orchestrator_darsteller: Array[Orchestrator_Darsteller] = []

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _spieler: Node2D = %Spieler
@onready var _tiere: Tier_Manager = %Tiere
@onready var _hud: VBoxContainer = %HUD
@onready var _rechteck: Control = %AuswahlRechteck
@onready var _kontext: PopupMenu = %KontextMenue

func _ready() -> void:
	_ladevorgang.einrichten(_model, _generator)
	_ladevorgang.ausfuehren(WeltSitzung.welt_name, WeltSitzung.seed_wunsch, _model.biom_id)
	_tageszyklus.einrichten(6.0, 4.0, 2.0)
	_tages_overlay = preload("res://world/scenes/tageszyklus_overlay.gd").new()
	(_tages_overlay as CanvasLayer).layer = 20
	add_child(_tages_overlay)
	(_tages_overlay as Object).call("einrichten", _tageszyklus)
	_karte.darstellen(_model, _registry, _biome)
	_karten_ebene_bauen()
	_tier_platzierer.platzieren(_model, _registry, _tiere)
	var start_position := Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE / 2.0
	_kamera_steuerung.einrichten(_steuerung, _model, start_position)
	_kamera.position = _kamera_steuerung.kamera_position
	# Spieler-Sprite ist nur noch Kamera-Anker, keine Spielfigur mehr.
	_spieler.position = _kamera_steuerung.kamera_position
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_ressourcen.lager_setzen(_lager)
	_stockmaenner.einrichten(_model, _tiere, _ressourcen)
	_stockmaenner.lager_setzen(_lager)
	_stockmaenner.tageszyklus_setzen(_tageszyklus)
	_waerme_sammler.sammeln(_model, _stockmaenner)
	add_child(_stockmaenner)
	_stockmaenner.einheit_hinzufuegen(_kamera_steuerung.kamera_position + Vector2(0, 48))
	_karten_beobachter.einrichten(_model, _generator, _tiere)
	_orchestrator_registry.laden(ORCHESTRATOR_PFAD)
	_orchestrator_manager.referenzen_setzen(_stockmaenner, _model, _registry, _job_registry)
	add_child(_orchestrator_manager)
	_orchestrator_darsteller = _orchestrator_verdrahtung.verdrahten(_orchestrator_registry, _orchestrator_manager, self)
	_hud.einrichten(_ressourcen)
	_kontext.einrichten(_steuerung)
	_kontext.aktion_gewaehlt.connect(_auf_kontext_aktion)
	_hud.job_anzeigen("")
	_biom_anzeigen()
	_eingabe_steuerung.einrichten({
		"steuerung": _steuerung,
		"model": _model,
		"registry": _registry,
		"job_registry": _job_registry,
		"stockmaenner": _stockmaenner,
		"tiere": _tiere,
		"lager": _lager,
		"auswahl": _auswahl,
		"karte": _karte,
		"kamera": _kamera,
		"hud": _hud,
		"rechteck": _rechteck,
		"kontext": _kontext,
		"kamera_steuerung": _kamera_steuerung,
		"karten_ebene": _karten_ebene,
		"karten_viewer": _karten_viewer,
		"schnellwahl": _schnellwahl,
	})
	var zurueck_knopf: Button = %ZurueckKnopf
	zurueck_knopf.pressed.connect(_auf_zurueck)

func _karten_ebene_bauen() -> void:
	# Komponier-Schritt: reine Observer-Schicht als CanvasLayer.
	_karten_ebene = CanvasLayer.new()
	_karten_ebene.layer = 30
	_karten_ebene.visible = false
	var hintergrund := ColorRect.new()
	hintergrund.color = Color(0, 0, 0, 0.55)
	hintergrund.set_anchors_preset(Control.PRESET_FULL_RECT)
	_karten_ebene.add_child(hintergrund)
	_karten_viewer = Ui_KartenViewer.new()
	_karten_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_karten_viewer.offset_left = 80.0
	_karten_viewer.offset_top = 60.0
	_karten_viewer.offset_right = -80.0
	_karten_viewer.offset_bottom = -120.0
	_karten_ebene.add_child(_karten_viewer)
	var info := Ui_WeltInfo.new()
	info.position = Vector2(90, 20)
	_karten_ebene.add_child(info)
	_karten_viewer.einrichten(_model, _registry, _biome)
	add_child(_karten_ebene)
	_karten_info = info

func _input(ereignis: InputEvent) -> void:
	_eingabe_steuerung.eingabe(ereignis, self, _auf_verteilung)

func _process(delta: float) -> void:
	_kamera_steuerung.kamera_bewegen(delta, _kamera)
	_spieler.position = _kamera_steuerung.kamera_position
	# RTS-Prinzip: Kamera und Einheiten sind entkoppelt. Stickmen bewegen
	# sich ausschließlich über Jobs (Einheit_Status + Rathaus/Orchestrator),
	# niemals durch unmittelbares Setzen ihrer Position pro Frame.
	_karten_beobachter.beobachten(_karten_viewer, _karten_info, _karten_ebene, _kamera_steuerung.kamera_position, _kamera)

func _unhandled_input(ereignis: InputEvent) -> void:
	_eingabe_steuerung.unhandled_input(
		ereignis,
		func(e: InputEventMouseButton) -> Vector2: return _eingabe_steuerung.klick_position(e),
		func() -> void: _eingabe_steuerung.rechteck_pflegen_bild(get_global_mouse_position(), get_viewport().get_canvas_transform(), _auswahl.ziehen_start),
		func(e: InputEventKey) -> void: _eingabe_steuerung.hotkey_verarbeiten(e)
	)

func _auf_verteilung(nahrung_je_takt: float) -> void:
	_eingabe_steuerung.auf_verteilung(nahrung_je_takt)

func _auf_kontext_aktion(aktion: Dictionary) -> void:
	_eingabe_steuerung.auf_kontext_aktion(aktion)

func _biom_anzeigen() -> void:
	var zustand := _model.biom_zustand()
	(_hud as Variant).biom_anzeigen(str(zustand.get("biom_id", _model.biom_id)), float(zustand.get("biom_faktor", 1.0)))

func _auf_zurueck() -> void:
	get_tree().change_scene_to_file("res://ui/scenes/hauptmenue.tscn")
