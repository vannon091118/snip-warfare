extends Node2D
## Prototyp-Karte: dünne Komponier-Spitze der RT-Pyramide. Sie besitzt keine
## eigene Logik: Sie lädt die Welt, verdrahtet die kleinen Spitzen (HUD-Observer,
## Selection, Kontext-Panel, Einheiten, Tiere) und übersetzt Eingaben in
## Aufrufe an die Untersysteme. Der Fluss läuft streng nach oben: Eingabe ->
## Maschinen -> Zustand -> Observer lesen und zeigen. Jede Kette ist über die
## eindeutigen Dateinamen zurückverfolgbar.

const STANDARD_WELT_PFAD := "res://world/data/standard_welt.json"
const KAMERA_ZOOM_SCHRITT := 1.1
const KAMERA_ZOOM_MIN := 0.2
const KAMERA_ZOOM_MAX := 2.5
const SCHNELLWAHL_MAX := 9
const ORCHESTRATOR_PFAD := "res://game/data/orchestrator_config.json"
const _AuswahlManagerSkript := preload("res://ui/scenes/selection/auswahl_manager.gd")

## Kategorie logik: Laden, Verdrahtung und Eingabe-Übersetzung der Spitzen.

## Kategorie daten: Modell, Registries und die komponierten Spitzen.
var _model := Welt_Model.new()
var _registry := Welt_Registry.new()
var _steuerung := Kern_SteuerungRegistry.new()
var _spieler_position := Vector2.ZERO
var _lager := Lager_Manager.new()
var _ressourcen := Einheit_Ressourcen.new()
var _job_registry := Job_Registry.new()
var _stockmaenner := Einheit_Manager.new()
var _tageszyklus := Welt_TageszyklusMaschine.new()
var _tages_overlay: CanvasLayer = null
var _auswahl := _AuswahlManagerSkript.new()
var _schnellwahl: Array[int] = []
var _job_kette: Array[Dictionary] = []
var _kette_laeuft: bool = false
var _orchestrator_registry := Orchestrator_Registry.new()
var _orchestrator_manager := Orchestrator_Manager.new()
var _orchestrator_darsteller: Array[Orchestrator_Darsteller] = []

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _spieler: Node2D = %Spieler
@onready var _tiere: Tier_Manager = %Tiere
@onready var _hud: VBoxContainer = %HUD
@onready var _rechteck: ColorRect = %AuswahlRechteck
@onready var _kontext: PopupMenu = %KontextMenue

func _ready() -> void:
	var geladen := false
	if WeltSitzung.welt_name != "":
		var speicher := Welt_Speicher.new()
		geladen = _model.aus_woerterbuch(speicher.laden(WeltSitzung.welt_name))
	if not geladen:
		geladen = _model.aus_woerterbuch(_standard_welt_laden())
	if not geladen:
		push_warning("Keine Welt ladbar, benutze leeres Raster")
	_tageszyklus.einrichten(6.0, 4.0, 2.0)
	_tages_overlay = preload("res://world/scenes/tageszyklus_overlay.gd").new()
	(_tages_overlay as CanvasLayer).layer = 20
	add_child(_tages_overlay)
	(_tages_overlay as Object).call("einrichten", _tageszyklus)
	_karte.darstellen(_model, _registry)
	_tiere_platzieren()
	_spieler_position = Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE / 2.0
	_spieler.position = _spieler_position
	_kamera.position = _spieler_position
	_lager_anlegen_aus_welt()
	_ressourcen.lager_setzen(_lager)
	_stockmaenner.einrichten(_model, _tiere, _ressourcen)
	_stockmaenner.lager_setzen(_lager)
	_stockmaenner.tageszyklus_setzen(_tageszyklus)
	_waerme_quellen_sammeln()
	add_child(_stockmaenner)
	_stockmaenner.einheit_hinzufuegen(_spieler_position)
	_orchestrator_registry.laden(ORCHESTRATOR_PFAD)
	_orchestrator_manager.referenzen_setzen(_stockmaenner, _model, _registry, _job_registry)
	add_child(_orchestrator_manager)
	_orchestratoren_verdrahten()
	_hud.einrichten(_ressourcen)
	_kontext.einrichten(_steuerung)
	_kontext.aktion_gewaehlt.connect(_auf_kontext_aktion)
	_hud.job_anzeigen("")
	_biom_anzeigen()
	var zurueck_knopf: Button = %ZurueckKnopf
	zurueck_knopf.pressed.connect(_auf_zurueck)

