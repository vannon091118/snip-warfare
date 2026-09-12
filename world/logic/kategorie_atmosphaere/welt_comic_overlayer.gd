extends Node2D
class_name Welt_ComicOverlayer
## Gezeichnete Overlay-Ebene ueber der Welt: fliegende Blaetter, Windlinien
## und Pollen. Die Ebene liest den Tick der zentralen Weltuhr und den
## Wind-Rechner; sie besitzt keine eigene Zeit und veraendert keine
## Spielmechanik. Partikel sind wiederverwendete Sprites aus einem Pool,
## damit die Menge konstant bleibt.

## Kategorie daten: Konfiguration, Wind und die gepoolten Teilchen.
const BLATT := preload("res://world/assets/atmosphaere/blatt.svg")
const WINDLINIE := preload("res://world/assets/atmosphaere/windlinie.svg")
const POLLEN := preload("res://world/assets/atmosphaere/pollen.svg")

var _konfig: Welt_AtmosphaereKonfig = null
var _wind: Welt_WindRechner = null
var _blaetter: Array[Sprite2D] = []
var _windlinien: Array[Sprite2D] = []
var _pollen: Array[Sprite2D] = []
var _bereich: float = 640.0
var _center := Vector2.ZERO

## Kategorie logik: Aufbau des Pools und deterministische Bewegung je Tick.

func einrichten(konfig: Welt_AtmosphaereKonfig, wind: Welt_WindRechner, center: Vector2, bereich: float) -> void:
	_konfig = konfig
	_wind = wind
	_center = center
	_bereich = bereich
	z_index = 90
	_pool_aufbauen()

func bereich_setzen(center: Vector2, bereich: float) -> void:
	_center = center
	_bereich = bereich

func _zufalls_feld(seed_feld: int) -> float:
	# Deterministische Streuung ohne eigenen RNG: schieberegister-artiger
	# Hash, jeder Pool-Eintrag bekommt seinen ortsfesten Anteil.
	var wert := sin(float(seed_feld) * 12.9898) * 43758.5453
	return wert - floorf(wert)

func _pool_aufbauen() -> void:
	if _konfig == null:
		return
	var blatt_zahl := _konfig.blatt_anzahl()
	var linien_zahl := _konfig.windlinien_anzahl()
	var pollen_zahl := _konfig.pollen_anzahl()
	for i in blatt_zahl:
		var blatt := Sprite2D.new()
		blatt.texture = BLATT
		blatt.position = _pool_position(i)
		blatt.modulate.a = 0.8 + 0.2 * _zufalls_feld(i + 17)
		add_child(blatt)
		_blaetter.append(blatt)
	for i in linien_zahl:
		var linie := Sprite2D.new()
		linie.texture = WINDLINIE
		linie.position = _pool_position(i + 100)
		linie.modulate.a = 0.35 + 0.3 * _zufalls_feld(i + 41)
		add_child(linie)
		_windlinien.append(linie)
	for i in pollen_zahl:
		var punkt := Sprite2D.new()
		punkt.texture = POLLEN
		punkt.position = _pool_position(i + 200)
		add_child(punkt)
		_pollen.append(punkt)

func _pool_position(index: int) -> Vector2:
	var x := _center.x + (_zufalls_feld(index + 3) * 2.0 - 1.0) * _bereich
	var y := _center.y + (_zufalls_feld(index + 5) * 2.0 - 1.0) * _bereich
	return Vector2(x, y)

func auf_tick(tick_nummer: int) -> void:
	if _wind == null or _konfig == null:
		return
	## Slice A: Partikelgruppen werden nur alle N Ticks bewegt, nicht bei
	## jedem der 24 Weltuhr-Ticks. Die Intervalle kommen aus dem Budget-Pool
	## in atmosphaere.json – kein harter Wert hier.
	var blatt_intervall := maxi(int(_konfig.budget_wert("blaetter_tick_intervall", 3.0)), 1)
	var linien_intervall := maxi(int(_konfig.budget_wert("windlinien_tick_intervall", 6.0)), 1)
	var pollen_intervall := maxi(int(_konfig.budget_wert("partikel_tick_intervall", 3.0)), 1)
	var staerke := _wind.staerke()
	var richtung := _wind.richtung()
	var zeit := float(tick_nummer)
	if tick_nummer % blatt_intervall == 0:
		for i in _blaetter.size():
			var blatt := _blaetter[i]
			var base_x := _center.x + (_zufalls_feld(i + 3) * 2.0 - 1.0) * _bereich
			var base_y := _center.y + (_zufalls_feld(i + 5) * 2.0 - 1.0) * _bereich
			var eigen := _zufalls_feld(i + 31) * ZWEI_PI
			blatt.position.x = base_x + richtung * staerke * 60.0 * (0.5 + 0.5 * sin(zeit * 0.02 + eigen))
			blatt.position.y = base_y + staerke * 18.0 * sin(zeit * 0.013 + eigen * 2.0)
			blatt.rotation = 0.6 * sin(zeit * 0.017 + eigen) * staerke * 3.0
	if tick_nummer % linien_intervall == 0:
		for i in _windlinien.size():
			var linie := _windlinien[i]
			var linie_x := _center.x + (_zufalls_feld(i + 103) * 2.0 - 1.0) * _bereich
			var linie_y := _center.y + (_zufalls_feld(i + 107) * 2.0 - 1.0) * _bereich
			linie.position.x = linie_x + richtung * staerke * 90.0 * sin(zeit * 0.01 + float(i))
			linie.position.y = linie_y + 8.0 * sin(zeit * 0.008 + float(i) * 1.7)
			linie.modulate.a = clampf(0.2 + staerke * 0.8, 0.1, 0.7)
	if tick_nummer % pollen_intervall == 0:
		for i in _pollen.size():
			var punkt := _pollen[i]
			punkt.position.x = _center.x + (_zufalls_feld(i + 203) * 2.0 - 1.0) * _bereich + richtung * staerke * 24.0 * sin(zeit * 0.011 + float(i))
			punkt.position.y = base_y_fuer(i) + _steig_fuer(i, zeit)


func _steig_fuer(index: int, zeit: float) -> float:
	var hoehe := _konfig.partikel_wert("pollen_bereich_px", 640.0)
	var steig := _konfig.partikel_wert("pollen_steig_px_pro_tick", 0.14) * 24.0
	var roh := fmod(base_y_fuer(index) - zeit * steig, hoehe)
	return roh if roh <= 0.0 else roh - hoehe

func base_y_fuer(index: int) -> float:
	return _center.y + (_zufalls_feld(index + 209) * 2.0 - 1.0) * _bereich

const ZWEI_PI := 6.283185307179586
