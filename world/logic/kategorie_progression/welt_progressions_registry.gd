extends RefCounted
class_name Welt_ProgressionsRegistry
## Einzige Ladestelle des Progressions-Pools world/data/ressourcen_progression.json.
## Die Klasse liest nur Daten: Stufen je Ressourcen-Typ, Waermegrenzen und die
## Seed-Spawn-Regeln. Sie berechnet nichts und besitzt keine Zeit.

## Kategorie daten: der geladene Pool als Woerterbuch.
var _pool: Dictionary = {}

## Kategorie logik: Laden und lesende Zugriffe auf den Datenpool.

const KONFIG_PFAD := "res://world/data/ressourcen_progression.json"

func laden() -> void:
	var datei := FileAccess.open(KONFIG_PFAD, FileAccess.READ)
	if datei == null:
		push_warning("Progressions-Pool fehlt: %s" % KONFIG_PFAD)
		return
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) == TYPE_DICTIONARY:
		_pool = gelesen

func _abschnitt(abschnitt_name: String) -> Dictionary:
	var wert: Variant = _pool.get(abschnitt_name, {})
	return wert as Dictionary if typeof(wert) == TYPE_DICTIONARY else {}

func definition_fuer(element_id: String) -> Dictionary:
	return _abschnitt("stufen").get(element_id, {})

func hat_definition(element_id: String) -> bool:
	return _abschnitt("stufen").has(element_id)

func staerke_fuer(element_id: String) -> int:
	return maxi(int(definition_fuer(element_id).get("staerke", 1)), 1)

func stadien_fuer(element_id: String) -> Array:
	return definition_fuer(element_id).get("stadien", [])

func folge_objekt_fuer(element_id: String) -> String:
	return str(definition_fuer(element_id).get("folge_objekt", ""))

func kategorie_fuer(element_id: String) -> String:
	return str(definition_fuer(element_id).get("kategorie", ""))

func wachstums_ticks_fuer(element_id: String) -> int:
	return maxi(int(definition_fuer(element_id).get("wachstums_ticks", 0)), 0)

func regenerations_ticks_fuer(element_id: String) -> int:
	return maxi(int(definition_fuer(element_id).get("regenerations_ticks", 0)), 0)

func stufe_icon_pfad_fuer(element_id: String) -> String:
	return str(definition_fuer(element_id).get("stufe_icon_pfad", ""))

func stufen_blatt() -> Dictionary:
	# Geometrie der Stufen-Sheets als Daten: Blattbreite, Blatthoehe und die
	# Zahl der Blaetter nebeneinander. Der Renderer schneidet damit dieselben
	# Zellen, ohne eine zweite Zellgroesse zu kennen.
	return _abschnitt("stufen_blatt")

func waerme_max_faktor() -> float:
	return float(_abschnitt("waerme").get("max_faktor", 1.0))

func waerme_min_faktor() -> float:
	return float(_abschnitt("waerme").get("min_faktor", 0.25))

func spawn_je_tag() -> int:
	return maxi(int(_abschnitt("seed_spawn").get("je_tag", 2)), 0)

func spawn_kandidaten() -> Array:
	return _abschnitt("seed_spawn").get("spawn_kandidaten", [])

func spawn_kategorie() -> String:
	return str(_abschnitt("seed_spawn").get("kategorie", "objekte"))

func fruchtbarkeit_max_faktor() -> float:
	return float(_abschnitt("seed_spawn").get("fruchtbarkeit_max_faktor", 1.5))

func fruchtbarkeit_min_faktor() -> float:
	return float(_abschnitt("seed_spawn").get("fruchtbarkeit_min_faktor", 0.5))
