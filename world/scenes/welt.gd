extends Node2D
## Welt: reine Endzustands-Visualisierung. Sie besitzt keine fremde Logik:
## Kein Lager-Bau, kein Tier-Spawn, kein Generator-Loop, keine Kamera-Formel,
## keine Input-Entscheidung. Jede fachliche Aufgabe liegt in ihrer eigenen
## Spitze; diese Datei verdrahtet nur Observer und Visualisierungen.
## Fluss: Eingabe -> Ui_EingabeSteuerung/Ui_KameraSteuerung -> Maschinen
## -> Zustand -> Welt_Renderer/HUD/Karten-Beobachter lesen und zeigen.

const ORCHESTRATOR_PFAD := "res://game/data/orchestrator_config.json"
const _AuswahlManagerSkript := preload("res://ui/scenes/selection/auswahl_manager.gd")
const _LandeplatzAnzeigeSkript := preload("res://world/logic/kategorie_welt/welt_landeplatz_anzeige.gd")
const _OrchestratorPriorityPanelSkript := preload("res://ui/logic/kategorie_ui/ui_orchestrator_priority_panel.gd")

## Kategorie daten: Modell und Registries als Quellen der Visualisierung.
## Kategorie logik: Verdrahtung der Observer- und Visualisierungs-Spitzen.
var _model := Welt_Model.new()
var _registry := Welt_RegistryZugriff.welt()
var _steuerung := Kern_SteuerungRegistry.new()
var _rassen_registry := Pop_RassenZugriff.registry()
var _lager := Lager_Manager.new()
var _ressourcen := Einheit_Ressourcen.new()
var _job_registry := Job_Registry.new()
var _stockmaenner := Einheit_Manager.new()
var _tageszyklus := Welt_TageszyklusMaschine.new()
var _tages_overlay: CanvasLayer = null
var _waerme_overlay: CanvasLayer = null
var _auswahl := _AuswahlManagerSkript.new()
var _schnellwahl: Array[int] = []
var _orchestrator_registry := Orchestrator_Registry.new()
var _orchestrator_manager := Orchestrator_Manager.new()
var _biome := Welt_RegistryZugriff.biom()
var _generator := Welt_Generator.new()
var _gebaeude_definitionen := Gebaeude_DefinitionRegistry.new()
var _karten_ebene: CanvasLayer = null
var _karten_viewer: Ui_KartenViewer = null
var _karten_info: Ui_WeltInfo = null
## UI-Aufbau-Spitze: Baut Panels, Kartenebene und Lager-Darsteller.
var _ui_aufbau := Welt_UiAufbau.new()
## LadeLeiste-Ebene: Eigene Schicht für den Lader-Balken; die Deklaration
## gehört zur Szene, die Nutzung sitzt in der Orchestrator-UI-Phase.
var _lade_canvas: CanvasLayer = null
## Phasen-Anker des Aufbaus: Kartenmitte und Beobachtungsradius, die mehrere
## Aufbau-Phasen gemeinsam nutzen.
var _start_position := Vector2.ZERO
var _bereich := 0.0

