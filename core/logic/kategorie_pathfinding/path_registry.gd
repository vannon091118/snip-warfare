extends Welt_RegistryBasis
class_name Kern_PathRegistry
## Registry des Pathfinding-Moduls. Sie ist die einzige Quelle für Weg-Boni,
## Unebenheiten-Mali und Kollisions-Sperrungen je Kachel-Typ. Neue Terraintypen
## werden nur hier nachgetragen; der Wegfinder liest ausschließlich hier.
## Quelle: game/data/steuerung.json Abschnitt pathfinding (menschenlesbar).

const PFAD_PFAD := "res://game/data/steuerung.json"

## Kategorie daten: Boni und Mali je Kachel-Typ als Wörterbuch.
var weg_bonus_nach_kachel: Dictionary = {}
var ebenen_malus_nach_kachel: Dictionary = {}
var sperrung_nach_kachel: Dictionary = {}

## Kategorie logik: Laden aus der Steuerungsdatei und Abfragen.

func _init() -> void:
	super(PFAD_PFAD)

func schema_name() -> String:
	return "Kern_PathRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	weg_bonus_nach_kachel.clear()
	ebenen_malus_nach_kachel.clear()
	sperrung_nach_kachel.clear()
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Pfad-Daten haben ein ungueltiges Format: %s" % PFAD_PFAD)
		return false
	var pfad: Variant = (gelesen as Dictionary).get("pathfinding", {})
	if typeof(pfad) != TYPE_DICTIONARY:
		return true
	var wege: Variant = (pfad as Dictionary).get("weg_bonus", {})
	var unebenen: Variant = (pfad as Dictionary).get("unebenheiten_malus", {})
	var sperren: Variant = (pfad as Dictionary).get("kollisions_sperrung", {})
	for kachel_id: String in (wege as Dictionary).keys():
		weg_bonus_nach_kachel[kachel_id] = float((wege as Dictionary)[kachel_id])
	for kachel_id: String in (unebenen as Dictionary).keys():
		ebenen_malus_nach_kachel[kachel_id] = float((unebenen as Dictionary)[kachel_id])
	for kachel_id: String in (sperren as Dictionary).keys():
		sperrung_nach_kachel[kachel_id] = bool((sperren as Dictionary)[kachel_id])
	return true

func weg_bonus_fuer(kachel_id: String) -> float:
	return float(weg_bonus_nach_kachel.get(kachel_id, 0.0))

func ebenen_malus_fuer(kachel_id: String) -> float:
	return float(ebenen_malus_nach_kachel.get(kachel_id, 0.0))

func ist_gesperrt(kachel_id: String) -> bool:
	return bool(sperrung_nach_kachel.get(kachel_id, false))

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["weg_bonus"] = "Dictionary"
	arten["ebenen_malus"] = "Dictionary"
	return arten
