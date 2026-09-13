extends Node2D
class_name Tier_Manager
## Verwaltung aller Tiere einer Welt im Takt der globalen Weltuhr. Tiere
## behalten eine stabile ID; Jobs und Angriffe laufen über diese ID. Das
## Wach-Sein der Darsteller führt der Tier_SichtWaechter, der Manager
## hält die Einträge, den Tick und die Zugriffe.

## Kategorie daten: Tier-Einträge mit Status, Darsteller und Position.
var _verhalten := Tier_Registry.new()
var _tiere: Array[Dictionary] = []
var _naechste_tier_nummer: int = 1
var _spieler_position := Vector2.ZERO
var _darsteller_ebene: Node2D
## Wächter über den Kamera-Blick: Ohne Bereich (Editor, Prüfläufe) ist
## alles sichtbar; im Spiel erwachen Tiere nur im Blick und schlafen außerhalb.
var _waechter := Tier_SichtWaechter.new()

## Parallel-Map: Referenz auf die Welt für 1/6 Tick-Gate.
var _welt_world: Welt_World = null
var _model: Welt_Model = null

## Kategorie logik: Platzierung, Tick-Abwicklung, Angriff und Ernte.

func _ready() -> void:
	y_sort_enabled = true
	_darsteller_ebene_anlegen()

func _darsteller_ebene_anlegen() -> void:
	# Der Anker wird faul angelegt, damit Platzierung auch ohne fertigen
	# Szenen-Kontext (Headless-Prüfungen) sicher funktioniert.
	if _darsteller_ebene != null:
		return
	_darsteller_ebene = Node2D.new()
	_darsteller_ebene.name = "TierDarstellerEbene"
	_darsteller_ebene.y_sort_enabled = true
	add_child(_darsteller_ebene)

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
	## Einer tritt an: Darsteller bauen und an die Ebene hängen.
	_darsteller_ebene_anlegen()
	var darsteller := Tier_Darsteller.new()
	darsteller.einrichten(tier_id, _verhalten, status)
	darsteller.position = welt_position
	_darsteller_ebene.add_child(darsteller)
	return darsteller

func alle_entfernen() -> void:
	## Idempotenz-Gate: Entfernt alle Tier-Darsteller aus dem Szenenbaum
	## und leert die interne Liste; stabile IDs beginnen danach neu.
	for tier: Dictionary in _tiere:
		var knoten: Variant = tier.get("darsteller")
		if knoten != null and is_instance_valid(knoten):
			(knoten as Node).queue_free()
	_tiere.clear()
	_naechste_tier_nummer = 1

func spieler_position_setzen(neue_position: Vector2) -> void:
	_spieler_position = neue_position

func tier_id_bei(ziel: Vector2, radius: float) -> int:
	# Stabile ID des Tieres nahe dem Punkt, sonst -1; fliehende Vögel kreisen
	# hoch über dem Boden, der Trefferbereich wächst mit der Körpergröße.
	var bester_id := -1
	var bester_abstand := INF
	for tier: Dictionary in _tiere:
		var groesse := _verhalten.frame_groesse(str(tier["tier_id"]))
		var mitte: Vector2 = tier["position"] + Vector2(0, -groesse.y / 2.0)
		var abstand := mitte.distance_to(ziel)
		if abstand <= radius + groesse.y * 0.6 and abstand < bester_abstand:
			bester_abstand = abstand
			bester_id = tier["id"]
	return bester_id

func tier_art(tier_nummer: int) -> String:
	for tier: Dictionary in _tiere:
		if tier["id"] == tier_nummer:
			return str(tier["tier_id"])
	return ""

func tier_effektiver_faktor(tier_nummer: int) -> float:
	## G1-Leser: Eigenfaktor × Logik-Basisfaktor; unbekannt bleibt neutral.
	var daten := _verhalten.tier_daten(tier_art(tier_nummer))
	return 1.0 if daten == null else daten.effektiver_faktor()

func tier_position(tier_nummer: int) -> Vector2:
	# Ungültige IDs liefern Vector2.INF, damit Aufrufer das Ziel prüfen können.
	for tier: Dictionary in _tiere:
		if tier["id"] == tier_nummer:
			return tier["position"]
	return Vector2.INF