func _auf_verteilung(nahrung_je_takt: float) -> void:
	_stockmaenner.verteilung_setzen(nahrung_je_takt)
	_hud.meldung_setzen("Verteilung: %.1f Nahrung je Einheit je Takt" % nahrung_je_takt)

func _waerme_quellen_sammeln() -> void:
	var feuer: Array[Vector2] = []
	for index in _model.objekt_anzahl():
		if _model.objekt_element_id(index) == "lagerfeuer":
			feuer.append(_model.objekt_position(index))
	_stockmaenner.waerme_quellen_aktualisieren(feuer)

func _lager_anlegen_aus_welt() -> void:
	# Jedes Haus-Objekt in der Welt ist ein lokales Lager. Liegt keines da,
	# bekommt die Startposition ein kleines Lager, damit Arbeit nicht ins Leere faellt.
	for index in _model.objekt_anzahl():
		var element_id := _model.objekt_element_id(index)
		var welt_pos := _model.objekt_position(index)
		if element_id == "haus":
			_lager.lager_anlegen("kleines_lager", welt_pos)
		elif element_id == "haus_gross":
			_lager.lager_anlegen("grosses_lager", welt_pos)
	if _lager.lager_zahl() == 0:
		_lager.lager_anlegen("kleines_lager", _spieler_position)

func _tiere_platzieren() -> void:
	# Objekte mit Typ "bewegt" sind Tiere und werden dem Tier_Manager übergeben.
	for index in _model.objekt_anzahl():
		var element_id := _model.objekt_element_id(index)
		var eintrag := _registry.finde_objekt(element_id)
		if eintrag == null or eintrag.typ != &"bewegt":
			continue
		_tiere.tier_platzieren(element_id, _model.objekt_position(index))

func _standard_welt_laden() -> Dictionary:
	if not FileAccess.file_exists(STANDARD_WELT_PFAD):
		return {}
	var datei := FileAccess.open(STANDARD_WELT_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) == TYPE_DICTIONARY:
		return daten
	return {}

func _input(ereignis: InputEvent) -> void:
	if ereignis is InputEventKey and ereignis.pressed and ereignis.keycode == KEY_V and ereignis.ctrl_pressed:
		var dlg := preload("res://population/scenes/verteilung_dialog.gd").new()
		add_child(dlg)
		(dlg as Window).popup_centered()
		dlg.verteilung_gesetzt.connect(_auf_verteilung)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_kamera_bewegen(delta)
	_spieler.position = _spieler_position
	_kamera.position = _spieler_position
	_tiere.spieler_position_setzen(_spieler_position)
	_stockmaenner.einheit_position_setzen(_auswahl.aktiver_einheit_index, _spieler_position)

func _kamera_bewegen(delta: float) -> void:
	var richtung := _lese_kamera_richtung()
	var geschw := _steuerung.steuerung.kamera_geschwindigkeit if _steuerung.steuerung != null else 520.0
	_spieler_position += richtung * geschw * delta
	var karten_groesse := Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE
	_spieler_position = _spieler_position.clamp(Vector2.ZERO, karten_groesse)

func _unhandled_input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseButton and ereignis.pressed:
		match ereignis.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(1.0 / KAMERA_ZOOM_SCHRITT)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(KAMERA_ZOOM_SCHRITT)
			MOUSE_BUTTON_LEFT:
				_auswahl.einzel_start(_klick_position(ereignis))
			MOUSE_BUTTON_RIGHT:
				_rechtsklick_verarbeiten(_klick_position(ereignis))
	elif ereignis is InputEventMouseButton and not ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		_linksklick_ende(_klick_position(ereignis))
	elif ereignis is InputEventMouseMotion and _auswahl.ziehen_aktiv:
		_rechteck_pflegen()
	elif ereignis is InputEventKey and ereignis.pressed:
		_hotkey_verarbeiten(ereignis)
	elif ereignis.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://ui/scenes/hauptmenue.tscn")

