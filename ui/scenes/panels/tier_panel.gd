extends VBoxContainer
## VBox-Panel: sichtbares Tier-/Monsterfenster.
## Liest nur über Ui_TierPanel aus dem bestehenden Tier_Manager.
## Keine eigene Logik, keine Maschine, nur Beobachter.

var _tiere: Tier_Manager = null
var _panel := Ui_TierPanel.new()
var _label: Label = null

func einrichten(tiere: Tier_Manager) -> void:
	_tiere = tiere

func _ready() -> void:
	_label = Label.new()
	add_child(_label)
	_label.text = "Tierfenster: bereit."

func _process(_delta: float) -> void:
	if _label == null or _tiere == null:
		return
	var zeilen := _panel.zeilen_fuer(_tiere)
	_label.text = "\n".join(zeilen)
