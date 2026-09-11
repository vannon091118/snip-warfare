extends PopupMenu
## Panel-Spitze: Rechtsklick-Kontextmenü. Es liest seine Einträge ausschließlich
## aus der Kern_SteuerungRegistry (game/data/steuerung.json): Label, Icon,
## Tooltip mit Werkzeug-Platzhalter und die ziel_tags der Aktion. Es führt
## nichts aus; es meldet nur, welche Aktion gewählt wurde.
## Filterregel: Eine Aktion erscheint, wenn ihre ziel_tags die ziel_tags des
## angeklickten Ortes treffen. Beide Tag-Listen sind Daten (steuerung.json und
## element_katalog.json); dieses Menü vergleicht keine Objektnamen mehr.
## Kette: Kern_SteuerungRegistry -> eintraege_aufbauen_fuer_tags -> id_pressed.

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
	# Vertrag der bestehenden Aufrufer: ein einzelner Zielbegriff. Er zählt
	# als ein Ziel-Tag; leer bedeutet kein Filter (Aufbau und Stufenwechsel).
	var tags: Array[String] = []
	if ziel_filter != "":
		tags.append(ziel_filter)
	eintraege_aufbauen_fuer_tags(tags)

func eintraege_aufbauen_fuer_tags(ziel_tags: Array) -> void:
	# Der Parameter bleibt bewusst untypisiert: Aufrufer reichen kurze
	# Literale herein; die Ziel-Tags werden hier in eine reine Textliste
	# überführt, damit der Vergleich tiefer nicht auf Varianten trifft.
	var tags: Array[String] = []
	for tag: Variant in ziel_tags:
		tags.append(str(tag))
	_aufbauen_mit_tags(tags)

func _aufbauen_mit_tags(ziel_tags: Array[String]) -> void:
	clear()
	_aktuelle_aktionen.clear()
	var alle_aktionen: Array[Dictionary] = []
	if _steuerung != null and _steuerung.steuerung != null:
		alle_aktionen = _steuerung.steuerung.kontext_aktionen

	for aktion: Dictionary in alle_aktionen:
		if not _ist_zielgerichtet(aktion, ziel_tags):
			continue
		var aktion_id := str(aktion.get("id", ""))
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

func _ist_zielgerichtet(aktion: Dictionary, ziel_tags: Array[String]) -> bool:
	# Drei Fälle, alle datengetrieben: Ohne Ziel-Tags am Ort wird nicht
	# gefiltert (Menüaufbau). Ohne ziel_tags der Aktion gilt die Aktion
	# überall (Expansion). Sonst entscheidet die Schnittmenge der Tags.
	if ziel_tags.is_empty():
		return true
	var aktion_tags: Variant = aktion.get("ziel_tags", [])
	if typeof(aktion_tags) != TYPE_ARRAY or (aktion_tags as Array).is_empty():
		return true
	for tag: Variant in aktion_tags as Array:
		if ziel_tags.has(str(tag)):
			return true
	return false

func _auf_id(id: int) -> void:
	if id < 0 or id >= _aktuelle_aktionen.size():
		return
	letzte_aktion = _aktuelle_aktionen[id]
	aktion_gewaehlt.emit(letzte_aktion)
