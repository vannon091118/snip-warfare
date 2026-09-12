extends Node2D
## Welt: reine Endzustands-Visualisierung. Sie besitzt keine fremde Logik:
## Kein Lager-Bau, kein Tier-Spawn, kein Generator-Loop, keine Kamera-Formel,
## keine Input-Entscheidung. Jede fachliche Aufgabe liegt in ihrer eigenen
## Spitze; diese Datei verdrahtet nur Observer und Visualisierungen.
## Fluss: Eingabe -> Ui_EingabeSteuerung/Ui_KameraSteuerung -> Maschinen
## -> Zustand -> Welt_Renderer/HUD/Karten-Beobachter lesen und zeigen.

const ORCHESTRATOR_PFAD := "res://game/data/orchestrator_config.json"
const _AuswahlManagerSkript := preload("res://ui/scenes/selection/auswahl_manager.gd")
const _BauPanelSzene := preload("res://ui/scenes/panels/bau_panel.tscn")
const _DebugPanelSkript := preload("res://ui/scenes/hud/hud_debug_panel.gd")
const _LandeplatzAnzeigeSkript := preload("res://world/logic/kategorie_welt/welt_landeplatz_anzeige.gd")

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
var _gebaeude_definitionen := Gebaeude_DefinitionRegistry.new()
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
var _fortschritt := Welt_FortschrittsMaschine.new()
var _karten_beobachter := Welt_KartenBeobachter.new()
var _timeline := Kern_Timeline.new()
var _feedback := Welt_FeedbackManager.new()
var _atmosphaere := Welt_AtmosphaereVerdrahtung.new()
var _progression := Welt_ProgressionsMaschine.new()
var _orchestrator_verdrahtung := Orchestrator_Verdrahtung.new()
var _kamera_steuerung := Ui_KameraSteuerung.new()
var _eingabe_steuerung := Ui_EingabeSteuerung.new()
var _pause_menue: Welt_PauseMenue = null
var _orchestrator_darsteller: Array[Orchestrator_Darsteller] = []
## Das Debug-Fenster hält Einheit- und Tierbeobachter; es ist im Normalbetrieb
## unsichtbar. Die Spielszene kennt nur diesen einen Sichtbarkeits-Schalter.
var _debug_panel: Control = null
var _bau_panel: Ui_BauPanelSzene = null
var _landeplatz: Node2D = null

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _tiere: Tier_Manager = %Tiere
@onready var _hud: VBoxContainer = %HUD
@onready var _rechteck: Control = %AuswahlRechteck
@onready var _kontext: PopupMenu = %KontextMenue