func tier_angreifen(tier_nummer: int, schaden: int) -> bool:
	var status := _status_fuer(tier_nummer)
	if status == null:
		return false
	status.schaden_nehmen(schaden)
	return status.ist_tot()

func tier_ernten(tier_nummer: int) -> int:
	## Erntet ein totes Tier und gibt den Fleisch-Ertrag zurück (sonst 0).
	var index := _index_fuer(tier_nummer)
	if index < 0:
		return 0
	var tier: Dictionary = _tiere[index]
	var status: Tier_Status = tier["status"]
	if not status.ist_tot():
		return 0
	var ertrag := status.fleisch
	# Der Darsteller wird erst geprüft, dann typisiert: Ein bereits
	# freigegebener Knoten darf nicht in eine typisierte Variable wandern.
	var darsteller_knoten: Variant = tier.get("darsteller")
	if is_instance_valid(darsteller_knoten):
		(darsteller_knoten as Tier_Darsteller).verschwinden()
	_tiere.remove_at(index)
	_nachruecken()
	return ertrag

func _status_fuer(tier_nummer: int) -> Tier_Status:
	var index := _index_fuer(tier_nummer)
	if index < 0:
		return null
	return _tiere[index]["status"]

func _index_fuer(tier_nummer: int) -> int:
	for index in _tiere.size():
		if _tiere[index]["id"] == tier_nummer:
			return index
	return -1

func _nachruecken() -> void:
	# Darsteller, die sich selbst entfernt haben, fliegen aus der Liste;
	# Schlaffende (null) bleiben, bis der Blick sie weckt oder ein Job erntet.
	var aufgerueckt: Array[Dictionary] = []
	for tier: Dictionary in _tiere:
		var knoten: Variant = tier.get("darsteller")
		if knoten != null and not is_instance_valid(knoten):
			continue
		aufgerueckt.append(tier)
	_tiere = aufgerueckt

func _auf_tick(_nummer: int, delta: float) -> void:
	## 1/6 Tick-Gate: Inaktive Karten ticken nur jedes 6. Frame.
	if _welt_world != null and _model != null:
		var aktive_map_id := _welt_world.aktive_map_id()
		var eigene_map_id := _model.map_id
		if aktive_map_id != "" and aktive_map_id != eigene_map_id:
			if Engine.get_process_frames() % 6 != 0:
				return
	# Der Wächter ordnet zuerst das Wach-Sein: Wecken im Blick mit Budget,
	# Einschlafen außerhalb, Geister und Ernte-Ausblendungen zum Austrag.
	var entfernte := _waechter.wachen_und_schlafen(_tiere, _darsteller_erzeugen)
	for tier: Dictionary in _tiere:
		var darsteller_knoten: Variant = tier.get("darsteller")
		if darsteller_knoten == null:
			# Schlafend: Der Logik-Eintrag tickt ohne Node weiter.
			var schlaf_status: Tier_Status = tier["status"]
			schlaf_status.tick(delta, tier["position"], _spieler_position)
			continue
		if not is_instance_valid(darsteller_knoten):
			continue
		var darsteller := darsteller_knoten as Tier_Darsteller
		var status: Tier_Status = tier["status"]
		var bewegung := status.tick(delta, tier["position"], _spieler_position)
		if bewegung != Vector2.ZERO:
			tier["position"] = tier["position"] + bewegung
			darsteller.global_position = tier["position"]
	# Von hinten austragen: Das Entfernen verschiebt alle folgenden Indizes,
	# ein Lauf von vorne würde bei mehreren Treffern die falschen Tiere löschen.
	entfernte.reverse()
	for index in entfernte:
		_tiere.remove_at(index)

func tier_zahl() -> int:
	return _tiere.size()

func tier_bestand() -> Array[Dictionary]:
	## Geschlossener Leser: Kopie, damit niemand die Interna mutiert.
	var kopie: Array[Dictionary] = []
	for tier: Dictionary in _tiere:
		kopie.append({
			"id": tier.get("id", -1),
			"tier_id": str(tier.get("tier_id", "")),
			"position": tier.get("position", Vector2.ZERO),
		})
	return kopie
