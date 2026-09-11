extends RefCounted
class_name Welt_SwayMaterial
## Erzeugt das Wind-Sway-ShaderMaterial fuer Registry-Eintraege und pflegt
## die Material-Werte aus dem Wind-Rechner. Die Klasse liest den Katalog-
## Eintrag (schluessel_daten) und den Atmosphaeren-Pool; der Renderer ruft
## sie nur auf und kennt die Shader-Details nicht.

## Kategorie daten: Pool-Zugriff und der geteilte Shader-Text.
var _konfig: Welt_AtmosphaereKonfig = null
var _shader: Shader = null

## Kategorie logik: Material bauen und pro Tick mit Wind fuettern.

const SWAY_SHADER_TEXT := "
shader_type canvas_item;
uniform float staerke = 0.0;
uniform float phase = 0.0;
uniform float schwingung = 0.008;

void vertex() {
	// Der Stamm bleibt stehen, die Spitze wiegt sich: Der Ausschlag waechst
	// mit der Hoehe der Textur und folgt der Wind-Phase des Objekts.
	float gewicht = VERTEX.y / max(1.0, 160.0);
	VERTEX.x += sin(phase + VERTEX.y * schwingung) * staerke * gewicht * -6.0;
}
"

## Der Shader-Text wird einmal zu einer echten Shader-Instanz gebacken,
## damit alle Materialien dieselbe Instanz teilen.
func shader_instanz() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SWAY_SHADER_TEXT
	return _shader

func einrichten(konfig: Welt_AtmosphaereKonfig) -> void:
	_konfig = konfig

## Liest die Sway-Werte aus dem Katalog-Eintrag: wind_sway schaltet das
## Material frei, wind_sway_wucht gewichtet es. Ohne Feld gibt es nichts.
func material_fuer(objekt: Objekt_Basis) -> ShaderMaterial:
	if objekt == null or not bool(objekt.schluessel_daten.get("wind_sway", false)):
		return null
	var material := ShaderMaterial.new()
	material.shader = shader_instanz()
	material.set_shader_parameter("staerke", 0.0)
	material.set_shader_parameter("phase", 0.0)
	material.set_shader_parameter("schwingung", float(objekt.schluessel_daten.get("wind_sway_schwingung", 0.008)))
	return material

func staerke_fuer(objekt: Objekt_Basis, wind_staerke: float) -> float:
	if objekt == null:
		return 0.0
	var wucht := float(objekt.schluessel_daten.get("wind_sway_wucht", 1.0))
	return wind_staerke * wucht * (1.0 if int(objekt.schluessel_daten.get("wind_sway_richtung", 1)) >= 0 else -1.0)