## Unter-Spitzen: Jede hält genau eine Zuständigkeit.
var _ladevorgang := Welt_Ladevorgang.new()
var _map_fabrik := Welt_MapFabrik.new()
var _gebaeude := Gebaeude_Manager.new()
var _moebel_platzierer: Objekt_MoebelPlatzierer = null
var _lager_fabrik := Welt_LagerFabrik.new()
var _tier_platzierer := Welt_TierPlatzierer.new()
var _waerme_sammler := Welt_WaermeSammler.new()
var _need_baum := Pop_NeedBaum.new()
var _fortschritt := Welt_FortschrittsMaschine.new()
var _fortschritt_verdrahtung := Welt_FortschrittVerdrahtung.new()
var _raum_und_lager := Welt_RaumUndLagerTick.new()
var _karten_beobachter := Welt_KartenBeobachter.new()
var _timeline := Kern_Timeline.new()
var _feedback := Welt_FeedbackManager.new()
var _atmosphaere := Welt_AtmosphaereVerdrahtung.new()
var _progression := Welt_ProgressionsMaschine.new()
## Sozial-Domaene: Eigene Fassade, hoert am Kern-SignalBus und tickt an der Uhr.
var _sozial := Soz_Manager.new()
## Der Wasser-Automat gehört zur Welt-Domäne: Er schreibt nur übers Modell
## und läuft nur, wenn der Schalter in welt_definition.json ihn läßt.
var _wasser := Welt_WasserAutomat.new()
var _orchestrator_verdrahtung := Orchestrator_Verdrahtung.new()
var _kamera_steuerung := Ui_KameraSteuerung.new()
var _eingabe_steuerung := Ui_EingabeSteuerung.new()
var _pause_menue: Welt_PauseMenue = null
var _orchestrator_darsteller: Array[Orchestrator_Darsteller] = []
var _fraktions_ki := Welt_FraktionsKiVerdrahtung.new()
## Rückmelde-Spitze: trägt die reinen Anzeige-Handler zwischen Maschinen und HUD.
var _rueckmeldung := Welt_HudRueckmeldung.new()
var _orchestrator_priority_panel: Ui_OrchestratorPriorityPanel = null
## Die Panel- und Kartenreferenzen hält die UI-Aufbau-Spitze; die Szene liest
## sie von dort. Der Debug-Schalter bleibt als einziger Sichtbarkeits-Weg.
var _landeplatz: Node2D = null
## Zeitgeslicener Chunk-Lader: läuft nach frischer Generierung und zieht
## die Welt in 16-ms-Budgets pro Frame nach, statt alles in einem Ruck.
var _chunk_lader: Welt_AsyncChunkLader = null

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _tiere: Tier_Manager = %Tiere
@onready var _hud: VBoxContainer = %HUD
@onready var _rechteck: Control = %AuswahlRechteck
@onready var _kontext: PopupMenu = %KontextMenue

func _ready() -> void:
	## Aufbau in fünf benannten Phasen, in der Reihenfolge des Datenflusses:
	## Uhr und Overlays, Karte und Atmosphaere, Domaenen und Einheiten,
	## Gebaeude und Fortschritt, Orchestrator und UI. Jede Phase haelt genau
	## ihren Zuständigkeits-Ausschnitt; die Szene bleibt der Kompositions-
	## Wurzelknoten, der nur zusammensetzt.
	_bereit_uhr_und_overlays()
	_bereit_karte_und_atmosphaere()
	_bereit_domaenen_und_einheiten()
	_bereit_gebaeude_und_fortschritt()
	_bereit_orchestrator_und_ui()

func _bereit_uhr_und_overlays() -> void:
	var aktionen_neu := _steuerung.inputmap_registrieren()
	print("Steuerung: %d Eingabe-Tasten aus steuerung.json in die InputMap geschrieben." % aktionen_neu)
	_ladevorgang_ausfuehren()
	_tageszyklus.einrichten(_need_baum.takt_minuten(), _need_baum.tag_minuten(), _need_baum.nacht_minuten())
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_tageszyklus.tick):
		weltuhr.tick.connect(_tageszyklus.tick)
	_tages_overlay = preload("res://world/scenes/tageszyklus_overlay.gd").new()
	(_tages_overlay as CanvasLayer).layer = 20
	add_child(_tages_overlay)
	(_tages_overlay as Object).call("einrichten", _tageszyklus)
	_waerme_overlay = preload("res://world/scenes/waerme_overlay.tscn").instantiate()
	(_waerme_overlay as CanvasLayer).layer = 10
	add_child(_waerme_overlay)

