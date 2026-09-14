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
	_waerme_overlay = preload("res://world/scenes/waerme_overlay.tscn").instantiate()
	(_waerme_overlay as CanvasLayer).layer = 10
	add_child(_waerme_overlay)

func _bereit_karte_und_atmosphaere() -> void:
	_start_position = Vector2(_model.groesse()) * float(_model.kachel_groesse) / 2.0
	_bereich = maxf(_model.groesse().x, _model.groesse().y) * float(_model.kachel_groesse) * 0.6
	_karte.darstellen(_model, _registry, _biome)
	_karte.progressions_maschine_setzen(_progression)
	# Wasser-Domäne: Der Automat wird erstmals richtig instanziiert und
	# lauscht an Uhr und Signalbus; ob er eingreift, entscheidet allein der
	# Daten-Schalter in welt_definition.json.
	_wasser.einrichten(_model, _registry)
	# Atmosphaeren-Domaene: Die Szene haengt nur die Spitze an und reicht
	# Tageszyklus, Kartenmitte und Radius weiter. Jede Fachlogik bleibt in
	# der Domaene; die Sway-Quelle fuer den Renderer kommt von dort.
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
	# Die Zustands-Timeline beobachtet jede Buchung der Ressourcen und
	# meldet sie ueber den Bus, damit das HUD den Einfluss der
	# Modifikatoren sichtbar machen kann. Nichts passiert ohne Feedback.
	_ressourcen.timeline_setzen(_timeline)
	_timeline.eintrag_neu.connect(_auf_timeline_eintrag)

func _bereit_domaenen_und_einheiten() -> void:
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
	# Moebel-Platzierer: Die Moebel-Domaene haengt ihre Platzierungen an
	# denselben Renderer-Nachzug wie die Gebaeude.
	_moebel_platzierer = Objekt_MoebelPlatzierer.new()
	_moebel_platzierer.einrichten(_model, _registry)
	_moebel_platzierer.moebel_platziert.connect(_auf_gebaeude_platziert)
	# Produktionszeile als Ereignis statt Frame-Abfrage: Der Manager meldet
	# jede Zustandsänderung selbst, das HUD liest nur die Meldung.
	_gebaeude.status_geaendert.connect(_auf_produktion_status)
	_rueckmeldung.produktion_anzeigen(_gebaeude.status_zeilen())
	# Einstiegs-Progression: Die Maschine ist die einzige Stufen-Wahrheit;
	# die Szene verdrahtet nur, Bauabschlüsse und Einwanderer melden sich
	# über die Manager, das HUD zeigt die aktuelle Zielzeile.
	var fortschritt_registry := Welt_FortschrittsRegistry.new()
	_fortschritt.registry_setzen(fortschritt_registry)
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
	# Ladeleiste der Chunk-Füllung: Eigene UI-Ebene, startet unsichtbar und
	# wird je Frame aus dem Lader-Fortschritt gespeist, bis er fertig ist.
	_lade_canvas = CanvasLayer.new()
	_lade_canvas.layer = 25
	add_child(_lade_canvas)
	_ui_aufbau.lade_leiste_bauen(_lade_canvas)

	# Orchestrator-Priority-Panel für Spieler-Steuerung
	_orchestrator_priority_panel = _OrchestratorPriorityPanelSkript.new()
	_orchestrator_priority_panel.name = "OrchestratorPriorityPanel"
	_orchestrator_priority_panel.einrichten(_orchestrator_manager, _auswahl)
	add_child(_orchestrator_priority_panel)

	# Verbinde Fortschritts-Maschine mit Orchestrator-Manager für Rathaus-Spawn
	_fortschritt.einheit_manager_setzen(_stockmaenner)
	_fortschritt.orchestrator_manager_setzen(_orchestrator_manager)

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

	# Erste Einheit erst mit dem ersten Lagerfeuer: Sie wandert am Anker
	# ein, sobald die Einstiegs-Kette das Lagerfeuer meldet. Vorher ist die
	# Karte leer und das Ziel sichtbar.
	_fortschritt.stufe_erreicht.connect(_auf_erste_einheit)
	# Ankunfts-Vertrag: Die Einwanderung setzt jeden Ankömmling genau dort
	# ab, wo der Spieler hinsieht. Ohne diesen Ruf landet niemand im Bild.
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
		"fortschritt": _fortschritt,
		"signal_bus": Kern_SignalBus.bus(),
		"orchestrator_panel": _orchestrator_priority_panel,
		"orchestrator_manager": _orchestrator_manager,
	})
	var zurueck_knopf: Button = %ZurueckKnopf
	zurueck_knopf.pressed.connect(_auf_zurueck)
	_pause_menue = Welt_PauseMenue.new()
	add_child(_pause_menue)
	_pause_menue.menue_gewuenscht.connect(_auf_zurueck)
	# Fenster-Panels: alle als modulare Control-Spitzen unter dem HUD-
	# CanvasLayer eingehängt; sie lesen nur über ihre Panel-Controller aus
	# den bestehenden Maschinen. Kein neuer Schnittpunkt, nur Sichtbarkeit.
	_ui_aufbau.debug_panel_bauen(%UILayer as CanvasLayer, _auswahl, _stockmaenner, _tiere)
	_ui_aufbau.bau_panel_bauen(%UILayer as CanvasLayer, _gebaeude_definitionen, _fortschritt, _steuerung, _auf_bau_gewaehlt, _registry)
	_ui_aufbau.pop_einheit_panel_bauen(%UILayer as CanvasLayer, _need_baum, _stockmaenner, _ressourcen)
	_eingabe_steuerung.debug_umgeschaltet.connect(_auf_debug_umgeschaltet)
	# Warum-Fenster: Die Status-Anzeige besitzt die Begründungsliste, die Szene
	# übergibt nur ihre drei Spitzen. Reine Verdrahtung, keine Timeline-Logik.
	_hud.warum_verdrahten(%WarumKnopf, %WarumFenster, %WarumText)

