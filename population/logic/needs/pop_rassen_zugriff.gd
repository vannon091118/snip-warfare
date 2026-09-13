extends RefCounted
class_name Pop_RassenZugriff
## Geteilter Zugriffspunkt der Rassen-Registries.
## Haelt je genau eine geparste Instanz von Pop_RassenSchemaRegistry
## (rassen_schemata.json) und reicht sie an alle Lauf-Hotspots weiter.
## Damit parst ein Weltlauf seine Rassen nicht mehr je Generator und
## je Verdrahtung doppelt (192 Keimpunkte -> 384 Prints/Schemata).
## Tests leeren den Cache ueber leeren(), frischen Stand via neu_laden().
## Wer einen frischen Stand braucht, ruft neu_laden() oder erzeugt direkt
## mit .new().

## Kategorie daten: der geteilte Cache.

static var _registry: Pop_RassenSchemaRegistry = null

## Kategorie logik: Zugriff und Pflege.

static func registry() -> Pop_RassenSchemaRegistry:
	if _registry == null:
		_registry = Pop_RassenSchemaRegistry.new()
	return _registry

static func leeren() -> void:
	_registry = null

static func neu_laden() -> void:
	leeren()
	_registry = Pop_RassenSchemaRegistry.new()
