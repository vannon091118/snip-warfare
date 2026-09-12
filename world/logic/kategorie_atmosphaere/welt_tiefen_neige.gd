extends Node2D
class_name Welt_TiefenNeige
## Die Tiefe der Papier-Lagen: Ein weicher radialer Schleier tönt den
## Kartenrand bläulich-grau, während die Kameranahme klar bleibt — dieselbe
## Luft-Perspektive wie im Banner, ohne ein einziges neues Objekt. Genau
## eine Verantwortung: Der Schleier folgt der Kamera. Keine Simulationslogik,
## keine zweite Zeit; die Position kommt vom Aufrufer je Tick.

## Kategorie daten: Pool, Schleier-Knoten und die letzte Kamerastelle.
var _konfig: Welt_AtmosphaereKonfig = null
var _schleier: Sprite2D = null
var _letzte_stelle := Vector2.ZERO
var _einmal_ankoppeln := false

## Kategorie logik: Aufbau und Kamera-Folge.

func einrichten(konfig: Welt_AtmosphaereKonfig) -> void:
	_konfig = konfig

func _ready() -> void:
	_schleier = Sprite2D.new()
	_schleier.name = "TiefenSchleier"
	_schleier.texture = _neige_bild()
	_schleier.z_index = 95
	add_child(_schleier)
	_anwenden()

## Der Schleier hängt als Kind dieser Ebene und wandert mit der Kamera;
## die Szene ruft je Takt die Kamerastelle.
func kamera_stelle(stelle: Vector2) -> void:
	_letzte_stelle = stelle
	if _schleier != null:
		_schleier.position = stelle

## Der radiale Neige-Verlauf als GradientTexture2D: Am Rand die Neige-Farbe,
## in der Mitte voll transparent. Der Radius folgt dem Sichtbereich.
func neige_radius(radius: float) -> void:
	if _schleier == null or _konfig == null:
		return
	var anteil := _konfig.tiefen_wert("radius_anteil", 0.7)
	_schleier.scale = Vector2.ONE * (radius * anteil / 256.0)

func _anwenden() -> void:
	if _schleier == null or _konfig == null:
		return
	var material := ShaderMaterial.new()
	material.shader = _neige_shader_instanz()
	material.set_shader_parameter("staerke", _konfig.tiefen_wert("staerke", 0.16))
	material.set_shader_parameter("neige_farbe", _konfig.tiefen_farbe("farbe", Color("#C3CDE2")))
	_schleier.material = material

func _neige_bild() -> Texture2D:
	var verlauf := Gradient.new()
	verlauf.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	verlauf.offsets = PackedFloat32Array([0.62, 1.0])
	var textur := GradientTexture2D.new()
	textur.gradient = verlauf
	textur.fill = GradientTexture2D.FILL_RADIAL
	textur.fill_from = Vector2(0.5, 0.5)
	textur.fill_to = Vector2(0.5, 0.0)
	textur.width = 512
	textur.height = 512
	return textur

func _neige_shader_instanz() -> Shader:
	var shader := Shader.new()
	shader.code = NEIGE_SHADER_TEXT
	return shader

const NEIGE_SHADER_TEXT := "
shader_type canvas_item;
uniform float staerke = 0.16;
uniform vec4 neige_farbe : source_color = vec4(0.76, 0.8, 0.88, 1.0);

void fragment() {
	// Der Verlauf sitzt im Alpha des Bildes: Am Rand toent, in der Mitte klar.
	COLOR = vec4(neige_farbe.rgb, neige_farbe.a * staerke * texture(TEXTURE, UV).a);
}
"
