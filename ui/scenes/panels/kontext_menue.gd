extends PopupMenu
## Panel-Spitze: Rechtsklick-Kontextmenü. Es liest seine Einträge ausschließlich
## aus der Kern_SteuerungRegistry (game/data/steuerung.json): Label, Icon und
## Tooltip mit Werkzeug-Platzhalter. Es führt nichts aus; es meldet nur, welche
## Aktion gewählt wurde.
## Kette: Kern_SteuerungRegistry -> eintraege_aufbauen -> id_pressed -> Meldung.

signal aktion_gewaehlt(aktion: Dictionary)

var _steuerung: Kern_SteuerungRegistry = null

## Kategorie daten: die gewählte Aktion als letzter Zustand des Menüs.
var letzte_aktion: Dictionary = {}

## Kategorie logik: Aufbau aus der Registry und Meldung der Wahl.

func einrichten(steuerung: Kern_SteuerungRegistry) -> void:
	_steuerung = steuerung
	eintraege_aufbauen()
	if not id_pressed.is_connected(_auf_id):
		id_pressed.connect(_auf_id)
	if not about_to_popup.is_connected(_auf_oeffnen):
		about_to_popup.connect(_auf_oeffnen)

func _auf_oeffnen() -> void:
	# Menü-Gegenprüfung: Das Öffnen meldet sich über den Signalbus; die
	# Modifikator-Maschinen aktualisieren daraufhin ihre Faktoren, damit
	# Anzeige und Zeiten präzise zum aktuellen Balancing passen.
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_menue_geoeffnet()

func eintraege_aufbauen() -> void:
	clear()
	var aktionen: Array[Dictionary] = []
	if _steuerung != null and _steuerung.steuerung != null:
		aktionen = _steuerung.steuerung.kontext_aktionen
	for aktion: Dictionary in aktionen:
		var eintrag_idx := item_count
		add_item(str(aktion.get("label", "")), eintrag_idx)
		var icon_pfad := str(aktion.get("icon_pfad", ""))
		if icon_pfad != "" and ResourceLoader.exists(icon_pfad):
			set_item_icon(eintrag_idx, load(icon_pfad))
		if _steuerung != null and _steuerung.steuerung != null:
			set_item_tooltip(eintrag_idx, _steuerung.steuerung.tooltip_fuer_aktion(str(aktion.get("id", ""))))

func _auf_id(id: int) -> void:
	var aktionen: Array[Dictionary] = []
	if _steuerung != null and _steuerung.steuerung != null:
		aktionen = _steuerung.steuerung.kontext_aktionen
	if id < 0 or id >= aktionen.size():
		return
	letzte_aktion = aktionen[id]
	aktion_gewaehlt.emit(letzte_aktion)