func _ladevorgang_ausfuehren() -> void:
	## Slice D: Kapselt den Ladevorgang aus welt_ladevorgang.gd und map_fabrik.gd.
	_ladevorgang.einrichten(_model, _generator)
	_map_fabrik.einrichten(_generator)
	# Faulbau scharf: Der Start-Frame baut keine tausend Kachel-Sprites;
	# der Lader erzeugt sie je Füllung, der Abschluss trägt den Endstand.
	_karte.sprites_faul_setzen(true)
	_ladevorgang.ausfuehren(WeltSitzung.welt_name, WeltSitzung.seed_wunsch, _model.biom_id)
	# Zeitgeslicene Füllung: Der Lader materialisiert Chunks im Budget;
	# die Szene speist ihn im _process, bis sein Signal kommt.
	_chunk_lader = _ladevorgang.lauf_lader
	if _chunk_lader != null:
		_chunk_lader.fertig.connect(_auf_welt_gefuellt)
		_chunk_lader.chunk_gefuellt.connect(_auf_chunk_gefuellt)
	else:
		# Save-Lauf ohne Generator: Der Vollbau in darstellen() ist die
		# Wahrheit, der Faulbau würde für immer leer bleiben.
		_karte.sprites_faul_setzen(false)

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
	_ui_aufbau.lager_darsteller_einrichten(_lager, _ressourcen)
	_tier_platzierer.platzieren(neues_modell, _registry, _tiere)
	# Wärme neu berechnen
	_waerme_sammler.sammeln(neues_modell, _stockmaenner, _waerme_overlay)
	# Domänen atomar umschalten
	_domaenen_modell_setzen(neues_modell)
	# Fraktions-KI auf neue Karte umstellen (Expansion)
	_fraktions_ki.modell_aktualisieren(neues_modell)
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
	_ui_aufbau.lager_darsteller_einrichten(_lager, _ressourcen)
	_waerme_sammler.sammeln(_model, _stockmaenner, _waerme_overlay)
	## Befund 6: Das Wegenetz kennt neue Gebäude erst nach diesem Aufruf.
	## Vorher liefen Einheiten planerisch durch jedes nach dem ersten Haus
	## errichtete Gebäude, weil das Netz beim initialen einrichten() eingefroren blieb.
	_stockmaenner.weg_planung_aktualisieren()
	if _landeplatz != null:
		_landeplatz.ausblenden()
		_landeplatz = null