func _ready() -> void:
	# Eingabe-Aktionen aus steuerung.json: Die InputMap entsteht zentral aus
	# der geladenen Steuerungs-Registry, bevor irgendein Leser die Richtungen
	# abfragt. Die Zahl ist der Registrier-Nachweis für den Lauf-Log.
	var aktionen_neu := _steuerung.inputmap_registrieren()
	print("Steuerung: %d Eingabe-Tasten aus steuerung.json in die InputMap geschrieben." % aktionen_neu)
	_ladevorgang_ausfuehren()
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
	var start_position := Vector2(_model.groesse()) * float(_model.kachel_groesse) / 2.0
	var bereich := maxf(_model.groesse().x, _model.groesse().y) * float(_model.kachel_groesse) * 0.6
	_karte.darstellen(_model, _registry, _biome)
	_karte.progressions_maschine_setzen(_progression)
	# Atmosphaeren-Domaene: Die Szene haengt nur die Spitze an und reicht
	# Tageszyklus, Kartenmitte und Radius weiter. Jede Fachlogik bleibt in
	# der Domaene; die Sway-Quelle fuer den Renderer kommt von dort.
	_atmosphaere.bereich_setzen(start_position, bereich)
	add_child(_atmosphaere)
	_atmosphaere.einrichten(_tageszyklus, start_position, bereich)
	_atmosphaere.weltuhr_verbinden()
	_karte.sway_material_quelle_setzen(_atmosphaere.sway_material_quelle())
	_stockmaenner.schlag_ort_empfaenger_setzen(_atmosphaere.staub_zeigen)
	add_child(_feedback)
	_feedback.einrichten(_ressourcen)
	_karten_ebene_bauen()
	_tier_platzierer.platzieren(_model, _registry, _tiere)
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
	_stockmaenner.schlag_empfaenger_setzen(_progression.schlag)
	_stockmaenner.schlag_ort_empfaenger_setzen(_atmosphaere.staub_zeigen)
	# Progressions-Domaene: Die Szene haengt nur die Maschine an, reicht
	# Modell, Biome und Tageszyklus hinein und verdrahtet die Renderer-
	# Sichten. Der Zustand wohnt im Modell, die Maschine tickt an der Uhr.
	_progression.einrichten(_model, _biome, _tageszyklus)
	add_child(_progression)
	_progression.objekt_erschoepft.connect(_atmosphaere.staub_zeigen)
	_stockmaenner.fortschritt_setzen(_fortschritt)
	_stockmaenner.need_baum_setzen(_need_baum)
	_stockmaenner.lager_setzen(_lager)
	_stockmaenner.tageszyklus_setzen(_tageszyklus)
	_waerme_sammler.sammeln(_model, _stockmaenner)
	_stockmaenner.y_sort_enabled = true
	add_child(_stockmaenner)
	_landeplatz = _LandeplatzAnzeigeSkript.new()
	_landeplatz.name = "LandeplatzAnzeige"
	_landeplatz.einrichten(start_position, float(_model.kachel_groesse))
	add_child(_landeplatz)
	_gebaeude.einrichten(_model, _registry, _ressourcen, _lager, _fortschritt)
	add_child(_gebaeude)
	_gebaeude.gebaeude_meldung.connect(_auf_gebaeude_meldung)
	_gebaeude.gebaeude_platziert.connect(_auf_gebaeude_platziert)
	# Produktionszeile als Ereignis statt Frame-Abfrage: Der Manager meldet
	# jede Zustandsänderung selbst, das HUD liest nur die Meldung.
	_gebaeude.status_geaendert.connect(_auf_produktion_status)
	_auf_produktion_status(_gebaeude.status_zeilen())
	# Einstiegs-Progression: Die Maschine ist die einzige Stufen-Wahrheit;
	# die Szene verdrahtet nur, Bauabschlüsse und Einwanderer melden sich
	# über die Manager, das HUD zeigt die aktuelle Zielzeile.
	var fortschritt_registry := Welt_FortschrittsRegistry.new()
	_fortschritt.registry_setzen(fortschritt_registry)
	_fortschritt.ziel_erreicht.connect(_auf_ziel_erreicht)
	_fortschritt.stufe_erreicht.connect(_auf_stufe_erreicht)
	_karten_beobachter.einrichten(_model, _generator, _tiere)
	_orchestrator_registry.laden(ORCHESTRATOR_PFAD)
	_orchestrator_manager.referenzen_setzen(_stockmaenner, _model, _registry, _job_registry)
	add_child(_orchestrator_manager)
	_orchestrator_darsteller = _orchestrator_verdrahtung.verdrahten(_orchestrator_registry, _orchestrator_manager, self)
	_hud.einrichten(_ressourcen)
	_kontext.einrichten(_steuerung, _fortschritt)
	_kontext.aktion_gewaehlt.connect(_auf_kontext_aktion)
	# Erste Einheit erst mit dem ersten Lagerfeuer: Sie wandert am Anker
	# ein, sobald die Einstiegs-Kette das Lagerfeuer meldet. Vorher ist die
	# Karte leer und das Ziel sichtbar.
	_fortschritt.stufe_erreicht.connect(_auf_erste_einheit)
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
		"fortschritt": _fortschritt,
	})
	var zurueck_knopf: Button = %ZurueckKnopf
	zurueck_knopf.pressed.connect(_auf_zurueck)
	_pause_menue = Welt_PauseMenue.new()
	add_child(_pause_menue)
	_pause_menue.menue_gewuenscht.connect(_auf_zurueck)
	# Fenster-Panels: alle als modulare Control-Spitzen unter dem HUD-
	# CanvasLayer eingehängt; sie lesen nur über ihre Panel-Controller aus
	# den bestehenden Maschinen. Kein neuer Schnittpunkt, nur Sichtbarkeit.
	_debug_panel_bauen()
	_bau_panel_bauen()
	_eingabe_steuerung.debug_umgeschaltet.connect(_auf_debug_umgeschaltet)
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