func _bereit_karte_und_atmosphaere() -> void:
	_start_position = Vector2(_model.groesse()) * float(_model.kachel_groesse) / 2.0
	_bereich = maxf(_model.groesse().x, _model.groesse().y) * float(_model.kachel_groesse) * 0.6
	_karte.darstellen(_model, _registry, _biome)
	_karte.progressions_maschine_setzen(_progression)
	_wasser.einrichten(_model, _registry)
	_atmosphaere.bereich_setzen(_start_position, _bereich)
	add_child(_atmosphaere)
	_atmosphaere.einrichten(_tageszyklus, _start_position, _bereich)
	_atmosphaere.weltuhr_verbinden()
	_karte.sway_material_quelle_setzen(_atmosphaere.sway_material_quelle())
	_stockmaenner.schlag_ort_empfaenger_setzen(_atmosphaere.staub_zeigen)
	add_child(_feedback)
	_feedback.einrichten(_ressourcen)
	add_child(_sozial)
	_ui_aufbau.karten_ebene_bauen(self, _model, _registry, _biome)
	_karten_ebene = _ui_aufbau.karten_ebene
	_karten_viewer = _ui_aufbau.karten_viewer
	_karten_info = _ui_aufbau.karten_info
	_tier_platzierer.platzieren(_model, _registry, _tiere)
	_kamera_steuerung.einrichten(_steuerung, _model, _start_position)
	_tiere.spieler_position_setzen(_kamera_steuerung.kamera_position)
	_kamera.position = _kamera_steuerung.kamera_position
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_ui_aufbau.lager_darsteller_einrichten(_lager, _ressourcen)
	_ressourcen.lager_setzen(_lager)
	_ressourcen.timeline_setzen(_timeline)
	_timeline.eintrag_neu.connect(_auf_timeline_eintrag)

func _bereit_domaenen_und_einheiten() -> void:
	add_child(_need_baum)
	_raum_und_lager.einrichten(_model, _lager)
	add_child(_raum_und_lager)
	_stockmaenner.einrichten(_model, _tiere, _ressourcen)
	_stockmaenner.schlag_empfaenger_setzen(_progression.schlag)
	_stockmaenner.schlag_ort_empfaenger_setzen(_atmosphaere.staub_zeigen)
	_progression.einrichten(_model, _biome, _tageszyklus)
	add_child(_progression)
	_progression.objekt_erschoepft.connect(_atmosphaere.staub_zeigen)
	_stockmaenner.fortschritt_setzen(_fortschritt)
	_stockmaenner.need_baum_setzen(_need_baum)
	_stockmaenner.lager_setzen(_lager)
	_stockmaenner.tageszyklus_setzen(_tageszyklus)
	_waerme_sammler.sammeln(_model, _stockmaenner, _waerme_overlay)
	_stockmaenner.y_sort_enabled = true
	add_child(_stockmaenner)
	_landeplatz = _LandeplatzAnzeigeSkript.new()
	_landeplatz.name = "LandeplatzAnzeige"
	_landeplatz.einrichten(_start_position, float(_model.kachel_groesse))
	add_child(_landeplatz)

func _bereit_gebaeude_und_fortschritt() -> void:
	_gebaeude.einrichten(_model, _registry, _ressourcen, _lager, _fortschritt)
	add_child(_gebaeude)
	_gebaeude.gebaeude_meldung.connect(_auf_gebaeude_meldung)
	_gebaeude.gebaeude_platziert.connect(_auf_gebaeude_platziert)
	_moebel_platzierer = Objekt_MoebelPlatzierer.new()
	_moebel_platzierer.einrichten(_model, _registry)
	_moebel_platzierer.moebel_platziert.connect(_auf_gebaeude_platziert)
	_gebaeude.status_geaendert.connect(_auf_produktion_status)
	_rueckmeldung.produktion_anzeigen(_gebaeude.status_zeilen())
	var fortschritt_registry := Welt_FortschrittsRegistry.new()
	_fortschritt.registry_setzen(fortschritt_registry)
	_fortschritt.model_setzen(_model)
	_fortschritt.ziel_erreicht.connect(_auf_ziel_erreicht)
	_fortschritt.stufe_erreicht.connect(_auf_stufe_erreicht)
	_karten_beobachter.einrichten(_model, _generator, _tiere)