func _process(delta: float) -> void:
	# Zeitgeslicene Welt-Füllung: Solange der Lader arbeitet, zieht er pro
	# Frame 16 ms Chunks nach, bevor der Rest des Frames läuft. Sichtbare
	# Chunks zuerst (Kartenmitte), der Rand folgt in den nächsten Frames.
	if _chunk_lader != null and _chunk_lader.laeuft:
		_chunk_lader.schritt()
		# Der letzte schritt() kann fertig emittieren und die Szene lässt den
		# Lader noch im selben Rahmen los; der Anteil wird nur gelesen, solange
		# die Referenz noch lebt.
		if _chunk_lader != null and _ui_aufbau.lade_leiste != null:
			_ui_aufbau.lade_leiste.anteil_setzen(_chunk_lader.fortschritt_anteil())
	_kamera_steuerung.kamera_bewegen(delta, _kamera)
	_tiere.spieler_position_setzen(_kamera.position)
	# Sprint 3: Die Kamerastelle führt die Tiefen-Neige mit; das Licht
	# selbst ist gerichtet und braucht keinen Ort.
	_atmosphaere.kamera_stelle(_kamera.position, _bereich)
	# RTS-Prinzip: Kamera und Einheiten sind entkoppelt. Stickmen bewegen
	# sich ausschließlich über Jobs (Einheit_Status + Rathaus/Orchestrator),
	# niemals durch unmittelbares Setzen ihrer Position pro Frame.
	_karten_beobachter.beobachten(_karten_viewer, _karten_info, _karten_ebene, _kamera_steuerung.kamera_position, _kamera)
	# Sichtbarkeits-Scheibe: Nur sichtbare Weltobjekte tragen Knoten; das
	# Modell bleibt die volle Wahrheit. Ohne Kamera bleibt der Bestand voll.
	if _kamera != null:
		var blick := _kamera.get_viewport_rect().size / _kamera.zoom.x
		var rand := _karte.sicht_rand_px()
		var blick_rechteck := Rect2(_kamera.position - blick * 0.5 - Vector2.ONE * rand, blick + Vector2.ONE * (rand * 2.0))
		_karte.sichtbereich_setzen(blick_rechteck)
		_tiere.sichtbereich_setzen(blick_rechteck)

func _auf_produktion_status(zeilen: Array[String]) -> void:
	# Reiner Weitergabe-Schritt: Die Zeilen kommen vom Gebaeude_Manager, die
	# Rückmelde-Spitze trägt sie ins HUD.
	_rueckmeldung.produktion_anzeigen(zeilen)

func _auf_bau_gewaehlt(gebaeude_id: String) -> void:
	_eingabe_steuerung.bau_auftrag_setzen(gebaeude_id)

func _auf_debug_umgeschaltet(sichtbar: bool) -> void:
	# Der Schalter aus dem Eingabe-Übersetzer ist die einzige Quelle der
	# Debug-Sichtbarkeit; das Fenster gehorcht. Der Parameter ist der
	# Vertrags-Signaturen-Wert des Signals und wird direkt durchgereicht.
	_ui_aufbau.debug_panel_sichtbar_setzen(sichtbar)

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
	## Frische Füllung sichtbar machen: Genau dieser Chunk kehrt mit neuen
	## Kachel-Bildern in die Karte zurück, der Rest der Ebene bleibt unberührt.
	## Ohne diesen Ruf bliebe die Karte weiß, weil der Renderer sie schon
	## vor der ersten Füllung aus dem leeren Modell gebaut hat.
	if _model == null:
		return
	_karte.kachel_erneuern_fuer_chunk(chunk, _model.aktive_z_ebene)

func _auf_welt_gefuellt() -> void:
	## Abschluss-Pass nach der letzten Chunk-Füllung: Gewaesser, Fels und
	## der Fraktions-Pass laufen danach; die Szene speist ihn nicht selbst,
	## sondern bittet den Generator. Die Karte folgt über den Kachel-Bus.
	if _chunk_lader == null:
		return
	_chunk_lader = null
	_generator.welt_abschliessen(_model, _model.welt_seed, _model.biom_id)
	# Der Abschluss-Pass schreibt Gewässer und Fels erst nach der Chunk-
	# Füllung; der Faulbau endet und trägt den vollen Stand in einem Rutsch.
	_karte.faulbau_abschliessen()
	# Die Leiste verabschiedet sich weich, statt mitten im Bild zu enden.
	if _ui_aufbau.lade_leiste != null:
		_ui_aufbau.lade_leiste.fertig_anzeigen()
	# Erst jetzt, mit voller Welt, geht der Stand auf die Platte; vorher
	# stünde eine leere Karte im Save.
	var world := WeltSitzung.world
	if world != null and WeltSitzung.aktive_map_id != "":
		Welt_Ladevorgang.welt_speichern_aktiv(world, WeltSitzung.aktive_map_id)
	# Der Objekt-Bestand ist vollständig: Gitter und Sicht-Scheibe neu.
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
	# Auch der Rückweg läuft über die Übergangs-Verbindung, damit jede
	# Szene denselben Weg nimmt und Events/Cutscenes dort andocken können.
	WeltSitzung.uebergang_ziel = "res://ui/scenes/hauptmenue.tscn"
	WeltSitzung.uebergang_text = "Zurück zum Hauptmenü …"
	get_tree().change_scene_to_file("res://ui/scenes/uebergang.tscn")

