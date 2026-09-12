extends Node2D
class_name Welt_PapierLicht
## Die eine Lichtquelle der Papierwelt: Ein warmes gerichtetes Licht wirft
## weiche Schatten der Scherenschnitt-Lagen auf den Tisch. Genau eine
## Verantwortung: Das Licht halten und seine Energie und Farbe der
## Tagesphase folgen lassen. Keine Simulationslogik, keine zweite Zeit;
## der Takt kommt ausschliesslich von der Tageszyklus-Maschine.

## Kategorie daten: der Pool und die Licht-Knoten.
var _konfig: Welt_AtmosphaereKonfig = null
var _zyklus: Welt_TageszyklusMaschine = null
var _licht: DirectionalLight2D = null

## Kategorie logik: Aufbau und Beobachtung der Tagesphase.

func einrichten(konfig: Welt_AtmosphaereKonfig, zyklus: Welt_TageszyklusMaschine) -> void:
	_konfig = konfig
	_zyklus = zyklus
	if _zyklus != null and _zyklus.has_signal("phase_geaendert"):
		_zyklus.phase_geaendert.connect(_auf_phase)
		_anwenden()

func _ready() -> void:
	_licht = DirectionalLight2D.new()
	_licht.name = "PapierSonne"
	var grad := 135.0
	var schatten_an := true
	if _konfig != null:
		grad = _konfig.papier_licht_wert("richtung_grad", grad)
		schatten_an = _konfig.papier_licht_wert("schatten_aktiv", 1.0) > 0.5
	# Der Winkel dreht die Lichtrichtung: 135 Grad fällt von oben links
	# nach unten rechts, die Bilderbuch-Beleuchtung des Banners.
	_licht.rotation = deg_to_rad(grad)
	_licht.shadow_enabled = schatten_an
	_licht.shadow_filter = DirectionalLight2D.SHADOW_FILTER_PCF5
	_licht.shadow_filter_smooth = 2.0
	var schatten_farbe := Color("#1C1A2659")
	if _konfig != null:
		schatten_farbe = _konfig.papier_licht_farbe("schatten_farbe", schatten_farbe)
	_licht.shadow_color = schatten_farbe
	add_child(_licht)
	_anwenden()

func _auf_phase(_neue_phase: int, _helligkeit: float) -> void:
	_anwenden()

## Energie und Farbe je Tagesphase, alle Zahlen aus dem Pool.
func _anwenden() -> void:
	if _licht == null:
		return
	var energie := 1.15
	var farbe := Color("#FFF3D8")
	if _konfig != null and _zyklus != null:
		match _zyklus.phase():
			Welt_TageszyklusMaschine.Phase.MORGEN:
				energie = _konfig.papier_licht_wert("energie_morgen", 0.9)
				farbe = _konfig.papier_licht_farbe("morgen_farbe", farbe)
			Welt_TageszyklusMaschine.Phase.DAEMMERUNG:
				energie = _konfig.papier_licht_wert("energie_daemmerung", 0.55)
				farbe = _konfig.papier_licht_farbe("daemmerung_farbe", farbe)
			Welt_TageszyklusMaschine.Phase.NACHT:
				energie = _konfig.papier_licht_wert("energie_nacht", 0.3)
				farbe = _konfig.papier_licht_farbe("nacht_farbe", farbe)
			_:
				energie = _konfig.papier_licht_wert("energie_tag", 1.15)
				farbe = _konfig.papier_licht_farbe("tag_farbe", farbe)
	_licht.energy = energie
	_licht.color = farbe