func _ladevorgang_ausfuehren() -> void:
	## Slice D: Kapselt den Ladevorgang aus welt_ladevorgang.gd und map_fabrik.gd.
	_ladevorgang.einrichten(_model, _generator)
	_map_fabrik.einrichten(_generator)
	_ladevorgang.ausfuehren(WeltSitzung.welt_name, WeltSitzung.seed_wunsch, _model.biom_id)

func _domaenen_modell_setzen(neues_modell: Welt_Model) -> void:

	## Slice D: Zentrale atomare Umstellung aller fachlichen Domänen auf ein Modell.
	## Wird sowohl beim ersten Start als auch beim Kartenwechsel genutzt.
	_model = neues_modell
	_stockmaenner.modell_wechseln(_model, _tiere)
	_eingabe_steuerung.modell_wechseln(_model, _tiere)
	_gebaeude.modell_wechseln(_model)
	_progression.einrichten(_model, _biome, _tageszyklus)

func _modell_ersetzen(neues_modell: Welt_Model) -> void:
	## Atomarer Kartenwechsel-Handshake: Alle modellhaltenden Domänen werden
	## auf das neue Modell umgestellt, bevor die Darstellung folgt.
	if neues_modell == null:
		return
	# Darstellung zuerst: Die neue Karte ist die Wahrheit.
	_karte.darstellen(neues_modell, _registry, _biome)
	_kamera.position = Vector2(neues_modell.groesse()) * float(neues_modell.kachel_groesse) / 2.0
	# Lager + Tiere: Lagerfabrik und Tier-Platzierer setzen intern zurück.
	_lager_fabrik.anlegen_aus_welt(neues_modell, _lager, _kamera.position)
	_tier_platzierer.platzieren(neues_modell, _registry, _tiere)
	# Wärme neu berechnen
	_waerme_sammler.sammeln(neues_modell, _stockmaenner)
	# Domänen atomar umschalten
	_domaenen_modell_setzen(neues_modell)
	# Karten-Minimap und Beobachter
	if _karten_viewer != null:
		_karten_viewer.einrichten(_model, _registry, _biome)
	_karten_beobachter.einrichten(_model, _generator, _tiere)
	_auswahl.auswahl_leeren()

func _input(ereignis: InputEvent) -> void:
	_eingabe_steuerung.eingabe(ereignis, self, _auf_verteilung)


func _auf_gebaeude_platziert(objekt_index: int) -> void:

	# Das neue Gebäude sofort visuell einhängen und die Domänen nachziehen.
	_karte.objekt_knoten_anhaengen(objekt_index)
	_karte.sichtgebiet_aktualisieren()
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_waerme_sammler.sammeln(_model, _stockmaenner)
	## Befund 6: Das Wegenetz kennt neue Gebäude erst nach diesem Aufruf.
	## Vorher liefen Einheiten planerisch durch jedes nach dem ersten Haus
	## errichtete Gebäude, weil das Netz beim initialen einrichten() eingefroren blieb.
	_stockmaenner.weg_planung_aktualisieren()
	if _landeplatz != null:
		_landeplatz.ausblenden()
		_landeplatz = null



func _process(delta: float) -> void:
	_kamera_steuerung.kamera_bewegen(delta, _kamera)
	_tiere.spieler_position_setzen(_kamera.position)
	# RTS-Prinzip: Kamera und Einheiten sind entkoppelt. Stickmen bewegen
	# sich ausschließlich über Jobs (Einheit_Status + Rathaus/Orchestrator),
	# niemals durch unmittelbares Setzen ihrer Position pro Frame.
	_karten_beobachter.beobachten(_karten_viewer, _karten_info, _karten_ebene, _kamera_steuerung.kamera_position, _kamera)
	# Sichtbarkeits-Scheibe: Nur sichtbare Weltobjekte tragen Knoten; das
	# Modell bleibt die volle Wahrheit. Ohne Kamera bleibt der Bestand voll.
	if _kamera != null:
		var blick := _kamera.get_viewport_rect().size / _kamera.zoom.x
		_karte.sichtbereich_setzen(Rect2(_kamera.position - blick * 0.5 - Vector2.ONE * _karte.SICHT_RAND_PX, blick + Vector2.ONE * (_karte.SICHT_RAND_PX * 2.0)))

