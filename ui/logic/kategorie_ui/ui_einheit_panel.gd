extends RefCounted
class_name Ui_EinheitPanel
## Uebersetzer der Einheit: Liest nur ueber den geschlossenen Schnittpunkt
## Einheit_Manager.einheit_beschreibung() (plus einheit_position). Niemals
## _einheiten direkt. Ein Fenster ruft nur diesen Uebersetzer.
## Schnittregel: Neue Daten kommen nur ueber Manager-Snapshot, nie durch
## direkte Feldzugriffe des Panels.

## Kategorie daten: letzter ausgelesener Snapshot (nur fuer Tests lesbar).
var letzter_snapshot: Dictionary = {}

## Kategorie logik: Snapshot in beschreibbare Zeilen uebersetzen.

func zeilen_fuer(einheit_index: int, manager: Einheit_Manager) -> Array[String]:
	if manager == null or einheit_index < 0 or einheit_index >= manager.einheit_zahl():
		return ["> Keine Einheit gewählt."]
	var beschreibung := manager.einheit_beschreibung(einheit_index)
	if beschreibung.is_empty():
		return ["> Keine Einheit gewählt."]
	letzter_snapshot = beschreibung
	var pos: Vector2 = beschreibung.get("position", Vector2.ZERO)
	var job_name: String = str(beschreibung.get("job_id", ""))
	var zustand_name: String = "IDLE"
	match int(beschreibung.get("zustand", 0)):
		Einheit_Status.Zustand.GEHEN:
			zustand_name = "GEHEN"
		Einheit_Status.Zustand.ARBEITEN:
			zustand_name = "ARBEITEN"
	var hp_text := "%d" % int(float(beschreibung.get("hp", 0.0)))
	var queue := int(beschreibung.get("queue", 0))
	var rasse := str(beschreibung.get("rasse", ""))
	var ziel_index := int(beschreibung.get("ziel_index", -1))
	var ziel := str(ziel_index) if ziel_index >= 0 else "-"
	return [
		"> Einheit %d — %s" % [einheit_index, rasse],
		"> Zustand: %s | Job: %s | Ziel-Idx: %s" % [zustand_name, job_name if job_name != "" else "-", ziel],
		"> Pos: %s | HP: %s | Queue: %d" % [str(pos), hp_text, queue],
	]
