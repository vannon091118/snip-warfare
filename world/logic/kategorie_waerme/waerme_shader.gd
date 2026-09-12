extends RefCounted
class_name Welt_WaermeShader
## Heat-Shader: 15 Zeilen. Nimmt waerme_wert (0..1) und gibt
## warm-oranges Overlay mit Alpha = waerme_wert aus.

const SHADER_CODE: String = """
shader_type canvas_item;

uniform float waerme_wert : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec3 warm = vec3(1.0, 0.55, 0.2);
    COLOR = vec4(warm, waerme_wert);
}
"""

func shader_instanz() -> Shader:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	return shader

func material_neu() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader_instanz()
	mat.set_shader_parameter("waerme_wert", 0.0)
	return mat