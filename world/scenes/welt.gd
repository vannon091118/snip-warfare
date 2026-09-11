extends Node2D
## Welt: reine Endzustands-Visualisierung. Sie besitzt keine fremde Logik:
## Kein Lager-Bau, kein Tier-Spawn, kein Generator-Loop, keine Kamera-Formel,
## keine Input-Entscheidung. Jede fachliche Aufgabe liegt in ihrer eigenen
## Spitze; diese Datei verdrahtet nur Observer und Visualisierungen.
## Fluss: Eingabe -> Ui_EingabeSteuerung/Ui_KameraSteuerung -> Maschinen
## -> Zustand -> Welt_Renderer/HUD/Karten-Beobachter lesen und zeigen.

const ORCHESTRATOR_PFAD := "res://game/data/orchestrator_config.json"
const _AuswahlManagerSkript := preload("res://ui/scenes/selection/auswahl_manager.gd")
const _EinheitPanelSzene := preload("res://ui/scenes/panels/einheit_panel.tscn")
const _TierPanelSzene := preload("res://ui/scenes/panels/tier_panel.tscn")

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
var _map_fabrik := Welt_MapFabrik.new()
var _gebaeude := Gebaeude_Manager.new()
var _lager_fabrik := Welt_LagerFabrik.new()
var _tier_platzierer := Welt_TierPlatzierer.new()
var _waerme_sammler := Welt_WaermeSammler.new()
var _need_baum := Pop_NeedBaum.new()
var _karten_beobachter := Welt_KartenBeobachter.new()
var _timeline := Kern_Timeline.new()
var _feedback := Welt_FeedbackManager.new()
var _orchestrator_verdrahtung := Orchestrator_Verdrahtung.new()
var _kamera_steuerung := Ui_KameraSteuerung.new()
var _eingabe_steuerung := Ui_EingabeSteuerung.new()
var _pause_menue: Welt_PauseMenue = null
var _orchestrator_darsteller: Array[Orchestrator_Darsteller] = []
var _einheit_panel: Control = null
var _tier_panel: Control = null

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _tiere: Tier_Manager = %Tiere
@onready var _hud: VBoxContainer = %HUD
@onready var _rechteck: Control = %AuswahlRechteck
@onready var _kontext: PopupMenu = %KontextMenue

func _ready() -> void:
	_ladevorgang.einrichten(_model, _generator)
	_map_fabrik.einrichten(_generator)
	_ladevorgang.ausfuehren(WeltSitzung.welt_name, WeltSitzung.seed_wunsch, _model.biom_id)
	# Spielrhythmus aus dem Datenpool: Taktdauer und Tag-/Nachtanteil kommen
	# über den Need-Baum aus population/data/needs.json; der Baum besitzt die
	# Registry und reicht die Werte weiter, statt sie hier hart zu setzen.
	_tageszyklus.einrichten(_need_baum.takt_minuten(), _need_baum.tag_minuten(), _need_baum.nacht_minuten())
	# Besitz-Korrektur: Die Tageszyklus-Maschine ist eine Weltmaschine und
	# hängt seit diesem Slice direkt an der zentralen Weltuhr, statt vom
	# Einheiten-Manager mitgetickt zu werden. Die Szene verbindet den
	# Tick der Maschine selbst und löst die Uhr zur Laufzeit auf, damit
	# Headless-Testläufe ohne Autoloads kompilierbar bleiben.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_tageszyklus.tick):
		weltuhr.tick.connect(_tageszyklus.tick)
	_tages_overlay = preload("res://world/scenes/tageszyklus_overlay.gd").new()
	(_tages_overlay as CanvasLayer).layer = 20
	add_child(_tages_overlay)
	(_tages_overlay as Object).call("einrichten", _tageszyklus)
	_karte.darstellen(_model, _registry, _biome)
	add_child(_feedback)
	_feedback.einrichten(_ressourcen)
	_karten_ebene_bauen()
	_tier_platzierer.platzieren(_model, _registry, _tiere)
	var start_position := Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE / 2.0
	_kamera_steuerung.einrichten(_steuerung, _model, start_position)
	_tiere.spieler_position_setzen(_kamera_steuerung.kamera_position)
	_kamera.position = _kamera_steuerung.kamera_position
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_ressourcen.lager_setzen(_lager)
	# Die Zustands-Timeline beobachtet jede Buchung der Ressourcen und
	# meldet sie ueber den Bus, damit das HUD den Einfluss der
	# Modifikatoren sichtbar machen kann. Nichts passiert ohne Feedback.
	_ressourcen.timeline_setzen(_timeline)
	_timeline.eintrag_neu.connect(_auf_timeline_eintrag)
	# Der eigene Need-Tree hängt als struktureller Anker der
	# Bedürfnis-Domäne unter der Welt-Szene; er erzeugt die
	# Mood-Maschinen als Kinder und vergibt die Rassen-Schemata.
	add_child(_need_baum)
	_stockmaenner.einrichten(_model, _tiere, _ressourcen)
	_stockmaenner.need_baum_setzen(_need_baum)
	_stockmaenner.lager_setzen(_lager)
	_stockmaenner.tageszyklus_setzen(_tageszyklus)
	_waerme_sammler.sammeln(_model, _stockmaenner)
	add_child(_stockmaenner)
	_gebaeude.einrichten(_model, _registry, _ressourcen, _lager)
	add_child(_gebaeude)
	_gebaeude.gebaeude_meldung.connect(_auf_gebaeude_meldung)
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
		"gebaeude": _gebaeude,
		"map_fabrik": _map_fabrik,
		"modell_ersetzen": _modell_ersetzen,
	})
	var zurueck_knopf: Button = %ZurueckKnopf
	zurueck_knopf.pressed.connect(_auf_zurueck)
	_pause_menue = Welt_PauseMenue.new()
	add_child(_pause_menue)
	_pause_menue.menue_gewuenscht.connect(_auf_zurueck)
	# Fenster-Panels: beide als modulare Control-Spitzen unter dem HUD-
	# CanvasLayer eingehängt; sie lesen nur über ihre Panel-Controller aus
	# den bestehenden Maschinen. Kein neuer Schnittpunkt, nur Sichtbarkeit.
	_einheit_panel_bauen()
	_tier_panel_bauen()
	# Warum-Fenster: Die Status-Anzeige besitzt die Begründungsliste, die Szene
	# übergibt nur ihre drei Spitzen. Reine Verdrahtung, keine Timeline-Logik.
	_hud.warum_verdrahten(%WarumKnopf, %WarumFenster, %WarumText)

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

