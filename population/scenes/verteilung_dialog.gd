extends Window
## Eigene Szene für die Verteilung der Nahrung.
## Strukturell getrennt vom Hauptfenster, blendet als Window über.
## Liest nur needs.json und schreibt nur über Pop-Verteilung.

signal verteilung_gesetzt(nahrung_je_einheit_je_takt: float)

var _label: Label = null
var _slider: HSlider = null
var _wert_label: Label = null

func _ready() -> void:
	title = "Verteilung"
	exclusive = true
	transient = true
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	var root := VBoxContainer.new()
	add_child(root)
	_label = Label.new()
	_label.text = "Nahrung je Stickman je 6-Minuten-Takt (Tag 4 / Nacht 2):"
	root.add_child(_label)
	var row := HBoxContainer.new()
	root.add_child(row)
	_slider = HSlider.new()
	_slider.min_value = 0.2
	_slider.max_value = 2.0
	_slider.step = 0.1
	_slider.value = 0.8
	_slider.custom_minimum_size = Vector2(220, 16)
	_slider.value_changed.connect(_auf_wert)
	row.add_child(_slider)
	_wert_label = Label.new()
	_wert_label.text = "0.8"
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