func _auf_gebaeude_meldung(meldung_text: String) -> void:
	_rueckmeldung.gebaeude_meldung_anzeigen(meldung_text)




func _auf_ziel_erreicht(stufe: Dictionary) -> void:
	_rueckmeldung.ziel_erreicht_anzeigen(stufe)

func _auf_erste_einheit(_stufe: Dictionary) -> void:
	# Die erste Einheit wandert mit dem Lagerfeuer ein: Vorher lebt die
	# Karte allein von ihrem Ziel, und die Einwanderung startet nicht doppelt.
	if _stockmaenner.einheit_zahl() > 0:
		return
	if _landeplatz != null:
		_landeplatz.ausblenden()
		_landeplatz = null
	_lager_fabrik.anlegen_aus_welt(_model, _lager, _kamera_steuerung.kamera_position)
	_waerme_sammler.sammeln(_model, _stockmaenner, _waerme_overlay)
	## Ankunftsort: Der erste Siedler erscheint dort, wo der Spieler
	## hinsieht. Ein Siedler im Modell, den niemand auf der Karte findet,
	## ist kein Fortschritt, sondern ein unsichtbarer Zustand.
	var ankunft := _ankunftsort()
	_stockmaenner.einheit_hinzufuegen(ankunft)
	_sozial.einheit_anmelden(_stockmaenner.einheit_zahl() - 1, ankunft, ["tratscht_gerne"])
	_hud.meldung_setzen("Der erste Siedler ist am Lagerfeuer angekommen.")

func _ankunftsort() -> Vector2:
	## Das Lagerfeuer dieser Stufe ist der Ankunftsort: Der Spieler hat es
	## gerade selbst gebaut und schaut hin. Stehen mehrere Feuer in der Welt,
	## zaehlt das naechste an der Kamera — ein weit entferntes Feuer wuerde
	## den Siedler ausserhalb des Bildes absetzen. Ohne Fundort bleibt der
	## Anker des Lagers, damit die Ankunft nie am Kartenursprung landet.
	## Massgeblich ist der Bildmittelpunkt, nie die Knoten-Position der
	## Kamera: Eine begrenzte Kamera zeigt nicht dorthin, wo ihr Knoten
	## rechnerisch steht, und ein Spawn am Knoten landet ausserhalb des
	## Sichtfelds.
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
	## Ohne Feuer zaehlt der Lageranker nur, wenn er im Blick liegt: Eine
	## Ankunft ausserhalb des Bildes ist keine Ankunft. Sonst kommt der
	## Siedler dort an, wo der Spieler hinsieht.
	var anker := _stockmaenner.lager_anker_position() + Vector2(0, 48)
	if _im_blick(anker):
		return anker
	return blick + Vector2(0, 48)

func _im_blick(welt_position: Vector2) -> bool:
	## Sichtfeld der Kamera in Weltkoordinaten: halbe Viewportgroesse je Zoom,
	## gerechnet ab dem gezeichneten Bildmittelpunkt. Der Knoten der Kamera
	## kann bei Karten-Grenzen von der gezeichneten Mitte abweichen; nur die
	## Mitte ist das, was ein Spieler wirklich sieht.
	var mitte := _kamera.get_screen_center_position()
	var halb := _kamera.get_viewport_rect().size * 0.5 / _kamera.zoom
	var abweichung := (welt_position - mitte).abs()
	return abweichung.x <= halb.x and abweichung.y <= halb.y

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
	if _ui_aufbau.bau_panel != null:
		_ui_aufbau.bau_panel.aktualisieren()

func _auf_timeline_eintrag(eintrag: Kern_TimelineEintrag) -> void:
	# Reine Beobachtung: Die Timeline meldet, die Rückmelde-Spitze zeigt.
	_rueckmeldung.timeline_anzeigen(eintrag.delta_text())
