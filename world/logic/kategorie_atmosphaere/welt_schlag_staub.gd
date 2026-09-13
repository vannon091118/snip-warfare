extends Node2D
class_name Welt_SchlagStaub
## Sichtbarer Arbeitsschlag: kurzer Staub-Puff und gezeichneter Blitz-Marker
## am Zielobjekt. Die Klasse hoert auf den Zustands-Zeitlinien-Bus der Welt-
## Szene (timeline_eintrag) und zeigt jede Erntebuchung als kleine Wolke am
## zuletzt gemeldeten Ernteort. Keine Gameplay-Logik, keine eigene Zeit,
## Selbst-Entfernung nach kurzer Dauer an der zentralen Weltuhr.

## Kategorie daten: Pool, Ernteort der letzten Buchung und aktive Knoten.
const STAUB := preload("res://world/assets/atmosphaere/staub.svg")
const TREFFER := preload("res://world/assets/atmosphaere/treffer.svg")

var _konfig: Welt_AtmosphaereKonfig = null
var _ernte_position: Vector2 = Vector2.INF
var _aktive: Array[Dictionary] = []
## Die aufgeloeste Uhr-Referenz: Der Abgang loest dieselbe Verbindung, die der
## Aufgang gelegt hat, statt den Autoload ein zweites Mal zu befragen.
var _weltuhr: Node = null

## Kategorie logik: Erzeugen, Bewegen und Aufräumen der Puffs je Tick.

func einrichten(konfig: Welt_AtmosphaereKonfig) -> void:
	_konfig = konfig
	z_index = 95

func ernte_ort_setzen(welt_position: Vector2) -> void:
	_ernte_position = welt_position

func _timeline_buchung_gesehen(beschreibung: String) -> void:
	# Nur echte Erntebuchungen werden sichtbar: Der Beschreibungstext der
	# bestehenden Buchung nennt die Ressource, nichts wird neu berechnet.
	if _ernte_position == Vector2.INF or not beschreibung.contains("eingelagert"):
		return
	schlag_zeigen(_ernte_position)

func schlag_zeigen(welt_position: Vector2) -> void:
	var dauer := 10
	var steig := 0.5
	var skalierung := 0.015
	if _konfig != null:
		dauer = maxi(int(_konfig.partikel_wert("staub_dauer_takt", 10.0)), 1)
		steig = _konfig.partikel_wert("staub_steig_px_pro_tick", 0.5)
		skalierung = _konfig.partikel_wert("staub_skalierung_pro_tick", 0.015)
	var puff := Sprite2D.new()
	puff.texture = STAUB
	puff.position = welt_position + Vector2(0.0, -52.0)
	add_child(puff)
	var blitz := Sprite2D.new()
	blitz.texture = TREFFER
	blitz.position = welt_position + Vector2(10.0, -78.0)
	blitz.rotation = 0.25
	add_child(blitz)
	_aktive.append({"knoten": puff, "alter": 0, "dauer": dauer, "steig": steig, "skalierung": skalierung})
	_aktive.append({"knoten": blitz, "alter": 0, "dauer": maxi(int(dauer * 0.5), 1), "steig": steig * 2.0, "skalierung": skalierung * 3.0})

func _enter_tree() -> void:
	# Die Uhr wird zur Laufzeit aufgeloest und vor dem Zugriff geprueft, wie in
	# jeder anderen Domaene: Der globale Autoload-Name wuerde in jedem Lauf ohne
	# Autoload (Editor, Prueflauf) mit einem Nil-Zugriff abbrechen.
	_weltuhr = get_node_or_null("/root/Weltuhr")
	if _weltuhr != null and _weltuhr.has_signal("tick") and not _weltuhr.tick.is_connected(_auf_tick):
		_weltuhr.tick.connect(_auf_tick)
	var bus := Kern_SignalBus.bus()
	if bus != null and not bus.timeline_eintrag.is_connected(_timeline_buchung_gesehen):
		bus.timeline_eintrag.connect(_timeline_buchung_gesehen)

func _exit_tree() -> void:
	if _weltuhr != null and is_instance_valid(_weltuhr) and _weltuhr.tick.is_connected(_auf_tick):
		_weltuhr.tick.disconnect(_auf_tick)
	_weltuhr = null
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.timeline_eintrag.is_connected(_timeline_buchung_gesehen):
		bus.timeline_eintrag.disconnect(_timeline_buchung_gesehen)

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
	var bleiben: Array[Dictionary] = []
	for eintrag: Dictionary in _aktive:
		var knoten := eintrag["knoten"] as Node2D
		if not is_instance_valid(knoten):
			continue
		eintrag["alter"] = int(eintrag["alter"]) + 1
		var alter := int(eintrag["alter"])
		var dauer := int(eintrag["dauer"])
		knoten.position.y -= float(eintrag["steig"])
		knoten.scale = knoten.scale + Vector2.ONE * float(eintrag["skalierung"])
		knoten.modulate.a = 1.0 - float(alter) / float(dauer)
		if alter < dauer:
			bleiben.append(eintrag)
		else:
			knoten.queue_free()
	_aktive = bleiben
