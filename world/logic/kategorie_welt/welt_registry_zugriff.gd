extends RefCounted
class_name Welt_RegistryZugriff
## Geteilter Zugriffspunkt der Welt-Registries.
## Haelt je genau eine geparste Instanz von Welt_Registry (element_katalog),
## Welt_GeneratorRegistry (generator_gewichte) und Welt_BiomRegistry (biome)
## und reicht sie an alle Lauf-Hotspots weiter. Damit parst ein Weltlauf
## seinen Katalog nicht mehr 108-mal (einmal je Chunk) und kein Tick baut
## die Gewichte oder Biome neu. Tests leeren den Cache ueber leeren().
## Wer einen frischen Stand braucht, ruft neu_laden() oder erzeugt direkt
## mit .new().

## Kategorie daten: der geteilte Cache.

static var _welt: Welt_Registry = null
static var _generator: Welt_GeneratorRegistry = null
static var _biom: Welt_BiomRegistry = null

## Kategorie logik: Zugriff und Pflege.

static func welt() -> Welt_Registry:
	if _welt == null:
		_welt = Welt_Registry.new()
	return _welt

static func generator() -> Welt_GeneratorRegistry:
	if _generator == null:
		_generator = Welt_GeneratorRegistry.new()
	return _generator

static func biom() -> Welt_BiomRegistry:
	if _biom == null:
		_biom = Welt_BiomRegistry.new()
	return _biom

static func leeren() -> void:
	_welt = null
	_generator = null
	_biom = null

static func neu_laden() -> void:
	leeren()
	_welt = Welt_Registry.new()
	_generator = Welt_GeneratorRegistry.new()
	_biom = Welt_BiomRegistry.new()
