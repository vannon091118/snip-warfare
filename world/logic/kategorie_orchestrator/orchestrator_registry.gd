extends RefCounted
class_name Orchestrator_Registry
## Registry der Orchestrator-Zonen. Die Quelle ist zentral die
## game/data/orchestrator_config.json; jede Zone entsteht nur hier
## als exakte Datenklasse Orchestrator_Konfiguration.

const ORCHESTRATOR_PFAD := "res://game/data/orchestrator_config.json"

## Kategorie daten: zentrale Zuordnung und getypte Zonenliste.
var zonen_nach_id: Dictionary = {}
var zonen: Array[Orchestrator_Konfiguration] = []

## Kategorie logik: Laden, Erzeugen und Zugriff.

func laden(pfad: String = ORCHESTRATOR_PFAD) -> void:
	zonen_nach_id.clear()
	zonen.clear()
	if not FileAccess.file_exists(pfad):
		push_warning("Orchestrator-Konfiguration nicht gefunden: %s" % pfad)
		return
	var datei := FileAccess.open(pfad, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Orchestrator-Daten haben ein ungültiges Format: %s" % pfad)
		return
	for eintrag_id: String in (gelesen as Dictionary).keys():
		var eintrag: Dictionary = gelesen[eintrag_id]
		var konfig := Orchestrator_Konfiguration.new()
		konfig.aus_eintrag(eintrag_id, eintrag)
		zonen_nach_id[eintrag_id] = konfig
		zonen.append(konfig)

func konfiguration_fuer(orchestrator_id: String) -> Orchestrator_Konfiguration:
	if zonen_nach_id.has(orchestrator_id):
		return zonen_nach_id[orchestrator_id]
	return null

func konfiguration_erstellen(orchestrator_id: String, overrides: Dictionary = {}) -> Orchestrator_Konfiguration:
	# Neue Zone aus Vorlage: Overrides ergänzen die Werte, sonst gilt die Basis.
	var basis := konfiguration_fuer(orchestrator_id)
	if basis == null:
		return null
	var erstellt := Orchestrator_Konfiguration.new()
	erstellt.aus_eintrag(orchestrator_id, {
		"position_x": overrides.get("position_x", basis.position.x),
		"position_y": overrides.get("position_y", basis.position.y),
		"radius": overrides.get("radius", basis.radius),
		"biom_id": overrides.get("biom_id", basis.biom_id),
		"bedarfsliste": overrides.get("bedarfsliste", basis.bedarfsliste),
		"farbe_r": overrides.get("farbe_r", basis.farbe.r),
		"farbe_g": overrides.get("farbe_g", basis.farbe.g),
		"farbe_b": overrides.get("farbe_b", basis.farbe.b),
	})
	return erstellt

func gibt_es(orchestrator_id: String) -> bool:
	return zonen_nach_id.has(orchestrator_id)