func _bereit_orchestrator_und_ui() -> void:
	_orchestrator_registry.laden(ORCHESTRATOR_PFAD)
	_orchestrator_manager.referenzen_setzen(_stockmaenner, _model, _registry, _job_registry)
	add_child(_orchestrator_manager)
	_orchestrator_darsteller = _orchestrator_verdrahtung.verdrahten(_orchestrator_registry, _orchestrator_manager, self)
	_hud.einrichten(_ressourcen)
	_rueckmeldung.einrichten(_hud, _fortschritt)
	_kontext.einrichten(_steuerung, _fortschritt)
	_kontext.aktion_gewaehlt.connect(_auf_kontext_aktion)
	_lade_canvas = CanvasLayer.new()
	_lade_canvas.layer = 25
	add_child(_lade_canvas)
	_ui_aufbau.lade_leiste_bauen(_lade_canvas)
	_orchestrator_priority_panel = _OrchestratorPriorityPanelSkript.new()
	_orchestrator_priority_panel.name = "OrchestratorPriorityPanel"
	_orchestrator_priority_panel.einrichten(_orchestrator_manager, _auswahl)
	add_child(_orchestrator_priority_panel)

	# Verbinde Fortschritts-Verdrahtung mit Einheiten und Orchestrator:
	# Bus-Brücke und Vorarbeiter-Spawn wohnen in der Verdrahtung.
	_fortschritt_verdrahtung.einrichten(_fortschritt)
	_fortschritt_verdrahtung.einheit_manager_setzen(_stockmaenner)
	_fortschritt_verdrahtung.orchestrator_manager_setzen(_orchestrator_manager)

	## Fraktions-KI über die Domänen-Spitze: Die Szene reicht nur die
	## Referenzen hinein; Config, Netzwerk, Keimlinge, Rassen und KI-Maschinen
	## wohnen in der Verdrahtung.
	_fraktions_ki.initialisieren({
		"model": _model,
		"biome": _biome,
		"rassen_registry": _rassen_registry,
		"map_fabrik": _map_fabrik,
		"lager": _lager,
	})
	_fortschritt.stufe_erreicht.connect(_auf_erste_einheit)
	_stockmaenner.ankunftsort_setzen(_ankunftsort)
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
		"fortschritt": _fortschritt,
		"raum_und_lager": _raum_und_lager,
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
		"moebel_platzierer": _moebel_platzierer,
		"map_fabrik": _map_fabrik,
		"modell_ersetzen": _modell_ersetzen,
		"signal_bus": Kern_SignalBus.bus(),
		"orchestrator_panel": _orchestrator_priority_panel,
		"orchestrator_manager": _orchestrator_manager,
		"definitionen": _gebaeude_definitionen,
		"bau_panel": _ui_aufbau.bau_panel,
	})
	var zurueck_knopf: Button = %ZurueckKnopf
	if zurueck_knopf != null:
		zurueck_knopf.pressed.connect(_auf_zurueck)
	var warum_knopf: Button = %WarumKnopf
	if warum_knopf != null:
		warum_knopf.visible = false
	_pause_menue = Welt_PauseMenue.new()
	add_child(_pause_menue)
	_pause_menue.menue_gewuenscht.connect(_auf_zurueck)
	_ui_aufbau.debug_panel_bauen(%UILayer as CanvasLayer, _auswahl, _stockmaenner, _tiere)
	_ui_aufbau.bau_panel_bauen(%UILayer as CanvasLayer, _gebaeude_definitionen, _fortschritt, _steuerung, _auf_bau_gewaehlt, _registry)
	_ui_aufbau.pop_einheit_panel_bauen(%UILayer as CanvasLayer, _need_baum, _stockmaenner, _ressourcen)
	# Lagerzone-Register an BauAuftragMaschine durchreichen: Der B-Toggle
	# greift ab hier auf echte Raumprüfung und Lager-Entscheid.
	if _eingabe_steuerung != null and _raum_und_lager != null:
		_eingabe_steuerung.bau_lagerzone_register_setzen(_raum_und_lager.lagerzone_register())
		_eingabe_steuerung.bau_panel_setzen(_ui_aufbau.bau_panel)
		_eingabe_steuerung.bau_definitionen_setzen(_gebaeude_definitionen)
	_eingabe_steuerung.debug_umgeschaltet.connect(_auf_debug_umgeschaltet)
	_hud.warum_verdrahten(%WarumKnopf, %WarumFenster, %WarumText)
	_fenster_leiste_bauen()

