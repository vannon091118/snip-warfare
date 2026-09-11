extends RefCounted
class_name Welt_TerrainBlatt
## Blatt der Terrain-Kacheln: die einzige Stelle, die aus den Daten der
## Kachel (Objekt_Kachel) und der Kachel-Koordinate die sichtbare Variante
## ableitet (Spiegelung und Tönung). Die Entscheidung ist deterministisch aus
## dem Welt-Seed abgeleitet, nie pro Frame gewürfelt, damit dieselbe Kachel
## an derselben Stelle immer gleich aussieht.
## Diese Klasse hält keine Texturen und keine Szene; sie liefert nur Daten für
## den Welt_Renderer. Damit bricht sie die sichtbare Tapeten-Wiederholung,
## ohne dass der Renderer selbst eine Regel erfindet.

const KACHEL_MISCHUNG := 2654435761

## Kategorie logik: Ableitung der sichtbaren Variante je Kachel.
func entscheidung_fuer(kachel: Objekt_Kachel, kachel_x: int, kachel_y: int, welt_seed: int = 0) -> Dictionary:
	var entscheidung := {
		"spiegel_x": false,
		"spiegel_y": false,
		"toenumg": Color.WHITE,
	}
	if kachel == null:
		return entscheidung
	var zahlenwert := _kachel_zahlenwert(kachel_x, kachel_y, welt_seed)
	if kachel.kachel_spiegelbar:
		entscheidung["spiegel_x"] = (zahlenwert & 1) == 1
		entscheidung["spiegel_y"] = (zahlenwert & 2) == 2
	if not kachel.kachel_toenungen.is_empty():
		var index := int(zahlenwert / 4) % kachel.kachel_toenungen.size()
		entscheidung["toenumg"] = Color.from_string(kachel.kachel_toenungen[index], Color.WHITE)
	return entscheidung

func _kachel_zahlenwert(kachel_x: int, kachel_y: int, welt_seed: int) -> int:
	# Chunk-Identität der Kachel: Koordinaten und Welt-Seed gehen in die
	# gemeinsame Zufallsquelle ein, damit die Variante ortsgebunden bleibt.
	var identitaet := ((kachel_x & 0xFFFF) << 16) | (kachel_y & 0xFFFF)
	identitaet = (identitaet * KACHEL_MISCHUNG) & 0x7FFFFFFFFFFFFFFF
	var zufall := Kern_Zufall.abgeleitet_fuer(welt_seed, identitaet)
	return zufall.naechste_zahl() & 0x7FFFFFFF
