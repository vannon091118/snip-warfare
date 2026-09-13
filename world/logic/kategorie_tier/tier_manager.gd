extends Node2D
class_name Tier_Manager
## Verwaltung aller Tiere einer Welt im Takt der globalen Weltuhr. Tiere
## behalten eine stabile Nummer; Jobs und Angriffe laufen über diese Nummer.
## Den Lesesaal trägt der Tier_Leser, die Darsteller die Tier_DarstellerFabrik,
## den Takt der Tier_Takt und das Wach-Sein der Tier_SichtWaechter; hier bleibt
## der Bestand und seine Zugriffe.

## Kategorie daten: Tier-Einträge mit Status, Darsteller und Position.
var _verhalten := Tier_Registry.new()
var _tiere: Array[Dictionary] = []
var _naechste_tier_nummer: int = 1
var _spieler_position := Vector2.ZERO
## Wächter über den Kamera-Blick: Ohne Bereich (Editor, Prüfläufe) ist alles
## sichtbar; im Spiel erwachen Tiere nur im Blick und schlafen außerhalb.
var _waechter := Tier_SichtWaechter.new()
var _fabrik := Tier_DarstellerFabrik.new()
var _takt := Tier_Takt.new(self)

## Parallel-Map: Referenz auf die Welt für das Karten-Gate.
var _welt_world: Welt_World = null
var _model: Welt_Model = null

## Kategorie logik: Platzieren, Ernten, Sichten und der eigene Takt.
func _ready() -> void:
	y_sort_enabled = true
	_fabrik.einrichten(_verhalten)

func _enter_tree() -> void:
	# Die Weltuhr wird zur Laufzeit aufgelöst statt über den Autoload-Namen,
	# damit der Manager auch in Headless-Testläufen ohne Autoloads ladbar bleibt.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func modell_setzen(model: Welt_Model, welt_world: Welt_World = null) -> void:
	_model = model
	_welt_world = welt_world

func sichtbereich_setzen(rechteck: Rect2) -> void:
	## Die Szene reicht das Kamera-Rechteck herein; der Abgleich läuft
	## budgetiert im Tick, nicht je Ruf.
	_waechter.bereich_setzen(rechteck)

func sichtbereich_deaktivieren() -> void:
	## Ohne Blick (Editor, Prüflauf, Speicher-Rückweg) erwacht wieder alles.
	_waechter.deaktivieren()
	_waechter.alles_aufwecken(_tiere, _darsteller_erzeugen)

func tier_platzieren(tier_id: String, welt_position: Vector2) -> int:
	if not _verhalten.hat_eintrag(tier_id):
		push_warning("Unbekanntes Tier: %s" % tier_id)
		return -1
	var status := Tier_Status.new(tier_id, _verhalten)
	# Fauler Aufbau: Nur im Blick gibt es sofort einen Darsteller. Außerhalb
	# schläft das Tier als reiner Logik-Eintrag und erwacht budgetiert im Tick.
	var darsteller: Tier_Darsteller = null
	if _waechter.enthaelt(welt_position):
		darsteller = _darsteller_erzeugen(tier_id, status, welt_position)
	var tier_nummer := _naechste_tier_nummer
	_naechste_tier_nummer += 1
	_tiere.append({
		"id": tier_nummer,
		"tier_id": tier_id,
		"status": status,
		"darsteller": darsteller,
		"position": welt_position,
	})
	return tier_nummer

func _darsteller_erzeugen(tier_id: String, status: Tier_Status, welt_position: Vector2) -> Tier_Darsteller:
	return _fabrik.darsteller_erzeugen(self, tier_id, status, welt_position)

func alle_entfernen() -> void:
	## Idempotenz-Gate: Alle Darsteller fallen, die Liste leert sich, die
	## stabilen Nummern beginnen danach neu.
	_fabrik.darsteller_freigeben(_tiere)
	_tiere.clear()
	_naechste_tier_nummer = 1

func spieler_position_setzen(neue_position: Vector2) -> void:
	_spieler_position = neue_position

func tier_id_bei(ziel: Vector2, radius: float) -> int:
	return Tier_Leser.id_bei(_tiere, _verhalten, ziel, radius)

func tier_art(tier_nummer: int) -> String:
	return Tier_Leser.art(_tiere, tier_nummer)

func tier_effektiver_faktor(tier_nummer: int) -> float:
	return Tier_Leser.effektiver_faktor(_tiere, _verhalten, tier_nummer)

func tier_position(tier_nummer: int) -> Vector2:
	return Tier_Leser.position(_tiere, tier_nummer)

func tier_angreifen(tier_nummer: int, schaden: int) -> bool:
	var status := Tier_Leser.status_fuer(_tiere, tier_nummer)
	if status == null:
		return false
	status.schaden_nehmen(schaden)
	return status.ist_tot()

func tier_ernten(tier_nummer: int) -> int:
	## Erntet ein totes Tier und gibt den Fleisch-Ertrag zurück (sonst 0).
	var index := Tier_Leser.index_fuer(_tiere, tier_nummer)
	if index < 0:
		return 0
	var status: Tier_Status = _tiere[index]["status"]
	if not status.ist_tot():
		return 0
	var ertrag := status.fleisch
	# Der Darsteller wird erst geprüft, dann typisiert: Ein bereits
	# freigegebener Knoten darf nicht in eine typisierte Variable wandern.
	var darsteller_knoten: Variant = _tiere[index].get("darsteller")
	if is_instance_valid(darsteller_knoten):
		(darsteller_knoten as Tier_Darsteller).verschwinden()
	_tiere.remove_at(index)
	_nachruecken()
	return ertrag

func _nachruecken() -> void:
	# Darsteller, die sich selbst entfernt haben, fliegen aus der Liste;
	# Schlafende (null) bleiben, bis der Blick sie weckt oder ein Job erntet.
	var aufgerueckt: Array[Dictionary] = []
	for tier: Dictionary in _tiere:
		var knoten: Variant = tier.get("darsteller")
		if knoten != null and not is_instance_valid(knoten):
			continue
		aufgerueckt.append(tier)
	_tiere = aufgerueckt

func _auf_tick(nummer: int, delta: float) -> void:
	_takt.tick(nummer, delta)

func tier_zahl() -> int:
	return Tier_Leser.zahl(_tiere)

func tier_bestand() -> Array[Dictionary]:
	return Tier_Leser.bestand(_tiere)
