extends RefCounted
class_name Welt_FortschrittsRegistry
## Registry der Einstiegs-Progression: lädt game/data/progression.json und
## hält die Stufenkette als Wörterbuch-Eintraege. Sie besitzt keine Zahlen
## und keine Logik; die Maschine rechnet nur mit den gelieferten Einträgen.
## Erweiterungsgrenze: eine neue Stufe ist nur ein neuer Eintrag im Pool.

const PROGRESSION_PFAD := "res://game/data/progression.json"

## Kategorie daten: getypte Liste aller Stufen.
var stufen: Array[Dictionary] = []
var _stufen_nach_id: Dictionary = {}

## Kategorie logik: Laden und reine Leser.

func _init() -> void:
	_laden()

func _laden() -> void:
	if not FileAccess.file_exists(PROGRESSION_PFAD):
		push_warning("Progressions-Daten fehlen: %s" % PROGRESSION_PFAD)
		return
	var datei := FileAccess.open(PROGRESSION_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Progressions-Daten haben ein ungültiges Format: %s" % PROGRESSION_PFAD)
		return
	stufen.clear()
	_stufen_nach_id.clear()
	for eintrag: Variant in (gelesen as Dictionary).get("stufen", []) as Array:
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		var stufe := (eintrag as Dictionary).duplicate(true)
		stufen.append(stufe)
		_stufen_nach_id[str(stufe.get("id", ""))] = stufe

func stufe_fuer(stufe_id: String) -> Dictionary:
	if _stufen_nach_id.has(stufe_id):
		return _stufen_nach_id[stufe_id]
	return {}

func stufe_an(index: int) -> Dictionary:
	if index >= 0 and index < stufen.size():
		return stufen[index]
	return {}

func stufen_zahl() -> int:
	return stufen.size()
