extends PanelContainer
class_name Ui_BauPanelSzene
## Kategorie daten: Baufenster-Zustand (_alle_eintraege, Filter- und Kategoriewahl als reine Listen).
## Kategorie logik: Toggelbares, scrollbares Fenster mit Suche/Kategorie, das Daten aus der Registry lädt.
## Baufenster: Toggelbares, scrollbares Fenster mit Suche und Kategorie-Filter.
## Liest über Ui_BauPanel Daten aus Gebaeude_DefinitionRegistry + Fortschritt.
## Neue Einträge in world/data/gebaeude.json erscheinen automatisch – ohne
## dass hier Code geändert werden muss. Gesperrte Objekte werden angezeigt,
## aber ausgegraut, deaktiviert und mit Sperrstufe im Tooltip markiert
## (CP-7.1): Der Spieler sieht den Weg statt einer leeren Liste.

signal bau_gewaehlt(gebaeude_id: String)

var _panel_logik := Ui_BauPanel.new()
var _filter_logik := Ui_BaufensterFilter.new()
var _definitionen: Gebaeude_DefinitionRegistry = null
var _fortschritt: Welt_FortschrittsMaschine = null
var _steuerung: Kern_SteuerungRegistry = null
var _registry: Welt_Registry = null
var _alle_eintraege: Array[Dictionary] = []
var _kategorie_wahl: String = "Alle"
var _suchbegriff: String = ""

@onready var _button_container: GridContainer = %ButtonContainer
@onready var _suchfeld: LineEdit = %Suchfeld
@onready var _kategorie_wahl_knoten: OptionButton = %KategorieWahl
@onready var _scroll: ScrollContainer = %ScrollFenster

func einrichten(definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine, steuerung: Kern_SteuerungRegistry, registry: Welt_Registry = null) -> void:
	_definitionen = definitionen
	_fortschritt = fortschritt
	_steuerung = steuerung
	_registry = registry
	if _fortschritt != null and not _fortschritt.stufe_erreicht.is_connected(_auf_stufe):
		_fortschritt.stufe_erreicht.connect(_auf_stufe)
	aktualisieren()

func _ready() -> void:
	if _definitionen == null:
		_definitionen = Gebaeude_DefinitionRegistry.new()
	if is_inside_tree():
		var knopf := get_node_or_null("%SchliessenKnopf") as Button
		if knopf != null and not knopf.pressed.is_connected(_auf_schliessen):
			knopf.pressed.connect(_auf_schliessen)
		if _suchfeld != null and not _suchfeld.text_changed.is_connected(_auf_suche):
			_suchfeld.text_changed.connect(_auf_suche)
		if _kategorie_wahl_knoten != null and not _kategorie_wahl_knoten.item_selected.is_connected(_auf_kategorie):
			_kategorie_wahl_knoten.item_selected.connect(_auf_kategorie)
	visible = false
	if _button_container != null and _button_container.get_child_count() == 0:
		aktualisieren()

func _exit_tree() -> void:
	if _fortschritt != null and _fortschritt.stufe_erreicht.is_connected(_auf_stufe):
		_fortschritt.stufe_erreicht.disconnect(_auf_stufe)

func sichtbar_umschalten() -> void:
	visible = not visible

func sichtbar_setzen(sichtbar: bool) -> void:
	visible = sichtbar

func ist_sichtbar() -> bool:
	return visible

func aktualisieren() -> void:
	if _button_container == null:
		if Engine.is_editor_hint():
			return
		# Headless/Tests ohne Szenenbaum: trotzdem Logik pflegen
		_alle_eintraege = _panel_logik.eintraege_ermitteln(_definitionen, _fortschritt, _steuerung, _registry)
		return
	for kind in _button_container.get_children():
		kind.queue_free()
	_alle_eintraege = _panel_logik.eintraege_ermitteln(_definitionen, _fortschritt, _steuerung, _registry)
	_kategorie_auswahl_auffrischen()
	var sicht := _filter_logik.filtern(_alle_eintraege, _suchbegriff, _kategorie_wahl)
	for eintrag: Dictionary in sicht:
		var btn := Button.new()
		var geb_id := str(eintrag.get("id", ""))
		var label_text := str(eintrag.get("name", geb_id))
		var kategorie := str(eintrag.get("kategorie", ""))
		var kosten_text := str(eintrag.get("kosten_text", ""))
		var tooltip_text := str(eintrag.get("tooltip", ""))
		var gesperrt := bool(eintrag.get("gesperrt", false))
		var stufe := int(eintrag.get("stufe", 0))
		btn.text = "%s [%s]\n%s" % [label_text, kategorie, kosten_text]
		if gesperrt:
			btn.text += "\nStufe %d" % stufe
		btn.tooltip_text = tooltip_text
		btn.custom_minimum_size = Vector2(152, 56)
		btn.disabled = gesperrt
		btn.modulate = Color(1, 1, 1, 0.45) if gesperrt else Color.WHITE
		var icon_pfad := str(eintrag.get("icon_pfad", ""))
		if icon_pfad != "" and ResourceLoader.exists(icon_pfad):
			btn.icon = load(icon_pfad)
			btn.expand_icon = true
		if not gesperrt:
			btn.pressed.connect(func() -> void:
				bau_gewaehlt.emit(geb_id)
			)
		_button_container.add_child(btn)
	if _scroll != null:
		_scroll.scroll_vertical = 0

func _kategorie_auswahl_auffrischen() -> void:
	if _kategorie_wahl_knoten == null:
		return
	var verfuegbar := _filter_logik.kategorien_aus(_alle_eintraege)
	var bestehende: Array[String] = []
	for index in _kategorie_wahl_knoten.item_count:
		bestehende.append(_kategorie_wahl_knoten.get_item_text(index))
	if bestehende == verfuegbar:
		return
	_kategorie_wahl_knoten.clear()
	for kat in verfuegbar:
		_kategorie_wahl_knoten.add_item(kat)
	var gewaehlt := verfuegbar.find(_kategorie_wahl)
	if gewaehlt >= 0:
		_kategorie_wahl_knoten.select(gewaehlt)
	else:
		_kategorie_wahl = "Alle"
		_kategorie_wahl_knoten.select(0)

func _auf_schliessen() -> void:
	sichtbar_setzen(false)

func _auf_suche(text: String) -> void:
	_suchbegriff = text
	aktualisieren()

func _auf_kategorie(index: int) -> void:
	if _kategorie_wahl_knoten == null:
		return
	_kategorie_wahl = _kategorie_wahl_knoten.get_item_text(index)
	aktualisieren()

func _auf_stufe(_stufe: Dictionary) -> void:
	aktualisieren()
