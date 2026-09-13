extends RefCounted
class_name Gebaeude_KartenGate
## Tick-Gate der Gebäude: Inaktive Karten ticken nur jedes sechste Frame,
## damit der Hintergrund nicht dieselbe Rechenzeit frisst wie die Karte vor
## der Kamera. Einzige Frage, einzige Antwort; kein Zustand, keine Buchung.

const SECHSTEL := 6

func darf_ticken(welt_world: Welt_World, model: Welt_Model) -> bool:
	if welt_world == null or model == null:
		return true
	var aktive_map_id := welt_world.aktive_map_id()
	var eigene_map_id := model.map_id
	if aktive_map_id != "" and aktive_map_id != eigene_map_id:
		return Engine.get_process_frames() % SECHSTEL == 0
	return true
