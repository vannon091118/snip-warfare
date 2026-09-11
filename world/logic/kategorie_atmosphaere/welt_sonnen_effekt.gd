extends CanvasLayer
class_name Welt_SonnenEffekt
## Stilisierte Bilderbuch-Sonne: gezeichnete Streifen in einem Winkel, die
## nur bei Tageslicht sichtbar sind. Liest die Tageszyklus-Maschine und den
## Atmosphaeren-Pool; keine Lichtberechnung, keine zweite Zeitquelle.

## Kategorie daten: Pool, Maschine und der gezeichnete Streifen-Layer.
var _konfig: Welt_AtmosphaereKonfig = null
var _sonnen_shader: Shader = null

## Der Sonnen-Shader-Text wird einmal zu einer echten Shader-Instanz
## gebacken, damit alle Materialien dieselbe Instanz teilen.
func sonnen_shader_instanz() -> Shader:
	if _sonnen_shader == null:
		_sonnen_shader = Shader.new()
		_sonnen_shader.code = SONNEN_SHADER_TEXT
	return _sonnen_shader
var _zyklus: Welt_TageszyklusMaschine = null
var _farbe: ColorRect = null
var _alpha: float = 0.0
var _ziel_alpha: float = 0.0

## Kategorie logik: Aufbau und reine Beobachtung der Tagesphase.

func einrichten(konfig: Welt_AtmosphaereKonfig, zyklus: Welt_TageszyklusMaschine) -> void:
	_konfig = konfig
	_zyklus = zyklus
	layer = 15
	if _zyklus != null:
		_zyklus.phase_geaendert.connect(_auf_phase)
		_ziel_alpha = _sichtbarkeit_fuer(_zyklus.phase())

func _ready() -> void:
	var halter := Control.new()
	halter.set_anchors_preset(Control.PRESET_FULL_RECT)
	halter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(halter)
	_farbe = ColorRect.new()
	_farbe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_farbe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var winkel := 0.0
	if _konfig != null:
		winkel = _konfig.sonne_wert("strequahlen_winkel_grad", 18.0)
	var streifen := ShaderMaterial.new()
	streifen.shader = sonnen_shader_instanz()
	streifen.set_shader_parameter("winkel", deg_to_rad(winkel))
	streifen.set_shader_parameter("farbe", _farbe_fuer_phase())
	streifen.set_shader_parameter("alpha", 0.0)
	streifen.set_shader_parameter("skala", _konfig.sonne_wert("streifenskala", 4.0) if _konfig != null else 4.0)
	_farbe.material = streifen
	halter.add_child(_farbe)

func farbe_setzen(farbe: Color) -> void:
	if _farbe != null and _farbe.material != null:
		(_farbe.material as ShaderMaterial).set_shader_parameter("farbe", farbe)

func _farbe_fuer_phase() -> Color:
	if _konfig == null or _zyklus == null:
		return Color.from_string("#FFF3C9", Color(1.0, 0.95, 0.79))
	match _zyklus.phase():
		Welt_TageszyklusMaschine.Phase.MORGEN:
			return _konfig.sonne_farbe("morgen_farbe", Color.from_string("#FFE0A8", Color(1.0, 0.88, 0.66)))
		Welt_TageszyklusMaschine.Phase.DAEMMERUNG:
			return _konfig.sonne_farbe("abend_farbe", Color.from_string("#E8A86B", Color(0.91, 0.66, 0.42)))
		_:
			return _konfig.sonne_farbe("tag_farbe", Color.from_string("#FFF3C9", Color(1.0, 0.95, 0.79)))

func _sichtbarkeit_fuer(phase: int) -> float:
	# Nur Tag und Morgen tragen Streifen; Daemmerung und Nacht ziehen sie ab.
	if _zyklus == null:
		return 0.0
	if phase == Welt_TageszyklusMaschine.Phase.TAG:
		return 1.0
	if phase == Welt_TageszyklusMaschine.Phase.MORGEN:
		return 0.7
	if phase == Welt_TageszyklusMaschine.Phase.DAEMMERUNG:
		return 0.3
	return 0.0

func _auf_phase(_neue_phase: int, _helligkeit: float) -> void:
	if _zyklus == null:
		return
	_ziel_alpha = _sichtbarkeit_fuer(_zyklus.phase())
	if _farbe != null and _farbe.material != null:
		(_farbe.material as ShaderMaterial).set_shader_parameter("farbe", _farbe_fuer_phase())

func _process(delta: float) -> void:
	# Sanftes Interpolieren des Streifen-Alpha: Uebergang ohne harten Schnitt.
	if _farbe == null or _farbe.material == null:
		return
	var nacht_dampfer := 1.0
	if _zyklus != null and _zyklus.is_nacht():
		nacht_dampfer = _konfig.sonne_wert("nacht_alpha_faktor", 0.2) if _konfig != null else 0.2
	_alpha = lerpf(_alpha, _ziel_alpha * nacht_dampfer, clampf(delta * 2.0, 0.0, 1.0))
	(_farbe.material as ShaderMaterial).set_shader_parameter("alpha", _alpha * _max_alpha())

func _max_alpha() -> float:
	return _konfig.sonne_wert("max_alpha", 0.1) if _konfig != null else 0.1

const SONNEN_SHADER_TEXT := "
shader_type canvas_item;
uniform float winkel = 0.314;
uniform vec4 farbe : source_color = vec4(1.0, 0.95, 0.79, 1.0);
uniform float alpha = 0.0;
uniform float skala = 4.0;

void fragment() {
	// Rotierte Koordinaten erzeugen schraege Streifen mit weichem Rand.
	float rotierte_y = UV.y * cos(winkel) + UV.x * sin(winkel);
	float streifen = sin(rotierte_y * skala * 3.14159);
	float maske = smoothstep(0.55, 1.0, streifen);
	COLOR = vec4(farbe.rgb, alpha * maske);
}
"