func _klick_position(ereignis: InputEventMouseButton) -> Vector2:
	# Mausposition in Kartenkoordinaten umrechnen (Kamera und Zoom einbezogen).
	var karten_transform := _karte.get_global_transform_with_canvas().affine_inverse()
	return karten_transform * ereignis.position

func _linksklick_ende(ende: Vector2) -> void:
	_rechteck.rechteck_verbergen()
	var treffer: Array[int] = _auswahl.ziehen_ende(ende, _stockmaenner.einheit_zahl(), _stockmaenner.einheit_position)
	if treffer.is_empty():
		_klick_verarbeiten(ende)
	else:
		_hud.meldung_setzen("Massenwahl: %d Einheiten im Rechteck" % treffer.size())

func _rechtsklick_verarbeiten(welt_pos: Vector2) -> void:
	# Rechtsklick auf leerer Fläche ist Move der aktiven Einheit, mit Shift
	# ein aggressiver Move, der gegnerische Ziele automatisch angreift.
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung.steuerung != null else 60.0
	var ziel_objekt := _model.objekt_bei(welt_pos, radius)
	var ziel_tier := _tiere.tier_id_bei(welt_pos, radius)
	if ziel_objekt >= 0 or ziel_tier >= 0:
		_kontext.position = get_viewport().get_mouse_position()
		_kontext.popup()
		return
	if Input.is_key_pressed(KEY_SHIFT):
		_hud.meldung_setzen("Aggressiver Move: Ziel wird automatisch angegriffen")
	else:
		_hud.meldung_setzen("Move-Befehl an aktive Einheit")

func _hotkey_verarbeiten(ereignis: InputEventKey) -> void:
	# Strg+1..9 merkt die aktive Einheit als Schnellwahl, 1..9 wählt sie.
	if ereignis.keycode < KEY_1 or ereignis.keycode > KEY_9:
		return
	var slot := int(ereignis.keycode) - int(KEY_1)
	if slot >= SCHNELLWAHL_MAX:
		return
	if ereignis.ctrl_pressed:
		_schnellwahl[slot] = _auswahl.aktiver_einheit_index
		_hud.meldung_setzen("Schnellwahl %d gesetzt auf Einheit %d" % [slot + 1, _auswahl.aktiver_einheit_index])
	elif _schnellwahl.has(slot) and _schnellwahl[slot] < _stockmaenner.einheit_zahl():
		_auswahl.aktiver_einheit_index = _schnellwahl[slot]
		_hud.meldung_setzen("Einheit %d gewählt" % (_auswahl.aktiver_einheit_index + 1))

func _klick_verarbeiten(klick: Vector2) -> void:
	# Linksklick wählt: erst Tiere, dann Objekte. Mit Shift wird der Job an
	# die Kette gehängt, ohne den laufenden Job zu brechen.
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung.steuerung != null else 60.0
	var ketten_nachfrage := Input.is_key_pressed(KEY_SHIFT)
	var tier_nummer := _tiere.tier_id_bei(klick, radius)
	if tier_nummer >= 0:
		_job_vergeben_fuer_tier(tier_nummer, _tiere.tier_position(tier_nummer), ketten_nachfrage)
		return
	var objekt_index := _model.objekt_bei(klick, radius)
	if objekt_index >= 0:
		var element_id := _model.objekt_element_id(objekt_index)
		var eintrag := _registry.finde_objekt(element_id)
		if eintrag != null and eintrag.typ == &"objekt":
			_job_vergeben_fuer_objekt(objekt_index, _model.objekt_position(objekt_index), element_id, ketten_nachfrage)
			return
	if not ketten_nachfrage:
		_hud.meldung_setzen("Hier gibt es nichts zu tun")

