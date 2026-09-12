extends CanvasLayer
class_name Welt_PapierKornEbene
## Das Papier unter allem: Der bisher ungenutzte Korn-Shader liegt als
## Vollbild-Ebene über der Welt und unter dem HUD, dazu eine sanfte
## Vignette wie am Bildrand eines Fotos. Genau eine Verantwortung: Die
## Ebene halten und ihre Stärke der Tagesphase folgen lassen. Keine
## Simulationslogik, keine zweite Zeit.

## Kategorie daten: Pool, Ebene und der gezeichnete Schleier.
var _konfig: Welt_AtmosphaereKonfig = null
var _zyklus: Welt_TageszyklusMaschine = null
var _papier: ColorRect = null

## Kategorie logik: Aufbau und reine Beobachtung der Tagesphase.

func einrichten(konfig: Welt_AtmosphaereKonfig, zyklus: Welt_TageszyklusMaschine) -> void:
	_konfig = konfig
	_zyklus = zyklus
	layer = maxi(int(_konfig.papier_wert("korn_ebene", 8.0)), 1) if _konfig != null else 8
	if _zyklus != null and _zyklus.has_signal("phase_geaendert"):
		_zyklus.phase_geaendert.connect(_auf_phase)

func _ready() -> void:
	var halter := Control.new()
	halter.set_anchors_preset(Control.PRESET_FULL_RECT)
	halter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(halter)
	_papier = ColorRect.new()
	_papier.set_anchors_preset(Control.PRESET_FULL_RECT)
	_papier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = _korn_shader_instanz()
	material.set_shader_parameter("korn", _konfig.papier_wert("korn_staerke", 0.045) if _konfig != null else 0.045)
	material.set_shader_parameter("variation", _konfig.papier_wert("farb_variation", 0.03) if _konfig != null else 0.03)
	material.set_shader_parameter("vignette", _konfig.papier_wert("vignette_staerke", 0.12) if _konfig != null else 0.12)
	material.set_shader_parameter("deckkraft", 0.0)
	_papier.material = material
	halter.add_child(_papier)
	_anwenden()

func _auf_phase(_neue_phase: int, _helligkeit: float) -> void:
	_anwenden()

## Der Shader-Text wird einmal zu einer echten Instanz gebacken, damit
## alle Materialien dieselbe Instanz teilen.
var _korn_shader: Shader = null
func _korn_shader_instanz() -> Shader:
	if _korn_shader == null:
		_korn_shader = Shader.new()
		_korn_shader.code = KORN_SHADER_TEXT
	return _korn_shader

## Die Deckkraft atmet mit der Tageszeit: Tags feines Korn, nachts etwas
## mehr Struktur, damit die Nacht nicht zu einer flachen Fläche kippt.
func _anwenden() -> void:
	if _papier == null or _papier.material == null:
		return
	var grund := _konfig.papier_wert("korn_alpha", 0.05) if _konfig != null else 0.05
	var ziel := grund
	if _zyklus != null and _zyklus.is_nacht():
		ziel = grund * 1.6
	(_papier.material as ShaderMaterial).set_shader_parameter("deckkraft", ziel)

const KORN_SHADER_TEXT := "
shader_type canvas_item;
uniform float korn = 0.045;
uniform float variation = 0.03;
uniform float vignette = 0.12;
uniform float deckkraft = 0.05;

float rauschen(vec2 punkt) {
	return fract(sin(dot(punkt, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// Vollbild-Blatt ohne TEXTURE: Das Korn lebt allein in SCREEN_UV,
	// die Vignette dunkelt den Bildrand wie bei einem alten Foto.
	float korn_wert = rauschen(floor(SCREEN_UV * 900.0));
	float unruhe = (korn_wert - 0.5) * 2.0 * korn;
	float grosse_unruhe = rauschen(floor(SCREEN_UV * 6.0));
	float tonung = (grosse_unruhe - 0.5) * 2.0 * variation;
	float rand = distance(SCREEN_UV, vec2(0.5));
	float dunkel = smoothstep(0.45, 0.95, rand) * vignette;
	vec3 papier = vec3(0.96, 0.94, 0.88) + unruhe + tonung;
	COLOR = vec4(papier, deckkraft + dunkel);
}
"
