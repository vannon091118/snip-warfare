extends Node2D
## Karten-Editor im Kreativmodus: eigene UI mit Kategorie-Seitenleiste.
## Assets werden per Drag & Drop aus der Seitenleiste auf die Karte gezogen,
## platzierte Objekte lassen sich erneut anfassen und verschieben.
## Die Werkzeug-Zustandsmaschine (Welt_EditorWerkzeug) trägt den Zustand;
## dieses Skript verbindet Eingabe, Modell und Renderer.

const STANDARD_WELT_PFAD := "res://world/data/standard_welt.json"
const VORSCHAU_GROESSE := 64.0
const KAMERA_GESCHWINDIGKEIT := 900.0
const KAMERA_ZOOM_MIN := 0.08
const KAMERA_ZOOM_MAX := 2.5

var _model := Welt_Model.new()
var _registry := Welt_Registry.new()
var _werkzeug := Welt_EditorWerkzeug.new()
var _vorschau: Sprite2D
var _maus_welt_position := Vector2.ZERO
var _zieht_aus_leiste := false

@onready var _karte: Welt_Renderer = %Karte
@onready var _kamera: Camera2D = %Kamera
@onready var _kategorien_leiste: VBoxContainer = %KategorienLeiste
@onready var _element_fluss: FlowContainer = %ElementFluss
@onready var _entfernen_knopf: Button = %EntfernenKnopf
@onready var _status_label: Label = %StatusLabel
@onready var _speichern_knopf: Button = %SpeichernKnopf
@onready var _dialog_speichern: ConfirmationDialog = %DialogSpeichern
@onready var _namen_feld: LineEdit = %NamenFeld

func _ready() -> void:
	# Kamera-Aktionen aus steuerung.json in die InputMap schreiben; der
	# Editor kennt keine Taste im Code und läuft über dieselben Aktionen
	# wie die Spielkamera (WASD plus Pfeil-Rückfall der ui_-Aktionen).
	var steuerung := Kern_SteuerungRegistry.new()
	steuerung.inputmap_registrieren()
	_welt_laden()
	_karte.darstellen(_model, _registry)
	_vorschau = Sprite2D.new()
	_vorschau.modulate = Color(1, 1, 1, 0.55)
	_vorschau.visible = false
	_karte.add_child(_vorschau)
	_seitenleiste_erzeugen()
	_entfernen_knopf.pressed.connect(_auf_entfernen)
	_speichern_knopf.pressed.connect(_auf_speichern)
	_dialog_speichern.confirmed.connect(_auf_gespeichert)
	_namen_feld.text = WeltSitzung.welt_name
	_status_aktualisieren()

func _welt_laden() -> void:
	var geladen := false
	if WeltSitzung.welt_name != "":
		var speicher := Welt_Speicher.new()
		geladen = _model.aus_woerterbuch(speicher.laden(WeltSitzung.welt_name))
	if not geladen:
		geladen = _model.aus_woerterbuch(_standard_welt_laden())
	if not geladen:
		# Kartengröße kommt aus der zentralen Weltdefinition, nie aus Code-Konstanten.
		var def_reg := Welt_DefinitionRegistry.new()
		def_reg.laden()
		var max_groesse := def_reg.max_karten_groesse()
		_model.karte_erzeugen(max_groesse.x, max_groesse.y, "boden")
	_kamera.position = Vector2(_model.groesse()) * float(_model.kachel_groesse) / 2.0

func _standard_welt_laden() -> Dictionary:
	if not FileAccess.file_exists(STANDARD_WELT_PFAD):
		return {}
	var datei := FileAccess.open(STANDARD_WELT_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) == TYPE_DICTIONARY:
		return daten
	return {}

func _seitenleiste_erzeugen() -> void:
	for kategorie in _registry.kategorien():
		var ueberschrift := Label.new()
		ueberschrift.text = kategorie
		# Godot 4 kennt keinen setzbaren Dictionary-Eintrag für Schriftgrößen;
		# der Override wird über die öffentliche Theme-API gesetzt.
		ueberschrift.add_theme_font_size_override("font_size", 22)
		_kategorien_leiste.add_child(ueberschrift)
		for objekt: Objekt_Basis in _registry.objekte_der_kategorie(kategorie):
			_element_fluss.add_child(_element_knopf(objekt))