func _job_vergeben_fuer_tier(tier_nummer: int, ziel_position: Vector2, kette: bool) -> void:
	var tier_art := _tiere.tier_art(tier_nummer)
	if tier_art == "":
		return
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung.steuerung != null else 60.0
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_tier(tier_art):
			continue
		if _spieler_position.distance_to(ziel_position) > probe.reichweite() + radius:
			_hud.meldung_setzen("Zu weit entfernt: erst hinbewegen")
			return
		if _stockmaenner.job_vergeben(_auswahl.aktiver_einheit_index, job_id, Job_Basis.ZielTyp.TIER, tier_nummer, ziel_position):
			_hud.job_anzeigen(_job_registry.job_name(job_id))
			return

func _job_vergeben_fuer_objekt(objekt_index: int, ziel_position: Vector2, element_id: String, kette: bool) -> void:
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung.steuerung != null else 60.0
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_objekt(element_id):
			continue
		if _spieler_position.distance_to(ziel_position) > probe.reichweite() + radius:
			_hud.meldung_setzen("Zu weit entfernt: erst hinbewegen")
			return
		if _stockmaenner.job_vergeben(_auswahl.aktiver_einheit_index, job_id, Job_Basis.ZielTyp.OBJEKT, objekt_index, ziel_position):
			_hud.job_anzeigen(_job_registry.job_name(job_id))
			return

func _lese_kamera_richtung() -> Vector2:
	if _steuerung.steuerung == null or _steuerung.steuerung.kamera_tasten.is_empty():
		return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var richtung := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		richtung.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		richtung.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		richtung.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		richtung.x += 1.0
	return richtung.normalized() if richtung.length() > 1.0 else richtung

func _rechteck_pflegen() -> void:
	if not _auswahl.ziehen_aktiv:
		return
	var maus: Vector2 = get_global_mouse_position()
	var start_bild: Vector2 = get_viewport().get_canvas_transform() * _auswahl.ziehen_start
	var end_bild: Vector2 = get_viewport().get_canvas_transform() * maus
	_rechteck.rechteck_setzen(start_bild, end_bild)

func _auf_kontext_aktion(aktion: Dictionary) -> void:
	# Das Panel meldet nur die Wahl; die Karte reicht sie an die Kette weiter.
	var logik := str(aktion.get("logik_id", ""))
	var label := str(aktion.get("label", ""))
	if label.to_lower().contains("wachstum") or logik.to_lower().contains("wachstum"):
		var haus_pos := _spieler_position
		if _lager.lager_zahl() > 0:
			haus_pos = _lager.lager_position(0)
		if _stockmaenner.versuche_wachstum(haus_pos):
			_hud.meldung_setzen("Wachstum: Neuer Stickman am Lager, 3 Nahrung verbraucht.")
		else:
			_hud.meldung_setzen("Wachstum braucht 3 Nahrung im naechsten Lager.")
		return
	_hud.meldung_setzen("Kontext: %s ueber Logik %s" % [label, logik])

func _biom_anzeigen() -> void:
	var zustand := _model.biom_zustand()
	_hud.biom_anzeigen(str(zustand.get("biom_id", _model.biom_id)), float(zustand.get("biom_faktor", 1.0)))

func _orchestratoren_verdrahten() -> void:
	for konfig in _orchestrator_registry.zonen:
		konfig.zustand = Orchestrator_Status.Zustand.AKTIV
		var idx := _orchestrator_manager.orchestrator_platzieren(konfig)
		var darsteller := Orchestrator_Darsteller.new()
		darsteller.einrichten(konfig)
		add_child(darsteller)
		_orchestrator_darsteller.append(darsteller)
		var status := _orchestrator_manager.status_fuer(idx)
		status.zustand_geaendert.connect(darsteller.status_geaendert)

func _zoom(faktor: float) -> void:
	var neuer_zoom: float = clampf(_kamera.zoom.x * faktor, KAMERA_ZOOM_MIN, KAMERA_ZOOM_MAX)
	_kamera.zoom = Vector2(neuer_zoom, neuer_zoom)

func _auf_zurueck() -> void:
	get_tree().change_scene_to_file("res://ui/scenes/hauptmenue.tscn")
