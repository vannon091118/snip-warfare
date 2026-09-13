extends RefCounted
class_name Orchestrator_KonfigLader
## Lader der Orchestrator-Konfiguration: Er liest die Zonen aus
## game/data/orchestrator_config.json und gibt sie als Wörterbuch zurück.
## Reines Lesen; keine Zone entsteht hier, keine Regel wohnt hier.

const PFAD := "res://game/data/orchestrator_config.json"

static func laden() -> Dictionary:
	if not FileAccess.file_exists(PFAD):
		return {}
	var datei := FileAccess.open(PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Orchestrator-Konfiguration ungültig: %s" % PFAD)
		return {}
	return gelesen as Dictionary