func _element_knopf(objekt: Objekt_Basis) -> Button:
	var knopf := Button.new()
	knopf.custom_minimum_size = Vector2(VORSCHAU_GROESSE + 24, VORSCHAU_GROESSE + 24)
	knopf.tooltip_text = objekt.angezeigter_name
	knopf.focus_mode = Control.FOCUS_NONE
	var bild := TextureRect.new()
	bild.texture = load(objekt.textur_pfad) if ResourceLoader.exists(objekt.textur_pfad) else null
	bild.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bild.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bild.set_anchors_preset(Control.PRESET_FULL_RECT)
	bild.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knopf.add_child(bild)
	knopf.gui_input.connect(_auf_leisten_input.bind(objekt.id))
	return knopf

func _auf_leisten_input(ereignis: InputEvent, element_id: String) -> void:
	if ereignis is InputEventMouseButton and ereignis.button_index == MOUSE_BUTTON_LEFT and ereignis.pressed:
		# Drag & Drop aus der Seitenleiste beginnen; das Loslassen fängt _input ab.
		_zieht_aus_leiste = true
		_werkzeug.waehle_element(element_id)
		_vorschau.texture = _textur_fuer(element_id)
		_maus_welt_position = get_global_mouse_position()
		_vorschau.position = _maus_welt_position
		_vorschau.visible = false
		_status_aktualisieren()
		get_viewport().set_input_as_handled()

func _input(ereignis: InputEvent) -> void:
	# Lebenszyklus des Leisten-Zugs: Bewegung und Loslassen, auch über UI-Flächen.
	if not _zieht_aus_leiste:
		return
	if ereignis is InputEventMouseMotion:
		_maus_welt_position = get_global_mouse_position()
		_vorschau.position = _maus_welt_position
		_vorschau.visible = _maus_welt_position_in_karte()
	elif ereignis is InputEventMouseButton and ereignis.button_index == MOUSE_BUTTON_LEFT and not ereignis.pressed:
		_maus_welt_position = get_global_mouse_position()
		if _maus_welt_position_in_karte():
			_objekt_platzieren(_maus_welt_position)
		_vorschau.visible = false
		_zieht_aus_leiste = false
		_status_aktualisieren()
		get_viewport().set_input_as_handled()

func _textur_fuer(element_id: String) -> Texture2D:
	var objekt := _registry.finde_objekt(element_id)
	if objekt == null:
		return null
	if not ResourceLoader.exists(objekt.textur_pfad):
		return null
	return load(objekt.textur_pfad)

func _status_aktualisieren() -> void:
	var werkzeug_name := "Platzieren"
	if _werkzeug.aktives_werkzeug == Welt_EditorWerkzeug.Werkzeug.ENTFERNEN:
		werkzeug_name = "Entfernen"
	elif _werkzeug.zieht_gerade() or _zieht_aus_leiste:
		werkzeug_name = "Verschieben"
	_status_label.text = "Kreativmodus | Werkzeug: %s | %d Objekte | %dx%d Kacheln" % [
		werkzeug_name,
		_model.objekt_anzahl(),
		_model.raster_breite,
		_model.raster_hoehe,
	]

func _unhandled_input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion:
		_maus_welt_position = get_global_mouse_position()
		if _werkzeug.zieht_gerade():
			_vorschau.position = _maus_welt_position
			_vorschau.visible = true
	elif ereignis is InputEventMouseButton:
		if ereignis.button_index == MOUSE_BUTTON_LEFT:
			if ereignis.pressed:
				_maus_gedrueckt()
			else:
				_maus_losgelassen()
		elif ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0 / 1.1)
		elif ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.1)
	elif ereignis.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://ui/scenes/hauptmenue.tscn")

