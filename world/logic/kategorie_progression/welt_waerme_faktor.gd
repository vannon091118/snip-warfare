extends RefCounted
class_name Welt_WaermeFaktor
## Rechnet den Warmefaktor des Wachstums aus der bestehenden Tageszyklus-
## Maschine: Helligkeit 0..1 wird in einen Faktor zwischen Nacht-Minimum
## und Tag-Maximum uebersetzt. Keine zweite Zeitquelle, keine Physik.

## Kategorie daten: der geladene Progressions-Pool.
var _registry: Welt_ProgressionsRegistry = null

## Kategorie logik: Ableitung des Faktors aus Helligkeit.

func einrichten(registry: Welt_ProgressionsRegistry) -> void:
	_registry = registry

func faktor_fuer_helligkeit(helligkeit: float) -> float:
	if _registry == null:
		return 1.0
	var minimum := _registry.waerme_min_faktor()
	var maximum := _registry.waerme_max_faktor()
	var helle := clampf(helligkeit, 0.0, 1.0)
	return lerpf(minimum, maximum, helle)
