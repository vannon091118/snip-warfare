extends Window
## Eigene Szene für die Verteilung der Nahrung.
## Strukturell getrennt vom Hauptfenster, blendet als Window über.
## Sie führt keine eigenen Zahlen: Startwert und Taktangabe kommen aus dem
## Datenpool, der Aufrufer reicht sie beim Öffnen herein.

signal verteilung_gesetzt(nahrung_je_einheit_je_takt: float)

## Rückfallwerte nur für den Fall, dass niemand Werte übergibt.
const TAKT_RUECKFALL := 6.0
const TAG_RUECKFALL := 4.0
const NACHT_RUECKFALL := 2.0
const WERT_RUECKFALL := 0.8

var _label: Label = null
var _slider: HSlider = null
var _wert_label: Label = null
var _takt_minuten: float = TAKT_RUECKFALL
var _tag_minuten: float = TAG_RUECKFALL
var _nacht_minuten: float = NACHT_RUECKFALL
var _startwert: float = WERT_RUECKFALL

## Öffnungs-Werte aus dem Datenpool; vor dem Popup aufrufen.
func werte_setzen(takt_minuten: float, tag_minuten: float, nacht_minuten: float, verbrauch_je_takt: float) -> void:
	_takt_minuten = takt_minuten
	_tag_minuten = tag_minuten
	_nacht_minuten = nacht_minuten
	_startwert = verbrauch_je_takt

func _ready() -> void:
	title = "Verteilung"
	exclusive = true
	transient = true
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	var root := VBoxContainer.new()
	add_child(root)
	_label = Label.new()
	_label.text = "Nahrung je Stickman je %d-Minuten-Takt (Tag %d / Nacht %d):" % [
		int(round(_takt_minuten)), int(round(_tag_minuten)), int(round(_nacht_minuten))]
	root.add_child(_label)
	var row := HBoxContainer.new()
	root.add_child(row)
	_slider = HSlider.new()
	_slider.min_value = 0.2
	_slider.max_value = 2.0
	_slider.step = 0.1
	_slider.value = _startwert
	_slider.custom_minimum_size = Vector2(220, 16)
	_slider.value_changed.connect(_auf_wert)
	row.add_child(_slider)
	_wert_label = Label.new()
	_wert_label.text = "%.1f" % _startwert
	row.add_child(_wert_label)
	var ok := Button.new()
	ok.text = "Übernehmen"
	ok.pressed.connect(_auf_ok)
	root.add_child(ok)
	close_requested.connect(queue_free)

func _auf_wert(wert: float) -> void:
	_wert_label.text = "%.1f" % wert

func _auf_ok() -> void:
	verteilung_gesetzt.emit(float(_slider.value))
	queue_free()
