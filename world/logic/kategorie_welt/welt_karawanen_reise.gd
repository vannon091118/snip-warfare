extends RefCounted
class_name Welt_KarawanenReise
## Reise-Rechner der Karawanen: Er liest die Wege des Makro-Netzwerks und
## liefert die Reisedauer in Ticks. Ohne Planer bleibt die Luftlinie als
## Rückfall. Er fährt nichts und tickt nichts; er rechnet nur.

const LUFTLINIE_FAKTOR := 0.24
const MIN_TICKS_OHNE_PLANER := 120
const MIN_TICKS_MIT_PLANER := 60
const ROH_FAKTOR := 50.0

func dauer_ticks(netzwerk_planer: Welt_NetzwerkPlaner, von_map_id: String, nach_map_id: String, von_pos: Vector2, nach_pos: Vector2) -> int:
	if netzwerk_planer == null:
		# Rückfall: euklidische Distanz mal Faktor, mindestens fünf Sekunden.
		return maxi(int(von_pos.distance_to(nach_pos) / ROH_FAKTOR), MIN_TICKS_OHNE_PLANER)
	var kuerzeste_distanz := _kuerzeste_wege_distanz(netzwerk_planer, von_map_id, nach_map_id)
	if kuerzeste_distanz == INF:
		# Kein direkter Weg: Rückfall auf Luftlinie.
		kuerzeste_distanz = von_pos.distance_to(nach_pos)
	# Umrechnung: 24 Ticks je Sekunde und rund hundert Pixel je Sekunde
	# ergeben Distanz mal 0,24 Ticks, mindestens zweieinhalb Sekunden.
	return maxi(int(kuerzeste_distanz * LUFTLINIE_FAKTOR), MIN_TICKS_MIT_PLANER)

func _kuerzeste_wege_distanz(netzwerk_planer: Welt_NetzwerkPlaner, von_map_id: String, nach_map_id: String) -> float:
	var kuerzeste := INF
	for weg: Dictionary in netzwerk_planer.wege():
		if not _verbindet(weg, von_map_id, nach_map_id):
			continue
		var dist := Vector2(weg.get("von", Vector2i.ZERO)).distance_to(Vector2(weg.get("nach", Vector2i.ZERO)))
		if dist < kuerzeste:
			kuerzeste = dist
	return kuerzeste

func _verbindet(weg: Dictionary, von_map_id: String, nach_map_id: String) -> bool:
	var weg_von_id := str(weg.get("von_id", ""))
	var weg_nach_id := str(weg.get("nach_id", ""))
	if _paar(weg_von_id, weg_nach_id, von_map_id, nach_map_id):
		return true
	# Auch die Spieler-Startregion gilt als verbunden.
	return _paar(weg_von_id, weg_nach_id, "spieler", nach_map_id)

func _paar(a: String, b: String, erste: String, zweite: String) -> bool:
	return (a == erste and b == zweite) or (a == zweite and b == erste)
