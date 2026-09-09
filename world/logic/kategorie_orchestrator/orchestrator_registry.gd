extends RefCounted
class_name Orchestrator_Registry
## Kategorie logik: Registry für Orchestrator-Konfigurationen
var _konfigurationen: Dictionary = {}  # [orchestrator_id: Orchestrator_Konfiguration]
var _basis_pfade: Array[String] = ["res://game/data/orchestrator_config.json"]

## Kategorie logik: Laden & Erstellen
func laden(pfade: Array[String] = []) -> void:
	var pfade_zu_laden := pfade if pfade.size() > 0 else _basis_pfade
	for pfad in pfade_zu_laden:
		_laden_von_json(pfad)

func _laden_von_json(pfad: String) -> void:
	if not FileAccess.file_exists(pfad):
		return
	var datei := FileAccess.open(pfad, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) != TYPE_DICTIONARY:
		return

	# FIXED: Properly iterate dictionary values (not keys)
	for key in daten:
		var eintrag = daten[key]
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		var konfig := Orchestrator_Konfiguration.new()
		konfig.orchestrator_id = str(eintrag.get("orchestrator_id", key))  # fallback to key if missing
		konfig.position = Vector2(
			float(eintrag.get("position_x", 0)),
			float(eintrag.get("position_y", 0))
		)
		konfig.radius = float(eintrag.get("radius", 100.0))
		konfig.biom_id = str(eintrag.get("biom_id", ""))
		var bedarf := eintrag.get("bedarfsliste", [])
		if typeof(bedarf) == TYPE_ARRAY:
			konfig.bedarfsliste = bedarf as Array[Dictionary]
		else:
			konfig.bedarfsliste = []
		konfig.farbe = Color(
			float(eintrag.get("farbe_r", 0.2)),
			float(eintrag.get("farbe_g", 0.6)),
			float(eintrag.get("farbe_b", 0.2)),
			1.0
		)
		_konfigurationen[konfig.orchestrator_id] = konfig

func konfiguration_erstellen(orchestrator_id: String, overrides: Dictionary = {}) -> Orchestrator_Konfiguration:
	var basis := _konfigurationen.get(orchestrator_id, null)
	if not basis:
		return null

	var erstellt := Orchestrator_Konfiguration.new()
	erstellt.orchestrator_id = orchestrator_id
	erstellt.position = overrides.get("position", basis.position)
	erstellt.radius = overrides.get("radius", basis.radius)
	erstellt.biom_id = overrides.get("biom_id", basis.biom_id)
	erstellt.bedarfsliste = overrides.get("bedarfsliste", basis.bedarfsliste)
	erstellt.farbe = overrides.get("farbe", basis.farbe)
	erstellt.zustand = Orchestrator_Status.Zustand.KONFIGURIERT
	return erstellt

func konfiguration_fuer(orchestrator_id: String) -> Orchestrator_Konfiguration:
	return _konfigurationen.get(orchestrator_id, null)

func konfigurationen() -> Array[Orchestrator_Konfiguration]:
	var listen: Array[Orchestrator_Konfiguration] = []
	for konfig in _konfigurationen.values():
		listen.append(konfig)
	return listen

func gibt_es(orchestrator_id: String) -> bool:
	return _konfigurationen.has(orchestrator_id)