func _maus_gedrueckt() -> void:
	# Erst prüfen, ob ein platziertes Objekt unter dem Zeiger liegt: dann greifen.
	var objekt_index := _model.objekt_bei(_maus_welt_position, 60.0)
	if objekt_index >= 0 and _werkzeug.aktives_werkzeug != Welt_EditorWerkzeug.Werkzeug.ENTFERNEN:
		_werkzeug.objekt_greifen(objekt_index)
		_vorschau.texture = _textur_fuer(_model.objekt_element_id(objekt_index))
		_vorschau.position = _maus_welt_position
		_vorschau.visible = true
		_status_aktualisieren()
		return
	match _werkzeug.aktives_werkzeug:
		Welt_EditorWerkzeug.Werkzeug.PLATZIEREN:
			_objekt_platzieren(_maus_welt_position)
		Welt_EditorWerkzeug.Werkzeug.ENTFERNEN:
			_objekt_entfernen(_maus_welt_position)

func _maus_losgelassen() -> void:
	if not _werkzeug.zieht_gerade():
		return
	var index := _werkzeug.gezogenes_objekt
	if index >= 0 and index < _model.objekt_anzahl() and _maus_welt_position_in_karte():
		# Abgelegt: neue Position ins Modell und in den Renderer-Knoten schreiben.
		_model.objekt_verschieben(index, _maus_welt_position)
		_karte.objekt_knoten_verschieben(index, _maus_welt_position)
	_werkzeug.objekt_ablegen()
	_vorschau.visible = false
	_status_aktualisieren()

func _maus_welt_position_in_karte() -> bool:
	var karten_groesse := Vector2(_model.groesse()) * float(_model.kachel_groesse)
	return _maus_welt_position.x >= 0.0 and _maus_welt_position.y >= 0.0 \
		and _maus_welt_position.x < karten_groesse.x and _maus_welt_position.y < karten_groesse.y

func _objekt_platzieren(ziel: Vector2) -> void:
	_model.objekt_hinzufuegen(_werkzeug.gewaehltes_element, ziel)
	_karte.objekt_knoten_anhaengen(_model.objekt_anzahl() - 1)
	_status_aktualisieren()

func _objekt_entfernen(ziel: Vector2) -> void:
	var objekt_index := _model.objekt_bei(ziel, 60.0)
	if objekt_index >= 0:
		_model.objekt_entfernen(objekt_index)
		_karte.objekt_knoten_entfernen(objekt_index)
		_status_aktualisieren()

func _auf_entfernen() -> void:
	_werkzeug.waehle_werkzeug(Welt_EditorWerkzeug.Werkzeug.ENTFERNEN)
	_vorschau.visible = false
	_status_aktualisieren()

func _auf_speichern() -> void:
	_namen_feld.text = WeltSitzung.welt_name
	_dialog_speichern.popup_centered()

func _auf_gespeichert() -> void:
	var neuer_name := _namen_feld.text.strip_edges()
	if neuer_name == "":
		return
	WeltSitzung.welt_name = neuer_name
	var speicher := Welt_Speicher.new()
	if speicher.speichern(neuer_name, _model.nach_woerterbuch()):
		_status_aktualisieren()

func _process(delta: float) -> void:
	# Richtungen kommen aus der InputMap der Steuerungskonfiguration; ohne
	# registrierte Aktionen gilt der ui_-Rückfall der Engine.
	var richtung := Vector2.ZERO
	if InputMap.has_action(Kern_SteuerungBasis.AKTION_HOCH):
		richtung = Input.get_vector(Kern_SteuerungBasis.AKTION_LINKS, Kern_SteuerungBasis.AKTION_RECHTS, Kern_SteuerungBasis.AKTION_HOCH, Kern_SteuerungBasis.AKTION_RUNTER)
	else:
		richtung = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_kamera.position += richtung * KAMERA_GESCHWINDIGKEIT * delta / maxf(_kamera.zoom.x, 0.2)

func _zoom(faktor: float) -> void:
	var neuer_zoom: float = clampf(_kamera.zoom.x * faktor, KAMERA_ZOOM_MIN, KAMERA_ZOOM_MAX)
	_kamera.zoom = Vector2(neuer_zoom, neuer_zoom)