func _debug_panel_bauen() -> void:
	# Debug-Fenster als eigener Knoten unter der UI-Ebene. Es ist standardmäßig
	# unsichtbar; nur der Debug-Schalter (F3) macht es sichtbar. Damit liegt
	# der Einheiten- und Tierzustand nicht mehr im Normalbild über der Karte.
	var canvas: CanvasLayer = %UILayer as CanvasLayer
	if canvas == null:
		return
	_debug_panel = _DebugPanelSkript.new()
	_debug_panel.name = "DebugPanel"
	_debug_panel.visible = false
	_debug_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_debug_panel.offset_left = -420.0
	_debug_panel.offset_top = 96.0
	_debug_panel.custom_minimum_size = Vector2(408, 0)
	_debug_panel.call("einrichten", _auswahl, _stockmaenner, _tiere)
	canvas.add_child(_debug_panel)

func _auf_produktion_status(zeilen: Array[String]) -> void:
	# Reiner Weitergabe-Schritt: Die Zeilen kommen vom Gebaeude_Manager, das
	# HUD zeigt sie; die Szene rechnet nichts nach.
	(_hud as Variant).produktion_anzeigen(zeilen)

func _bau_panel_bauen() -> void:
	var canvas: CanvasLayer = %UILayer as CanvasLayer
	if canvas == null:
		return
	_bau_panel = _BauPanelSzene.instantiate()
	_bau_panel.name = "BauPanel"
	_bau_panel.einrichten(_gebaeude_definitionen, _fortschritt, _steuerung)
	_bau_panel.bau_gewaehlt.connect(_auf_bau_gewaehlt)
	canvas.add_child(_bau_panel)

func _auf_bau_gewaehlt(gebaeude_id: String) -> void:
	_eingabe_steuerung.bau_auftrag_setzen(gebaeude_id)

func _auf_debug_umgeschaltet(sichtbar: bool) -> void:
	# Der Schalter aus dem Eingabe-Übersetzer ist die einzige Quelle der
	# Debug-Sichtbarkeit; das Fenster gehorcht.
	if _debug_panel != null:
		_debug_panel.call("sichtbar_setzen", sichtbar)

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




func _auf_ziel_erreicht(stufe: Dictionary) -> void:
	_hud.meldung_setzen("Ziel erreicht: %s" % str(stufe.get("id", "")))
	_hud.meldung_setzen(_fortschritt.ziel_zeile())

func _auf_erste_einheit(_stufe: Dictionary) -> void:
	# Die erste Einheit wandert mit dem Lagerfeuer ein: Vorher lebt die
	# Karte allein von ihrem Ziel, und die Einwanderung startet nicht doppelt.
	if _stockmaenner.einheit_zahl() > 0:
		return
	if _landeplatz != null:
		_landeplatz.ausblenden()
		_landeplatz = null
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_waerme_sammler.sammeln(_model, _stockmaenner)
	_stockmaenner.einheit_hinzufuegen(_stockmaenner.lager_anker_position() + Vector2(0, 48))
	_hud.meldung_setzen("Der erste Siedler ist am Lagerfeuer angekommen.")

func _auf_stufe_erreicht(stufe: Dictionary) -> void:
	# Neue Stufe: Das HUD nennt die freigeschaltete Stufe und das nächste
	# Ziel; das Kontextmenü und das Bau-Panel bauen ihre Freischaltungen neu auf.
	var freigaben: Array[String] = []
	for gebaeude_id: Variant in (stufe.get("schaltet_frei", {}).get("gebaeude", []) as Array):
		freigaben.append(str(gebaeude_id))
	if not freigaben.is_empty():
		_hud.meldung_setzen("Neu freigeschaltet: %s" % ", ".join(freigaben))
	_hud.meldung_setzen(_fortschritt.ziel_zeile())
	_kontext.eintraege_aufbauen()
	if _bau_panel != null:
		_bau_panel.aktualisieren()

func _auf_timeline_eintrag(eintrag: Kern_TimelineEintrag) -> void:
	# Reine Beobachtung: Die Timeline meldet, das HUD zeigt die Begruendung.
	_hud.timeline_anzeigen(eintrag.delta_text())
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_timeline_eintrag(eintrag.delta_text())
