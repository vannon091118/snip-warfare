extends RefCounted
class_name Welt_FeldAnalyser
## Verwaltet drei deterministische FastNoiseLite-Instanzen für die 2D-Weltgenerierung:
## Hoehe, Feuchtigkeit und Temperatur. Jede Instanz wird ausschliesslich ueber
## Kern_Zufall abgeleitet (keine direkte Randomisierung). Domain Warp ist fuer
## alle drei aktiviert und liest seine Amplitude aus generator_gewichte.json.
## Diese Klasse kapselt die Noise-Erzeugung; die Biom-Zuordnung erfolgt in
## Welt_BiomAnalyser.

## Kategorie daten: Drei FastNoiseLite-Instanzen und ihre Konfiguration.
var height_noise: FastNoiseLite = FastNoiseLite.new()
var moisture_noise: FastNoiseLite = FastNoiseLite.new()
var temperature_noise: FastNoiseLite = FastNoiseLite.new()

var _domain_warp_amplitude: float = 1.0
var _ist_initialisiert: bool = false

## Kategorie logik: Initialisierung und Noise-Abfrage.

func _init() -> void:
	# Standard-Konfiguration fuer alle drei Noise-Instanzen.
	# Noise-Type: OpenSimplex2 (Standard in Godot 4), Frequenz wird spaeter gesetzt.
	for noise in [height_noise, moisture_noise, temperature_noise]:
		noise.noise_type = FastNoiseLite.TYPE_OPEN_SIMPLEX_2
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 4
		noise.fractal_lacunarity = 2.0
		noise.fractal_gain = 0.5

func initialisiere(welt_seed: int, generator_gewichte: Dictionary) -> void:
	# Deterministische Seed-Ableitung fuer jede Noise-Instanz via Kern_Zufall.
	# Das zweite Argument ist ein integer-Identifikator fuer die Noise-Art.
	var height_id := int(Kern_Hash.wort("hoehe") & 0x7FFFFFFFFFFFFFFF)
	var moisture_id := int(Kern_Hash.wort("feuchtigkeit") & 0x7FFFFFFFFFFFFFFF)
	var temperature_id := int(Kern_Hash.wort("temperatur") & 0x7FFFFFFFFFFFFFFF)

	var height_kern := Kern_Zufall.abgeleitet_fuer(welt_seed, height_id)
	var moisture_kern := Kern_Zufall.abgeleitet_fuer(welt_seed, moisture_id)
	var temperature_kern := Kern_Zufall.abgeleitet_fuer(welt_seed, temperature_id)

	# Nutze die erste generierte Zahl jeder Folge als FastNoiseLite Seed.
	height_noise.seed = height_kern.naechste_zahl()
	moisture_noise.seed = moisture_kern.naechste_zahl()
	temperature_noise.seed = temperature_kern.naechste_zahl()

	# Domain Warp aktivieren und Amplitude aus Konfiguration lesen.
	_domain_warp_amplitude = 1.0
	if generator_gewichte.has("domain_warp_amplitude"):
		_domain_warp_amplitude = float(generator_gewichte["domain_warp_amplitude"])

	height_noise.domain_warp_enabled = true
	height_noise.domain_warp_amplitude = _domain_warp_amplitude

	moisture_noise.domain_warp_enabled = true
	moisture_noise.domain_warp_amplitude = _domain_warp_amplitude

	temperature_noise.domain_warp_enabled = true
	temperature_noise.domain_warp_amplitude = _domain_warp_amplitude

	_ist_initialisiert = true

func get_noise_2d(x: int, y: int, noise_art: String) -> float:
	# Gibt einen normalisierten Noise-Wert (-1 bis 1) fuer die gegebene
	# Tile-Position und Noise-Art zurueck.
	if not _ist_initialisiert:
		push_warning("Generator_Felder nicht initialisiert: initialisiere() aufrufen.")
		return 0.0
	match noise_art:
		"hoehe":
			return height_noise.get_noise_2d(x, y)
		"feuchtigkeit":
			return moisture_noise.get_noise_2d(x, y)
		"temperatur":
			return temperature_noise.get_noise_2d(x, y)
		_:
			return 0.0

func generiere_raster(breite: int, hoehe: int, noise_art: String) -> Array[float]:
	# Erzeugt ein flaches Array mit Noise-Werten fuer jede Kachel der
	# gegebenen Groesse. Index-Berechnung: y * breite + x.
	var raster: Array[float] = []
	raster.resize(breite * hoehe)
	for y in range(hoehe):
		for x in range(breite):
			var index := y * breite + x
			raster[index] = get_noise_2d(x, y, noise_art)
	return raster

func generiere_alle_raster(breite: int, hoehe: int) -> Dictionary:
	# Erzeugt alle drei Raster in einem Durchlauf zurueck.
	return {
		"hoehe": generiere_raster(breite, hoehe, "hoehe"),
		"feuchtigkeit": generiere_raster(breite, hoehe, "feuchtigkeit"),
		"temperatur": generiere_raster(breite, hoehe, "temperatur"),
	}
