extends PanelContainer
## Pop_EinheitPanel: Einheiten-HUD als PanelContainer.
## Sichtbar bei Kern_SignalBus.einheit_ausgewaehlt(einheit_id).
## Signal-getrieben, kein _process-Polling.
## Felder: aktueller Job, Hunger mit Farbskala, Wärme-Wert,
## Stimmungs-Modifikatoren als scrollbare Liste, Inventar-Slots.

@onready var _titel: Label = %Titel
@onready var _job_label: Label = %JobLabel
@onready var _zustand_label: Label = %ZustandLabel
@onready var _hp_label: Label = %HpLabel
@onready var _hunger_bar: ProgressBar = %HungerBar
@onready var _hunger_label: Label = %HungerLabel
@onready var _waerme_bar: ProgressBar = %WaermeBar
@onready var _waerme_label: Label = %WaermeLabel
@onready var _mood_container: VBoxContainer = %MoodContainer
@onready var _inventar_grid: GridContainer = %InventarGrid

var _uebersetzer: Pop_EinheitUebersetzer = null
var _signal_bus: Kern_SignalBus = null
var _aktiver_index: int = -1

func _ready() -> void:
	_signal_bus = Kern_SignalBus.bus()
	if _signal_bus != null:
		_signal_bus.einheit_ausgewaehlt.connect(_auf_einheit_ausgewaehlt)
	visible = false
	set_process(false)

func einrichten(uebersetzer: Pop_EinheitUebersetzer) -> void:
	_uebersetzer = uebersetzer

func _auf_einheit_ausgewaehlt(einheit_id: int) -> void:
	_aktiver_index = einheit_id
	if _aktiver_index >= 0:
		_anzeigen()
		visible = true
	else:
		visible = false

func _anzeigen() -> void:
	if _uebersetzer == null or _aktiver_index < 0:
		return
	var daten := _uebersetzer.daten_fuer_einheit(_aktiver_index)
	if daten.is_empty():
		visible = false
		return
	
	_titel.text = "Einheit %d — %s" % [daten.index, daten.rasse]
	_job_label.text = "Job: %s" % (daten.job if daten.job != "" else "keiner")
	_zustand_label.text = "Zustand: %s" % daten.zustand
	_hp_label.text = "HP: %d" % daten.hp
	
	# Hunger mit Farbskala
	var hunger := daten.hunger_wert
	_hunger_bar.value = hunger * 100.0
	_hunger_bar.max_value = 100.0
	var hunger_farbe := _uebersetzer.hunger_farbe(hunger)
	_hunger_bar.modulate = hunger_farbe
	_hunger_label.text = "Hunger: %d%%" % int(hunger * 100)
	_hunger_label.add_theme_color_override("font_color", hunger_farbe)
	
# Wärme-Wert
 	var waerme := daten.waerme_wert
 	_waerme_bar.value = (waerme + 1.0) * 50.0  # -1..1 auf 0..100
 	_waerme_bar.max_value = 100.0
 	var waerme_farbe := _uebersetzer.waerme_farbe(waerme)
 	_waerme_bar.modulate = waerme_farbe
 	_waerme_label.text = "Wärme: %.2f" % waerme
 	_waerme_label.add_theme_color_override("font_color", waerme_farbe)
	
	# Stimmungs-Modifikatoren als scrollbare Liste
	_mood_container.queue_free_children()
	if daten.mood:
		var mood_label := Label.new()
		mood_label.text = "Stimmung: %s %s" % [daten.mood.emoji, daten.mood.sprechblase]
		mood_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		mood_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_mood_container.add_child(mood_label)
		
		if daten.mood.grund != "":
			var grund_label := Label.new()
			grund_label.text = "Grund: %s" % daten.mood.grund
			grund_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			grund_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			grund_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
			_mood_container.add_child(grund_label)
		
		if daten.mood.wirkung != "":
			var wirkung_label := Label.new()
			wirkung_label.text = "Wirkung: %s" % daten.mood.wirkung
			wirkung_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			wirkung_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			wirkung_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
			_mood_container.add_child(wirkung_label)
		
		if daten.mood.kette != "":
			var kette_label := Label.new()
			kette_label.text = "Kette: %s (Stufe %d)" % [daten.mood.kette, daten.mood.stufe]
			kette_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			kette_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			kette_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.9, 1.0))
			_mood_container.add_child(kette_label)
	
	# Inventar-Slots
	_inventar_grid.queue_free_children()
	if daten.inventar:
		for res_id: String in daten.inventar:
			var menge: int = daten.inventar[res_id]
			var slot := HBoxContainer.new()
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(24, 24)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if _uebersetzer._ressourcen != null:
				var icon_pfad := _uebersetzer._ressourcen.icon_pfad(res_id)
				if icon_pfad != "":
					icon.texture = load(icon_pfad)
			var menge_label := Label.new()
			menge_label.text = "%s: %d" % [res_id, menge]
			menge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(icon)
			slot.add_child(menge_label)
			_inventar_grid.add_child(slot)

func _exit_tree() -> void:
	if _signal_bus != null and _signal_bus.has_signal("einheit_ausgewaehlt"):
		_signal_bus.einheit_ausgewaehlt.disconnect(_auf_einheit_ausgewaehlt)