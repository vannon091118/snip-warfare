extends Node2D
class_name Welt_AtmosphaereVerdrahtung
## Spitze der Atmosphaeren-Domaene: laedt den Pool, haelt den Wind-Rechner,
## baut die darstellenden Kinder (Overlay, Sonne, Staub) und verdrahtet sie
## an die bestehende Weltuhr und Tageszyklus-Maschine. Die Welt-Szene haengt
## nur diesen Knoten an und ruft genau zwei Methoden auf; jede Fachlogik
## bleibt hier und in den Kindern.

## Kategorie daten: Pool, Wind und die darstellenden Knoten.
const OVERLAYER_SKRIPT := preload("res://world/logic/kategorie_atmosphaere/welt_comic_overlayer.gd")
const SONNE_SKRIPT := preload("res://world/logic/kategorie_atmosphaere/welt_sonnen_effekt.gd")
const STAUB_SKRIPT := preload("res://world/logic/kategorie_atmosphaere/welt_schlag_staub.gd")

var _konfig := Welt_AtmosphaereKonfig.new()
var _wind := Welt_WindRechner.new()
var _overlayer: Welt_ComicOverlayer = null
var _sonne: Welt_SonnenEffekt = null
var _staub: Welt_SchlagStaub = null
var _sway: Welt_SwayMaterial = null
var _bereich_vorlauf: Dictionary = {}

## Kategorie logik: Aufbau und Tick-Weiterleitung an die Kinder.

func _ready() -> void:
	_konfig.laden()
	_wind.einrichten(_konfig)

func einrichten(zyklus: Welt_TageszyklusMaschine, center: Vector2, bereich: float) -> void:
	if not _bereich_vorlauf.is_empty():
		center = _bereich_vorlauf["center"]
		bereich = _bereich_vorlauf["bereich"]
	_sway = Welt_SwayMaterial.new()
	_sway.einrichten(_konfig)
	_overlayer = OVERLAYER_SKRIPT.new()
	_overlayer.name = "ComicOverlayer"
	add_child(_overlayer)
	_overlayer.einrichten(_konfig, _wind, center, bereich)
	_staub = STAUB_SKRIPT.new()
	_staub.name = "SchlagStaub"
	add_child(_staub)
	_staub.einrichten(_konfig)
	_sonne = SONNE_SKRIPT.new()
	_sonne.name = "SonnenEffekt"
	add_child(_sonne)
	_sonne.einrichten(_konfig, zyklus)

func bereich_anpassen(center: Vector2, bereich: float) -> void:
	if _overlayer != null:
		_overlayer.bereich_setzen(center, bereich)

func bereich_setzen(center: Vector2, bereich: float) -> void:
	# Wird vor add_child aufgerufen, damit der Aufbau schon die Kartenmitte
	# kennt; einrichten uebernimmt die Werte ebenfalls.
	_bereich_vorlauf = {"center": center, "bereich": bereich}

func weltuhr_verbinden() -> void:
	# Nullsichere Verbindung an den Autoload: In Headless-Testlaeufen ohne
	# Autoloads bleibt die Domäne ladbar und tut nichts.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_uhr_tick):
		weltuhr.tick.connect(_auf_uhr_tick)

func _auf_uhr_tick(tick_nummer: int, _delta: float) -> void:
	auf_weltuhr_tick(tick_nummer)

func auf_weltuhr_tick(tick_nummer: int) -> void:
	_wind.staerke_an(tick_nummer)
	if _overlayer != null:
		_overlayer.auf_tick(tick_nummer)

func staub_zeigen(welt_position: Vector2) -> void:
	if _staub != null:
		_staub.schlag_zeigen(welt_position)

func ernte_ort_melden(welt_position: Vector2) -> void:
	# Die Ernte-Maschine meldet den Ort des letzten Schlages; der Staub
	# zeigt dort seine kleine Wolke, sobald die Buchung auf der Timeline
	# erscheint. Kein neuer Signalknoten, nur eine Weiterreichung.
	if _staub != null:
		_staub.ernte_ort_setzen(welt_position)

func sway_material_quelle() -> Callable:
	return func() -> RefCounted: return _sway

func papier_material() -> ShaderMaterial:
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = papier_shader_instanz()
	shader_mat.set_shader_parameter("korn", _konfig.papier_wert("korn_staerke", 0.045))
	shader_mat.set_shader_parameter("variation", _konfig.papier_wert("farb_variation", 0.03))
	return shader_mat

## Der Papier-Shader-Text wird einmal zu einer echten Shader-Instanz
## gebacken, damit alle Materialien dieselbe Instanz teilen.
var _papier_shader: Shader = null
func papier_shader_instanz() -> Shader:
	if _papier_shader == null:
		_papier_shader = Shader.new()
		_papier_shader.code = PAPIER_SHADER_TEXT
	return _papier_shader

const PAPIER_SHADER_TEXT := "
shader_type canvas_item;
uniform float korn = 0.045;
uniform float variation = 0.03;

float rauschen(vec2 punkt) {
	return fract(sin(dot(punkt, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 basis = texture(TEXTURE, UV);
	// Feines Papierkorn: ein dunkler Fleck je Rasterzelle, ohne Kanten-Hart.
	float korn_wert = rauschen(floor(UV * 220.0));
	float unruhe = (korn_wert - 0.5) * 2.0 * korn;
	// Minimale Farbvariation ueber groessere Flecken, wie unebenmaessiges Papier.
	float grosse_unruhe = rauschen(floor(UV * 6.0));
	float tonung = (grosse_unruhe - 0.5) * 2.0 * variation;
	basis.rgb = clamp(basis.rgb + unruhe + tonung, vec3(0.0), vec3(1.0));
	COLOR = basis;
}
"