func _modell_ersetzen(neues_modell: Welt_Model) -> void:
	# Expansion: Die neue Basis-Karte ersetzt das Szenen-Modell; alle
	# Beobachter und Manager werden auf die neue Karte umgestellt. Die
	# alte Karte bleibt in der World gespeichert.
	if neues_modell == null:
		return
	_model = neues_modell
	_karte.darstellen(_model, _registry, _biome)
	_kamera.position = Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE / 2.0
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera.position)
	_tier_platzierer.platzieren(_model, _registry, _tiere)
	_waerme_sammler.sammeln(_model, _stockmaenner)
	_karten_beobachter.einrichten(_model, _generator, _tiere)
	_auswahl.auswahl_leeren()

func _input(ereignis: InputEvent) -> void:
	_eingabe_steuerung.eingabe(ereignis, self, _auf_verteilung)

func _process(delta: float) -> void:
	_kamera_steuerung.kamera_bewegen(delta, _kamera)
	_tiere.spieler_position_setzen(_kamera.position)
	# RTS-Prinzip: Kamera und Einheiten sind entkoppelt. Stickmen bewegen
	# sich ausschließlich über Jobs (Einheit_Status + Rathaus/Orchestrator),
	# niemals durch unmittelbares Setzen ihrer Position pro Frame.
	_karten_beobachter.beobachten(_karten_viewer, _karten_info, _karten_ebene, _kamera_steuerung.kamera_position, _kamera)
	_hud.produktion_anzeigen(_gebaeude.status_zeilen())

func _einheit_panel_bauen() -> void:
	var canvas: CanvasLayer = %HUD.get_parent() as CanvasLayer
	if canvas == null:
		return
	# Godot-komponiert: PackedScene -> instantiate -> add_child.
	# Kein .gd.new() direkt, damit _ready und @onready der Szene laufen.
	_einheit_panel = _EinheitPanelSzene.instantiate()
	_einheit_panel.name = "EinheitPanel"
	_einheit_panel.position = Vector2(16, 192)
	_einheit_panel.custom_minimum_size = Vector2(520, 80)
	(_einheit_panel as Object).call("einrichten", _auswahl, _stockmaenner)
	canvas.add_child(_einheit_panel)

func _tier_panel_bauen() -> void:
	var canvas: CanvasLayer = %HUD.get_parent() as CanvasLayer
	if canvas == null:
		return
	_tier_panel = _TierPanelSzene.instantiate()
	_tier_panel.name = "TierPanel"
	_tier_panel.position = Vector2(16, 284)
	_tier_panel.custom_minimum_size = Vector2(520, 80)
	(_tier_panel as Object).call("einrichten", _tiere)
	canvas.add_child(_tier_panel)

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

func model_liefern() -> Welt_Model:
	return _model

func _auf_zurueck() -> void:
	# Auch der Rückweg läuft über die Übergangs-Verbindung, damit jede
	# Szene denselben Weg nimmt und Events/Cutscenes dort andocken können.
	WeltSitzung.uebergang_ziel = "res://ui/scenes/hauptmenue.tscn"
	WeltSitzung.uebergang_text = "Zurück zum Hauptmenü …"
	get_tree().change_scene_to_file("res://ui/scenes/uebergang.tscn")

func _auf_gebaeude_meldung(meldung_text: String) -> void:
	_hud.meldung_setzen(meldung_text)

func _auf_timeline_eintrag(eintrag: Kern_TimelineEintrag) -> void:
	# Reine Beobachtung: Die Timeline meldet, das HUD zeigt die Begruendung.
	_hud.timeline_anzeigen(eintrag.delta_text())
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_timeline_eintrag(eintrag.delta_text())
