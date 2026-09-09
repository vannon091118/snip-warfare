extends Node2D
## Prototyp-Karte: zeigt eine Welt aus dem Speicher oder die Standardwelt.
## Der Spieler bewegt seine Einheit per WASD/Pfeiltasten; die Einheit bewegt
## sich niemals selbst. Jobs werden per Klick auf das Job-Objekt vergeben
## (Baum = Holzfäller, Stein = Steinmetz, Tier = Jäger); Rechtsklick bricht ab.
## Diese Szene enthält nur Darstellung und Eingabe; die Job-Logik liegt in der
## Game-Domäne, die Tier-Logik in der Welt-Domäne.

const STANDARD_WELT_PFAD := "res://world/data/standard_welt.json"
const SPIELER_GESCHWINDIGKEIT := 520.0
const KAMERA_ZOOM_SCHRITT := 1.1
const KAMERA_ZOOM_MIN := 0.2
const KAMERA_ZOOM_MAX := 2.5
const AUSWAHL_RADIUS := 60.0

var _model := Welt_Model.new()
var _registry := Welt_Registry.new()
var _spieler_position := Vector2.ZERO
var _ressourcen := Einheit_Ressourcen.new()
var _job_registry := Job_Registry.new()
var _stockmaenner := Einheit_Manager.new()
var _aktiver_einheit_index := 0
var _ressourcen_labels: Dictionary = {}

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _spieler: Node2D = %Spieler
@onready var _tiere: Tier_Manager = %Tiere
@onready var _job_label: Label = %JobLabel
@onready var _status_label: Label = %StatusLabel

func _ready() -> void:
	var geladen := false
	if WeltSitzung.welt_name != "":
		var speicher := Welt_Speicher.new()
		geladen = _model.aus_woerterbuch(speicher.laden(WeltSitzung.welt_name))
	if not geladen:
		geladen = _model.aus_woerterbuch(_standard_welt_laden())
	if not geladen:
		push_warning("Keine Welt ladbar, benutze leeres Raster")
	_karte.darstellen(_model, _registry)
	_tiere_platzieren()
	_spieler_position = Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE / 2.0
	_spieler.position = _spieler_position
	_kamera.position = _spieler_position
	_stockmaenner.einrichten(_model, _tiere, _ressourcen)
	add_child(_stockmaenner)
	_stockmaenner.einheit_hinzufuegen(_spieler_position)
	_hud_aufbauen()
	_hud_aktualisieren()
	var zurueck_knopf: Button = %ZurueckKnopf
	zurueck_knopf.pressed.connect(_auf_zurueck)

func _tiere_platzieren() -> void:
	# Objekte mit Typ "bewegt" sind Tiere und werden dem Tier_Manager übergeben.
	for objekt: Dictionary in _model.objekte:
		var eintrag := _registry.finde_objekt(str(objekt["element_id"]))
		if eintrag == null or eintrag.typ != &"bewegt":
			continue
		var position_werte: Array = objekt["position"]
		_tiere.tier_platzieren(str(objekt["element_id"]), Vector2(position_werte[0], position_werte[1]))

func _standard_welt_laden() -> Dictionary:
	if not FileAccess.file_exists(STANDARD_WELT_PFAD):
		return {}
	var datei := FileAccess.open(STANDARD_WELT_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) == TYPE_DICTIONARY:
		return daten
	return {}

func _process(delta: float) -> void:
	var richtung := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_spieler_position += richtung * SPIELER_GESCHWINDIGKEIT * delta
	var karten_groesse := Vector2(_model.groesse()) * Welt_Model.KACHEL_GROESSE
	_spieler_position = _spieler_position.clamp(Vector2.ZERO, karten_groesse)
	_spieler.position = _spieler_position
	_kamera.position = _spieler_position
	_tiere.spieler_position_setzen(_spieler_position)
	_stockmaenner.einheit_position_setzen(_aktiver_einheit_index, _spieler_position)

func _unhandled_input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseButton and ereignis.pressed:
		if ereignis.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0 / KAMERA_ZOOM_SCHRITT)
		elif ereignis.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(KAMERA_ZOOM_SCHRITT)
		elif ereignis.button_index == MOUSE_BUTTON_LEFT:
			_klick_verarbeiten(_klick_position(ereignis))
		elif ereignis.button_index == MOUSE_BUTTON_RIGHT:
			_job_abbrechen()
	elif ereignis.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://ui/scenes/hauptmenue.tscn")

func _klick_position(ereignis: InputEventMouseButton) -> Vector2:
	# Mausposition in Kartenkoordinaten umrechnen (Kamera und Zoom einbezogen).
	var transform := _karte.get_global_transform_with_canvas().affine_inverse()
	return transform * ereignis.position

