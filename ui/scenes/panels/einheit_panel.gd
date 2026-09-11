extends VBoxContainer
## VBox-Panel: sichtbares Einheitenfenster.
## Liest nur über Ui_EinheitPanel aus bestehenden Maschinen (Auswahl + Einheit_Manager).
## Keine eigene Logik, keine Maschine, nur Beobachter.

var _auswahl: Ui_AuswahlManager = null
var _einheiten: Einheit_Manager = null
var _panel := Ui_EinheitPanel.new()
var _label: Label = null

func einrichten(auswahl: Ui_AuswahlManager, einheiten: Einheit_Manager) -> void:
	_auswahl = auswahl
	_einheiten = einheiten

func _ready() -> void:
	_label = Label.new()
	add_child(_label)
	_label.text = "Einheitenfenster: bereit."

func _process(_delta: float) -> void:
	# Ein unsichtbarer Beobachter liest nichts: Das Debug-Fenster ist im
	# Normalbetrieb aus und soll dann auch keine Arbeit kosten.
	if not is_visible_in_tree():
		return
	if _label == null or _auswahl == null or _einheiten == null:
		return
	var zeilen := _panel.zeilen_fuer(_auswahl.aktiver_einheit_index, _einheiten)
	_label.text = "\n".join(zeilen)
