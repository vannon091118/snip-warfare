extends Node2D
class_name Tier_Manager
## Verwaltung aller Tiere einer Welt im Takt der globalen Weltuhr.
## Prüft pro Tick die Trigger-Zonen gegen die Spielerposition und wendet
## die von den Zustandsmaschinen gelieferten Bewegungen an.
## Tiere behalten eine stabile ID; Jobs und Angriffe laufen über diese ID,
## damit Positionen beim Entfernen nicht verrutschen.

## Kategorie daten: Tier-Einträge mit Status, Darsteller und Position.
const MAX_DARSTELLER := 120

var _verhalten := Tier_Registry.new()
var _tiere: Array[Dictionary] = []
var _naechste_tier_nummer: int = 1
var _spieler_position := Vector2.ZERO
var _darsteller_ebene: Node2D

## Kategorie logik: Platzierung, Tick-Abwicklung, Angriff und Ernte.

func _ready() -> void:
	_darsteller_ebene = Node2D.new()
	_darsteller_ebene.name = "TierDarstellerEbene"
	add_child(_darsteller_ebene)

func _enter_tree() -> void:
	# Die Weltuhr wird zur Laufzeit aufgelöst statt über den Autoload-Namen,
	# damit der Manager auch in Headless-Testläufen ohne Autoloads ladbar
	# bleibt. Im Spiel ist es dieselbe zentrale Uhr aus project.godot.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func tier_platzieren(tier_id: String, welt_position: Vector2) -> int:
	if not _verhalten.hat_eintrag(tier_id):
		push_warning("Unbekanntes Tier: %s" % tier_id)
		return -1
	var status := Tier_Status.new(tier_id, _verhalten)
	var darsteller := Tier_Darsteller.new()
	darsteller.einrichten(tier_id, _verhalten, status)
	darsteller.position = welt_position
	_darsteller_ebene.add_child(darsteller)
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

func spieler_position_setzen(neue_position: Vector2) -> void:
	_spieler_position = neue_position

func tier_id_bei(ziel: Vector2, radius: float) -> int:
	# Liefert die stabile ID des Tieres nahe dem Punkt, sonst -1.
	# Da fliehende Vögel hoch über dem Boden kreisen, wächst der Trefferbereich
	# mit der Körpergröße des Tieres.
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
	# Liefert die Tier-Art (z. B. "baer"), sonst "".
	for tier: Dictionary in _tiere:
		if tier["id"] == tier_nummer:
			return str(tier["tier_id"])
	return ""

func tier_position(tier_nummer: int) -> Vector2:
	# Ungültige IDs liefern Vector2.INF, damit Aufrufer das Ziel prüfen können.
	for tier: Dictionary in _tiere:
		if tier["id"] == tier_nummer:
			return tier["position"]
	return Vector2.INF

func tier_angreifen(tier_nummer: int, schaden: int) -> bool:
	# Schaden anwenden; liefert true, wenn das Tier dadurch stirbt.
	var status := _status_fuer(tier_nummer)
	if status == null:
		return false
	status.schaden_nehmen(schaden)
	return status.ist_tot()

func tier_ernten(tier_nummer: int) -> int:
	# Erntet ein totes Tier und gibt den Fleisch-Ertrag zurück (sonst 0).
	var index := _index_fuer(tier_nummer)
	if index < 0:
		return 0
	var tier: Dictionary = _tiere[index]
	var status: Tier_Status = tier["status"]
	if not status.ist_tot():
		return 0
	var ertrag := status.fleisch
	var darsteller: Tier_Darsteller = tier["darsteller"]
	if is_instance_valid(darsteller):
		darsteller.verschwinden()
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
	# Darsteller, die sich bereits selbst entfernt haben, aus der Liste nehmen.
	var aufgerueckt: Array[Dictionary] = []
	for tier: Dictionary in _tiere:
		if tier["darsteller"] == null or not is_instance_valid(tier["darsteller"]):
			continue
		aufgerueckt.append(tier)
	_tiere = aufgerueckt

func _auf_tick(_nummer: int, delta: float) -> void:
	var entfernte: Array[int] = []
	for index in _tiere.size():
		var tier: Dictionary = _tiere[index]
		var status: Tier_Status = tier["status"]
		var darsteller: Tier_Darsteller = tier["darsteller"]
		if not is_instance_valid(darsteller):
			entfernte.append(index)
			continue
		var bewegung := status.tick(delta, tier["position"], _spieler_position)
		if bewegung != Vector2.ZERO:
			tier["position"] = tier["position"] + bewegung
			darsteller.global_position = tier["position"]
		if not is_instance_valid(darsteller):
			entfernte.append(index)
	for index in entfernte:
		_tiere.remove_at(index)

func tier_zahl() -> int:
	return _tiere.size()
