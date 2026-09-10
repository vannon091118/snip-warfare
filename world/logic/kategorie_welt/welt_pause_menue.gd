extends CanvasLayer
class_name Welt_PauseMenue
## Observer- und Menue-Spitze: ESC pausiert die Welt, Speichern delegiert an
## Welt_Ladevorgang (einzige Speicher-Zustaendigkeit), Hauptmenue laeuft
## ueber die bestehende Uebergangs-Bruecke. Eigene Zeit oder Logik besitzt
## diese Schicht nicht; sie pausiert nur den Baum und meldet Feedback.

signal menue_gewuenscht

var _offen: bool = false
var _panel: Control = null
var _info: Label = null

func _ready() -> void:
	layer = 30
	_panel = _panel_bauen()
	# Generischer UI-Name: externe Beobachter (E2E, WarFenster) erkennen das
	# Pause-UI ueber diesen Zwecknamen, nicht ueber die Klassenzugehoerigkeit.
	_panel.name = "PauseMenu"
	_panel.visible = false
	_sichtbar_setzen(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			_toggle()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	if _offen:
		schliessen()
	else:
		oeffnen()

func oeffnen() -> void:
	if _offen:
		return
	_offen = true
	get_tree().paused = true
	_sichtbar_setzen(true)

func schliessen() -> void:
	if not _offen:
		return
	_offen = false
	get_tree().paused = false
	_sichtbar_setzen(false)
	if _info != null:
		_info.text = ""

func _sichtbar_setzen(sichtbar: bool) -> void:
	if _panel != null:
		_panel.visible = sichtbar
	process_mode = Node.PROCESS_MODE_ALWAYS

func _panel_bauen() -> Control:
	var hintergrund := ColorRect.new()
	hintergrund.name = "PauseHintergrund"
	hintergrund.color = Color(0.02, 0.03, 0.05, 0.72)
	hintergrund.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hintergrund)

	var zentrum := CenterContainer.new()
	zentrum.name = "PauseZentrum"
	zentrum.set_anchors_preset(Control.PRESET_FULL_RECT)
	hintergrund.add_child(zentrum)

	var box := VBoxContainer.new()
	box.name = "PauseBox"
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 12)
	zentrum.add_child(box)

	var titel := Label.new()
	titel.name = "PauseTitel"
	titel.text = "Pause"
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(titel)

	_info = Label.new()
	_info.name = "PauseInfo"
	_info.text = ""
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_info)

	var weiter := Button.new()
	weiter.name = "WeiterKnopf"
	weiter.text = "Weiter"
	weiter.pressed.connect(schliessen)
	box.add_child(weiter)

	var speichern := Button.new()
	speichern.name = "SpeichernKnopf"
	speichern.text = "Speichern"
	speichern.pressed.connect(_auf_speichern)
	box.add_child(speichern)

	var hauptmenue := Button.new()
	hauptmenue.name = "HauptmenueKnopf"
	hauptmenue.text = "Hauptmenü"
	hauptmenue.pressed.connect(_auf_hauptmenue)
	box.add_child(hauptmenue)
	return hintergrund

func _auf_speichern() -> void:
	var meldung := "Speichern fehlgeschlagen."
	var world: Welt_World = WeltSitzung.world
	var map_id := WeltSitzung.aktive_map_id
	if world != null and map_id != "":
		var aktive: Welt_Model = world.map_model(map_id)
		if aktive != null:
			aktive.aus_welt_uebernehmen(_model_vom_baum())
			if Welt_Ladevorgang.welt_speichern_aktiv(world, map_id):
				meldung = "Gespeichert."
	if _info != null:
		_info.text = meldung

func _model_vom_baum() -> Welt_Model:
	var eltern := get_parent()
	if eltern != null and "model_liefern" in eltern:
		return eltern.model_liefern()
	return null

func _auf_hauptmenue() -> void:
	get_tree().paused = false
	menue_gewuenscht.emit()