func _ladevorgang_ausfuehren() -> void:
	_ladevorgang.einrichten(_model, _generator)
	_map_fabrik.einrichten(_generator)
	_karte.sprites_faul_setzen(true)
	_ladevorgang.ausfuehren(WeltSitzung.welt_name, WeltSitzung.seed_wunsch, _model.biom_id)
	_chunk_lader = _ladevorgang.lauf_lader
	if _chunk_lader != null:
		_chunk_lader.fertig.connect(_auf_welt_gefuellt)
		_chunk_lader.chunk_gefuellt.connect(_auf_chunk_gefuellt)
	else:
		_karte.sprites_faul_setzen(false)

func _domaenen_modell_setzen(neues_modell: Welt_Model) -> void:
	_model = neues_modell
	_stockmaenner.modell_wechseln(_model, _tiere)
	_eingabe_steuerung.modell_wechseln(_model, _tiere)
	_gebaeude.modell_wechseln(_model)
	_raum_und_lager.model_setzen(_model)
	_fortschritt.model_setzen(_model)
	_progression.einrichten(_model, _biome, _tageszyklus)

func _modell_ersetzen(neues_modell: Welt_Model) -> void:
	if neues_modell == null:
		return
	_karte.darstellen(neues_modell, _registry, _biome)
	_kamera.position = Vector2(neues_modell.groesse()) * float(neues_modell.kachel_groesse) / 2.0
	_lager_fabrik.anlegen_aus_welt(neues_modell, _lager, _kamera.position)
	_ui_aufbau.lager_darsteller_einrichten(_lager, _ressourcen)
	_tier_platzierer.platzieren(neues_modell, _registry, _tiere)
	_waerme_sammler.sammeln(neues_modell, _stockmaenner, _waerme_overlay)
	_domaenen_modell_setzen(neues_modell)
	_fraktions_ki.modell_aktualisieren(neues_modell)
	if _karten_viewer != null:
		_karten_viewer.einrichten(_model, _registry, _biome)
	_karten_beobachter.einrichten(_model, _generator, _tiere)
	_auswahl.auswahl_leeren()

func _input(ereignis: InputEvent) -> void:
	_eingabe_steuerung.eingabe(ereignis, self, _auf_verteilung)

func _auf_gebaeude_platziert(objekt_index: int) -> void:
	_karte.objekt_knoten_anhaengen(objekt_index)
	_karte.sichtgebiet_aktualisieren()
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_ui_aufbau.lager_darsteller_einrichten(_lager, _ressourcen)
	_raum_und_lager.lager_setzen(_lager)
	_waerme_sammler.sammeln(_model, _stockmaenner, _waerme_overlay)
	_stockmaenner.weg_planung_aktualisieren()
	if _landeplatz != null:
		_landeplatz.ausblenden()
		_landeplatz = null

func _process(delta: float) -> void:
	if _chunk_lader != null and _chunk_lader.laeuft:
		_chunk_lader.schritt()
		if _chunk_lader != null and _ui_aufbau.lade_leiste != null:
			_ui_aufbau.lade_leiste.anteil_setzen(_chunk_lader.fortschritt_anteil())
	_kamera_steuerung.kamera_bewegen(delta, _kamera)
	_tiere.spieler_position_setzen(_kamera.position)
	_atmosphaere.kamera_stelle(_kamera.position, _bereich)
	_karten_beobachter.beobachten(_karten_viewer, _karten_info, _karten_ebene, _kamera_steuerung.kamera_position, _kamera)
	if _kamera != null:
		var blick := _kamera.get_viewport_rect().size / _kamera.zoom.x
		var rand := _karte.sicht_rand_px()
		var blick_rechteck := Rect2(_kamera.position - blick * 0.5 - Vector2.ONE * rand, blick + Vector2.ONE * (rand * 2.0))
		_karte.sichtbereich_setzen(blick_rechteck)
		_tiere.sichtbereich_setzen(blick_rechteck)

func _auf_produktion_status(zeilen: Array[String]) -> void:
	_rueckmeldung.produktion_anzeigen(zeilen)

