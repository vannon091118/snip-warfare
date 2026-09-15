extends ConfirmationDialog
class_name Ui_GrundsatzFenster
## Grundsatz-Fenster: Ein kleiner Dialog, in dem der Spieler die Moral der
## Kolonie mit eigenen Händen stellt. Je Grundsatz steht ein Schalter mit
## Label und Tooltip; ein Klick meldet die Änderung über den Übersetzer an
## den Einheit_Manager, der sie an die Moral-Instanz der Verdrahtung reicht.
## Keine eigene Logik, kein Direktzugriff auf die Moral-Daten: nur Schalter
## und Meldung. Der Dialog pausiert nicht die Welt; die Kette lebt im Tick.
##
## Kette: Ui_GrundsatzPanel.eintraege_ermitteln -> CheckButtons -> toggled
## -> grundsatz_setzen -> Einheit_Manager.moral_grundsatz_setzen.

var _panel := Ui_GrundsatzPanel.new()
var _manager: Einheit_Manager = null
var _box: VBoxContainer = null
var _schalter_nach_id: Dictionary = {}
var _info: Label = null

## Kategorie logik: Einrichten, Aufbau, Zurückmelden.

func einrichten(manager: Einheit_Manager) -> void:
	_manager = manager

func _ready() -> void:
	title = "Grundsätze der Kolonie"
	ok_button_text = "Schließen"
	get_cancel_button().visible = false
	_box = VBoxContainer.new()
	_box.custom_minimum_size = Vector2(360, 0)
	_box.add_theme_constant_override("separation", 8)
	_info = Label.new()
	_info.text = "Die Grundsaetze steuern, welche Ziele die Kolonie in der Verzweiflung waehlt."
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_info)
	add_child(_box)
	about_to_popup.connect(_schalter_auffrischen)
	confirmed.connect(_auf_geschlossen)

func _schalter_auffrischen() -> void:
	# Jedes Öffnen liest den echten Stand; keine kopie hält den Dialog schlau.
	for kind in _box.get_children():
		if kind != _info:
			kind.queue_free()
	_schalter_nach_id.clear()
	for eintrag: Dictionary in _panel.eintraege_ermitteln(_manager):
		var schalter_id := str(eintrag.get("id", ""))
		var zeile := CheckButton.new()
		zeile.name = "Schalter_%s" % schalter_id
		zeile.text = str(eintrag.get("label", schalter_id))
		zeile.tooltip_text = str(eintrag.get("tooltip", ""))
		var erlaubt := bool(eintrag.get("erlaubt", false))
		zeile.button_pressed = erlaubt
		zeile.toggled.connect(func(neu_aktiv: bool) -> void: _auf_schalter(schalter_id, neu_aktiv))
		_box.add_child(zeile)
		_schalter_nach_id[schalter_id] = zeile

func _auf_schalter(schalter_id: String, erlaubt: bool) -> void:
	_panel.grundsatz_setzen(_manager, schalter_id, erlaubt)

func _auf_geschlossen() -> void:
	# Der Abschluss liest nichts nach; der Stand lebt in der Moral-Instanz.
	pass

