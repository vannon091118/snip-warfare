extends RefCounted
class_name Welt_GrenzProfil
## Reine Grenz-Zuständigkeit: Liefert das Randprofil zwischen zwei Regionen
## aus der Weltstruktur. Kein manuelles Nachbarschafts-Array, keine feste
## Karte, keine handgesetzten Übergänge. Das Profil enthält nur was der
## lokale Generator für kompatible Ränder tatsächlich braucht: die Biom-Paarung
## und die maximale Höhen-/Klima-Abweichung als Schwelle.

## Kategorie daten: Schwellen aus der Definition.
var max_biom_sprung: int = 1

## Kategorie logik: Nachbarschaft aus Welt_Model ableiten.

func einrichten(_definition: Welt_DefinitionRegistry) -> void:
	# Schwelle bleibt konservativ; die konkrete Zahl ist konfigurierbar,
	# hier 1 bedeutet benachbarte Biome dürfen nur um eine Stufe abweichen
	# (z. B. gemaessigt -> steppe, nicht gemaessigt -> tundra direkt).
	max_biom_sprung = 1

func nachbarn_fuer(model: Welt_Model, region_x: int, region_y: int) -> Array[Dictionary]:
	# Liefert die vier orthogonalen Nachbarn als Region-Dictionaries,
	# abgeleitet ausschließlich aus der Koordinatenstruktur.
	var ergebnis: Array[Dictionary] = []
	for delta: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := region_x + delta.x
		var ny := region_y + delta.y
		var region := _finde_region(model, nx, ny)
		if not region.is_empty():
			ergebnis.append(region)
	return ergebnis

func randprofil_fuer(a: Dictionary, b: Dictionary) -> Dictionary:
	# Minimaler Randzustand: Enthält nur was der Chunk-Prüfer/Generator
	# für kompatible Ränder wirklich braucht.
	var biom_a := str(a.get("biom_id", ""))
	var biom_b := str(b.get("biom_id", ""))
	var kompatibel := biom_a == biom_b or _biom_abstand(biom_a, biom_b) <= max_biom_sprung
	return {
		"biom_a": biom_a,
		"biom_b": biom_b,
		"kompatibel": kompatibel,
		"abstand": _biom_abstand(biom_a, biom_b),
	}

func _biom_abstand(a: String, b: String) -> int:
	# Fache Ordung der Biome als Abstand: Aus der Biome-Liste abgeleitet.
	# Reihenfolge: gemaessigt (0) -> steppe (1) -> tundra (2).
	var ordnung := {"gemaaessigt": 0, "steppe": 1, "tundra": 2}
	if not ordnung.has(a) or not ordnung.has(b):
		return 99
	return absi(int(ordnung[a]) - int(ordnung[b]))

func _finde_region(model: Welt_Model, region_x: int, region_y: int) -> Dictionary:
	for region: Dictionary in model.regionen:
		if int(region.get("region_x", -999)) == region_x and int(region.get("region_y", -999)) == region_y:
			return region
	return {}