func _auf_bau_gewaehlt(gebaeude_id: String) -> void:
	_eingabe_steuerung.bau_auftrag_setzen(gebaeude_id)

func _auf_debug_umgeschaltet(_sichtbar: bool) -> void:
	# Die Szene reicht nur den Signal-Wert durch; die Leiste pflegt sich selbst.
	if _ui_aufbau.debug_panel != null:
		_ui_aufbau.debug_panel.call("sichtbar_setzen", _sichtbar)
	if _ui_aufbau.fenster_leiste != null:
		_ui_aufbau.fenster_leiste.aktualisieren()
	if _karten_ebene != null and _ui_aufbau.fenster_leiste != null:
		_ui_aufbau.fenster_leiste.aktualisieren()

func _unhandled_input(ereignis: InputEvent) -> void:
	_eingabe_steuerung.unhandled_input(
		ereignis,
		func(e: InputEventMouseButton) -> Vector2: return _eingabe_steuerung.klick_position(e),
		func() -> void: _eingabe_steuerung.rechteck_pflegen_bild(get_global_mouse_position(), get_viewport().get_canvas_transform(), _auswahl.ziehen_start),
		func(e: InputEventKey) -> void: _eingabe_steuerung.hotkey_verarbeiten(e)
	)

func _auf_verteilung(nahrung_je_takt: float) -> void:
	_eingabe_steuerung.auf_verteilung(nahrung_je_takt)

func _auf_chunk_gefuellt(chunk: Vector2i) -> void:
	if _model == null:
		return
	_karte.kachel_erneuern_fuer_chunk(chunk, _model.aktive_z_ebene)

func _auf_welt_gefuellt() -> void:
	if _chunk_lader == null:
		return
	_chunk_lader = null
	_generator.welt_abschliessen(_model, _model.welt_seed, _model.biom_id)
	_karte.faulbau_abschliessen()
	if _ui_aufbau.lade_leiste != null:
		_ui_aufbau.lade_leiste.fertig_anzeigen()
	var world := WeltSitzung.world
	if world != null and WeltSitzung.aktive_map_id != "":
		Welt_Ladevorgang.welt_speichern_aktiv(world, WeltSitzung.aktive_map_id)
	_karte.sichtgebiet_aktualisieren()
	_ladevorgang.lauf_lader = null

func _auf_kontext_aktion(aktion: Dictionary) -> void:
	_eingabe_steuerung.auf_kontext_aktion(aktion)

func _biom_anzeigen() -> void:
	var zustand := _model.biom_zustand()
	_rueckmeldung.biom_anzeigen(str(zustand.get("biom_id", _model.biom_id)), float(zustand.get("biom_faktor", 1.0)))

func model_liefern() -> Welt_Model:
	return _model

func lager_liefern() -> Lager_Manager:
	return _lager

func gebaeude_liefern() -> Gebaeude_Manager:
	return _gebaeude

func ressourcen_liefern() -> Einheit_Ressourcen:
	return _ressourcen

func einheiten_liefern() -> Einheit_Manager:
	return _stockmaenner

func _auf_zurueck() -> void:
	WeltSitzung.uebergang_ziel = "res://ui/scenes/hauptmenue.tscn"
	WeltSitzung.uebergang_text = "Zurück zum Hauptmenü …"
	get_tree().change_scene_to_file("res://ui/scenes/uebergang.tscn")

func _auf_gebaeude_meldung(meldung_text: String) -> void:
	_rueckmeldung.gebaeude_meldung_anzeigen(meldung_text)

func _auf_ziel_erreicht(stufe: Dictionary) -> void:
	_rueckmeldung.ziel_erreicht_anzeigen(stufe)

func _auf_erste_einheit(_stufe: Dictionary) -> void:
	if _stockmaenner.einheit_zahl() > 0:
		return
	if _landeplatz != null:
		_landeplatz.ausblenden()
		_landeplatz = null
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_waerme_sammler.sammeln(_model, _stockmaenner, _waerme_overlay)
	var ankunft := _ankunftsort()
	_stockmaenner.einheit_hinzufuegen(ankunft)
	_sozial.einheit_anmelden(_stockmaenner.einheit_zahl() - 1, ankunft, ["tratscht_gerne"])
	_hud.meldung_setzen("Der erste Siedler ist am Lagerfeuer angekommen.")