func _klick_verarbeiten(klick: Vector2) -> void:
	# 1. Tier getroffen? Dann kommt der Jäger-Job in Frage.
	var tier_nummer := _tiere.tier_id_bei(klick, AUSWAHL_RADIUS)
	if tier_nummer >= 0:
		var ziel_position := _tiere.tier_position(tier_nummer)
		_job_vergeben_fuer_tier(tier_nummer, ziel_position)
		return
	# 2. Weltobjekt getroffen? (Baum und Steine sind die Job-Objekte.)
	var objekt_index := _model.objekt_bei(klick, AUSWAHL_RADIUS)
	if objekt_index >= 0:
		var element_id := str(_model.objekte[objekt_index]["element_id"])
		var eintrag := _registry.finde_objekt(element_id)
		if eintrag != null and eintrag.typ == &"objekt":
			var ziel_position := _model.objekt_position(objekt_index)
			_job_vergeben_fuer_objekt(objekt_index, ziel_position, element_id)

func _job_vergeben_fuer_tier(tier_nummer: int, ziel_position: Vector2) -> void:
	var tier_art := _tiere.tier_art(tier_nummer)
	if tier_art == "":
		return
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_tier(tier_art):
			continue
		if _spieler_position.distance_to(ziel_position) > probe.reichweite() + AUSWAHL_RADIUS:
			_status_label.text = "Zu weit entfernt: erst hinbewegen"
			return
		if _stockmaenner.job_vergeben(_aktiver_einheit_index, job_id, Job_Basis.ZielTyp.TIER, tier_nummer, ziel_position):
			_status_label.text = "Job: %s" % _job_registry.job_name(job_id)
			_hud_aktualisieren()
			return
	_status_label.text = "Hier gibt es nichts zu tun"

func _job_vergeben_fuer_objekt(objekt_index: int, ziel_position: Vector2, element_id: String) -> void:
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_objekt(element_id):
			continue
		if _spieler_position.distance_to(ziel_position) > probe.reichweite() + AUSWAHL_RADIUS:
			_status_label.text = "Zu weit entfernt: erst hinbewegen"
			return
		if _stockmaenner.job_vergeben(_aktiver_einheit_index, job_id, Job_Basis.ZielTyp.OBJEKT, objekt_index, ziel_position):
			_status_label.text = "Job: %s" % _job_registry.job_name(job_id)
			_hud_aktualisieren()
			return
	_status_label.text = "Hier gibt es nichts zu tun"

func _job_abbrechen() -> void:
	if _stockmaenner.job_id_einheit(_aktiver_einheit_index) == "":
		return
	_stockmaenner.einheit_job_abbrechen(_aktiver_einheit_index)
	_status_label.text = "Job abgebrochen"
	_hud_aktualisieren()

func _zoom(faktor: float) -> void:
	var neuer_zoom: float = clampf(_kamera.zoom.x * faktor, KAMERA_ZOOM_MIN, KAMERA_ZOOM_MAX)
	_kamera.zoom = Vector2(neuer_zoom, neuer_zoom)

func _hud_aufbauen() -> void:
	# Ressourcenleiste: ein Icon mit Zähler pro Ressource aus der zentralen Config.
	var reihe: HBoxContainer = %RessourcenReihe
	for ressource: String in _ressourcen.ressource_ids():
		var feld := HBoxContainer.new()
		var icon := TextureRect.new()
		var pfad := _ressourcen.icon_pfad(ressource)
		if pfad != "" and ResourceLoader.exists(pfad):
			icon.texture = load(pfad)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var zaehler := Label.new()
		zaehler.text = "0"
		feld.add_child(icon)
		feld.add_child(zaehler)
		reihe.add_child(feld)
		_ressourcen_labels[ressource] = zaehler
	_ressourcen.bestand_geaendert.connect(_auf_bestand)

func _auf_bestand(ressource: String, neuer_bestand: int) -> void:
	if _ressourcen_labels.has(ressource):
		(_ressourcen_labels[ressource] as Label).text = str(neuer_bestand)

func _hud_aktualisieren() -> void:
	var job_id := _stockmaenner.job_id_einheit(_aktiver_einheit_index)
	if job_id == "":
		_job_label.text = "Job: keiner (Objekt anklicken)"
	else:
		_job_label.text = "Job: %s" % _job_registry.job_name(job_id)

func _auf_zurueck() -> void:
	get_tree().change_scene_to_file("res://ui/scenes/hauptmenue.tscn")
