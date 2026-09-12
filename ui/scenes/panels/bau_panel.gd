extends PanelContainer
class_name Ui_BauPanelSzene
## Bau-Panel: Horizontale Leiste am unteren Bildschirmrand zur Gebäudeauswahl.
## Liest über Ui_BauPanel Daten aus Gebaeude_DefinitionRegistry und Fortschritt.
## Reagiert auf Klicks und emittiert bau_gewaehlt(gebaeude_id).
## Keine Spiellogik: reine Visualisierung und Eingabeerfassung.

signal bau_gewaehlt(gebaeude_id: String)

var _panel_logik := Ui_BauPanel.new()
var _definitionen: Gebaeude_DefinitionRegistry = null
var _fortschritt: Welt_FortschrittsMaschine = null
var _steuerung: Kern_SteuerungRegistry = null

@onready var _button_container: HBoxContainer = %ButtonContainer

func einrichten(definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine, steuerung: Kern_SteuerungRegistry) -> void:
	_definitionen = definitionen
	_fortschritt = fortschritt
	_steuerung = steuerung
	aktualisieren()

func _ready() -> void:
	if _definitionen == null:
		_definitionen = Gebaeude_DefinitionRegistry.new()
	if _button_container != null and _button_container.get_child_count() == 0:
		aktualisieren()

func aktualisieren() -> void:
	if _button_container == null:
		return
	for kind in _button_container.get_children():
		kind.queue_free()

	var eintraege := _panel_logik.eintraege_ermitteln(_definitionen, _fortschritt, _steuerung)
	for eintrag: Dictionary in eintraege:
		var btn := Button.new()
		var geb_id := str(eintrag.get("id", ""))
		var gesperrt := bool(eintrag.get("gesperrt", false))
		var label_text := str(eintrag.get("name", geb_id))
		var kosten_text := str(eintrag.get("kosten_text", ""))

		btn.text = "%s\n(%s)" % [label_text, kosten_text]
		btn.tooltip_text = str(eintrag.get("tooltip", ""))
		btn.disabled = gesperrt
		btn.custom_minimum_size = Vector2(130, 52)

		var icon_pfad := str(eintrag.get("icon_pfad", ""))
		if icon_pfad != "" and ResourceLoader.exists(icon_pfad):
			btn.icon = load(icon_pfad)
			btn.expand_icon = true

		btn.pressed.connect(func() -> void:
			bau_gewaehlt.emit(geb_id)
		)
		_button_container.add_child(btn)