func _ankunftsort() -> Vector2:
	var blick := _kamera.get_screen_center_position()
	var naechstes := Vector2.INF
	var beste_distanz := INF
	for index in _model.objekt_anzahl():
		if str(_model.objekt_feld(index, "gebaeude_id", "")) != "lagerfeuer":
			continue
		var position := _model.objekt_position(index)
		var distanz := position.distance_to(blick)
		if distanz < beste_distanz:
			beste_distanz = distanz
			naechstes = position
	if naechstes != Vector2.INF:
		return naechstes + Vector2(0, 48)
	var anker := _stockmaenner.lager_anker_position() + Vector2(0, 48)
	if _im_blick(anker):
		return anker
	return blick + Vector2(0, 48)

func _im_blick(welt_position: Vector2) -> bool:
	var mitte := _kamera.get_screen_center_position()
	var halb := _kamera.get_viewport_rect().size * 0.5 / _kamera.zoom
	var abweichung := (welt_position - mitte).abs()
	return abweichung.x <= halb.x and abweichung.y <= halb.y

func _auf_stufe_erreicht(stufe: Dictionary) -> void:
	var freigaben: Array[String] = []
	for gebaeude_id: Variant in (stufe.get("schaltet_frei", {}).get("gebaeude", []) as Array):
		freigaben.append(str(gebaeude_id))
	if not freigaben.is_empty():
		_hud.meldung_setzen("Neu freigeschaltet: %s" % ", ".join(freigaben))
	_hud.meldung_setzen(_fortschritt.ziel_zeile())
	_kontext.eintraege_aufbauen()
	if _ui_aufbau.bau_panel != null:
		_ui_aufbau.bau_panel.aktualisieren()
	if _ui_aufbau.fenster_leiste != null:
		_ui_aufbau.fenster_leiste.aktualisieren()

func _auf_timeline_eintrag(eintrag: Kern_TimelineEintrag) -> void:
	_rueckmeldung.timeline_anzeigen(eintrag.delta_text())


func _fenster_leiste_bauen() -> void:
	var canvas := get_node_or_null("%UILayer") as CanvasLayer
	if canvas == null:
		canvas = get_node_or_null("UILayer") as CanvasLayer
	if canvas == null:
		return
	var eintraege: Array[Dictionary] = [
		{
			"id": "bau",
			"name": "Bau",
			"shortcut": "B",
			"tooltip": "Baufenster öffnen/schließen [B]",
			"aktion": _eingabe_steuerung.bau_panel_umschalten,
			"sichtbar": func() -> bool: return _ui_aufbau.bau_panel != null and _ui_aufbau.bau_panel.visible,
		},
		{
			"id": "karte",
			"name": "Karte",
			"shortcut": "M",
			"tooltip": "Weltkarte umschalten [M]",
			"aktion": _eingabe_steuerung.karten_umschalten,
			"sichtbar": func() -> bool: return _karten_ebene != null and _karten_ebene.visible,
		},
		{
			"id": "debug",
			"name": "Debug",
			"shortcut": "F3",
			"tooltip": "Debug-Overlay umschalten [F3]",
			"aktion": _eingabe_steuerung.debug_umschalten,
			"sichtbar": func() -> bool: return _ui_aufbau.debug_panel != null and _ui_aufbau.debug_panel.visible,
		},
		{
			"id": "warum",
			"name": "Warum?",
			"shortcut": "",
			"tooltip": "Begründungen der letzten Buchungen anzeigen",
			"aktion": _hud.warum_oeffnen,
			"sichtbar": func() -> bool: return false,
		},
		{
			"id": "menu",
			"name": "Menü",
			"shortcut": "Esc",
			"tooltip": "Ins Hauptmenü",
			"aktion": _auf_zurueck,
			"sichtbar": func() -> bool: return false,
		},
	]
	_ui_aufbau.fenster_leiste_bauen(canvas, eintraege)
