extends PopupMenu
## Panel-Spitze: Rechtsklick-Kontextmenü. Es liest seine Einträge ausschließlich
## aus der Kern_SteuerungRegistry (game/data/steuerung.json): Label, Icon und
## Tooltip mit Werkzeug-Platzhalter. Es führt nichts aus; es meldet nur, welche
## Aktion gewählt wurde.
## Kette: Kern_SteuerungRegistry -> eintraege_aufbauen -> id_pressed -> Meldung.

signal aktion_gewaehlt(aktion: Dictionary)

var _steuerung: Kern_SteuerungRegistry = null
var _fortschritt: Welt_FortschrittsMaschine = null
var _aktuelle_aktionen: Array[Dictionary] = []

## Kategorie daten: die gewählte Aktion als letzter Zustand des Menüs.
var letzte_aktion: Dictionary = {}

## Kategorie logik: Aufbau aus der Registry und Meldung der Wahl.

func einrichten(steuerung: Kern_SteuerungRegistry, fortschritt: Welt_FortschrittsMaschine = null) -> void:
	_steuerung = steuerung
	_fortschritt = fortschritt
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
	eintraege_aufbauen_fuer("")

func eintraege_aufbauen_fuer(ziel_filter: String) -> void:
	clear()
	_aktuelle_aktionen.clear()
	var alle_aktionen: Array[Dictionary] = []
	if _steuerung != null and _steuerung.steuerung != null:
		alle_aktionen = _steuerung.steuerung.kontext_aktionen
	
	for aktion: Dictionary in alle_aktionen:
		var aktion_id := str(aktion.get("id", ""))
		var logik_id := str(aktion.get("logik_id", ""))
		
		# Kontextsensitive Filterung nach Zielobjekt:
		if ziel_filter != "":
			if ziel_filter.contains("baum") and aktion_id != "sammeln":
				continue
			elif ziel_filter.contains("stein") and aktion_id != "abbauen":
				continue
			elif ziel_filter.contains("busch") and aktion_id != "sammeln":
				continue
			elif ziel_filter == "tier" and aktion_id != "sammeln":
				continue
			elif ziel_filter == "boden" and (aktion_id == "sammeln" or aktion_id == "abbauen"):
				continue
		
		_aktuelle_aktionen.append(aktion)
		var gesperrt := false
		if _fortschritt != null and _steuerung != null and _steuerung.steuerung != null:
			gesperrt = not _fortschritt.stufe_frei(_steuerung.steuerung.gesperrt_ab_stufe_fuer_aktion(aktion_id))
		var eintrag_idx := item_count
		var label_text := str(aktion.get("label", ""))
		if gesperrt:
			label_text = "🔒 " + label_text
		add_item(label_text, eintrag_idx)
		set_item_disabled(eintrag_idx, gesperrt)
		var icon_pfad := str(aktion.get("icon_pfad", ""))
		if icon_pfad != "" and ResourceLoader.exists(icon_pfad):
			set_item_icon(eintrag_idx, load(icon_pfad))
		if _steuerung != null and _steuerung.steuerung != null:
			set_item_tooltip(eintrag_idx, _steuerung.steuerung.tooltip_fuer_aktion(aktion_id))

func _auf_id(id: int) -> void:
	if id < 0 or id >= _aktuelle_aktionen.size():
		return
	letzte_aktion = _aktuelle_aktionen[id]
	aktion_gewaehlt.emit(letzte_aktion)
