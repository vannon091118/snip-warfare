extends Welt_ModellLeben
class_name Welt_ModellRegionen
## Vierte Stufe der Kette: Regionen als raeumliche Makrostruktur der Welt.
## Kategorie daten: Regionen, Regions-Index, Welt-Seed und Karten-Kennung.
## Kategorie logik: Ergaenzen, Suchen und die Biom-Ableitung je Kachel.

## Jede Region traegt Biom, Seed-Beitrag und Chunk-Anzahl; Chunks sind die
## technische Partition (Generator-Groesse), Objekte die konkreten Inhalte.
var regionen: Array[Dictionary] = []
var region_kante: int = 4
## Regions-Index je Regions-Koordinate: Der O(1)-Griff fuer die zehntausenden
## Abfragen des Netzwerk-Passes; wird mit regionen_leeren mitgeleert.
var _regionen_index: Dictionary = {}
var welt_seed: int = 0
## map_id: Kennung dieser Karte innerhalb einer World. Leer bedeutet, dass
## die Karte als eigenstaendige Einzelwelt gefuehrt wird (abwaertskompatibel).
var map_id: String = ""

func regionen_leeren() -> void:
	regionen.clear()
	_regionen_index.clear()

func region_ergaenzen(region_x: int, region_y: int, biom: String, seed_beitrag: int, chunk_kante: int) -> void:
	regionen.append({
		"region_x": region_x,
		"region_y": region_y,
		"biom_id": biom,
		"seed_beitrag": seed_beitrag,
		"chunk_kante": chunk_kante,
	})
	_regionen_index[Vector2i(region_x, region_y)] = regionen[regionen.size() - 1]

func region_an(position: Vector2, z_ebene: int = 0) -> Dictionary:
	# Liefert die Region der Kachel unter der Welt-Position; sonst leer.
	var kachel_x := int(position.x / float(kachel_groesse))
	var kachel_y := int(position.y / float(kachel_groesse))
	return region_an_kachel(kachel_x, kachel_y, z_ebene)

func region_an_kachel(kachel_x: int, kachel_y: int, _z_ebene: int = 0) -> Dictionary:
	# O(1)-Griff ueber den Regions-Index statt linearer Suche ueber alle
	# Regionen: Der Netzwerk-Pass fragt zehntausende Male je Weltlauf,
	# die lineare Variante machte daraus Sekunden.
	var kante := maxi(region_kante, 1)
	var regions_x := floori(float(kachel_x) / float(kante))
	var regions_y := floori(float(kachel_y) / float(kante))
	var gefunden: Variant = _regionen_index.get(Vector2i(regions_x, regions_y), null)
	if gefunden != null:
		return gefunden as Dictionary
	return {}

func biom_an_kachel(kachel_x: int, kachel_y: int, z_ebene: int = 0) -> String:
	# Einziger Ort der die Biom-Zugehoerigkeit einer Kachel ableitet:
	# Region zuerst, sonst das globale Welt-Biom.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	var region := region_an_kachel(kachel_x, kachel_y, z)
	if not region.is_empty():
		return str(region.get("biom_id", biom_id))
	return biom_id
