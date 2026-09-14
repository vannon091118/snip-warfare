extends PanelContainer
class_name Ui_FensterLeiste
## Zentrale Fenster-Leiste: Bündelt alle UI-Fenster in einer einzigen, sortierten Leiste.
## Sie zeigt für jedes Fenster einen Button (Bau, Karte, Debug, Warum, Hauptmenü)
## und sortiert sie alphabetisch. Ein Klick ruft die bestehende Maschine auf,
## kein Fenster kennt die Leiste, nur die Leiste kennt die Callables.

## Kategorie daten: Sortierte Einträge und Button-Zuordnung als reine Datenhaltung.
var _eintraege: Array[Dictionary] = []
var _knopf_nach_id: Dictionary = {}
var _reihe: HBoxContainer = null

## Kategorie logik: Aufbau, sortierte Darstellung (A-Z), Toggle-Vermittlung.

func _init() -> void:
	_reihe = HBoxContainer.new()
	_reihe.name = "Reihe"
	_reihe.alignment = BoxContainer.ALIGNMENT_CENTER
	_reihe.add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(0, 36)
	add_theme_stylebox_override("panel", _standard_panel())

func _ready() -> void:
	if _reihe.get_parent() == null:
		add_child(_reihe)
	if _eintraege.is_empty() and _reihe.get_child_count() == 0:
		visible = false

func einrichten(eintraege: Array[Dictionary]) -> void:
	_eintraege = eintraege.duplicate(true)
	_eintraege.sort_custom(_nach_name)
	if not is_inside_tree():
		visible = not _eintraege.is_empty()
		return
	_aufbauen()

func aktualisieren() -> void:
	if _eintraege.is_empty():
		visible = false
		return
	_aufbauen()

func _aufbauen() -> void:
	if _reihe == null:
		_reihe = HBoxContainer.new()
		_reihe.name = "Reihe"
		_reihe.alignment = BoxContainer.ALIGNMENT_CENTER
		_reihe.add_theme_constant_override("separation", 6)
	if _reihe.get_parent() == null:
		add_child(_reihe)
	for kind in _reihe.get_children():
		kind.queue_free()
	_knopf_nach_id.clear()
	for eintrag in _eintraege:
		var id := str(eintrag.get("id", ""))
		if id == "":
			continue
		var name_text := str(eintrag.get("name", id))
		var shortcut := str(eintrag.get("shortcut", ""))
		var label_text := name_text
		if shortcut != "":
			label_text = "%s [%s]" % [name_text, shortcut]
		var btn := Button.new()
		btn.name = "Knopf_%s" % id
		btn.text = label_text
		btn.tooltip_text = str(eintrag.get("tooltip", label_text))
		# Einheitliche Breite, damit die Leiste nicht springt
		btn.custom_minimum_size = Vector2(116, 28)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		var aktion: Variant = eintrag.get("aktion", null)
		if aktion is Callable and (aktion as Callable).is_valid():
			var aktion_call: Callable = aktion as Callable
			btn.pressed.connect(func() -> void:
				aktion_call.call()
				_sichtbarkeit_nachziehen()
			)
		_reihe.add_child(btn)
		_knopf_nach_id[id] = btn
	visible = _reihe.get_child_count() > 0
	_sichtbarkeit_nachziehen()

func _sichtbarkeit_nachziehen() -> void:
	for eintrag in _eintraege:
		var id := str(eintrag.get("id", ""))
		var btn: Variant = _knopf_nach_id.get(id, null)
		if not (btn is Button):
			continue
		var sichtbar_call: Variant = eintrag.get("sichtbar", null)
		if sichtbar_call is Callable and (sichtbar_call as Callable).is_valid():
			var sichtbar := bool((sichtbar_call as Callable).call())
			(btn as Button).button_pressed = sichtbar

func _nach_name(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("name", "")) < str(b.get("name", ""))

func _standard_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.08, 0.1, 0.82)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = Color(1, 1, 1, 0.18)
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_right = 8
	box.corner_radius_bottom_left = 8
	box.content_margin_left = 10.0
	box.content_margin_top = 4.0
	box.content_margin_right = 10.0
	box.content_margin_bottom = 4.0
	return box
