extends RefCounted
class_name Welt_SwayMaterial
## Erzeugt das Wind-Sway-ShaderMaterial fuer Registry-Eintraege und pflegt
## die Material-Werte aus dem Wind-Rechner. Die Klasse liest den Katalog-
## Eintrag (schluessel_daten) und den Atmosphaeren-Pool; der Renderer ruft
## sie nur auf und kennt die Shader-Details nicht.

## Kategorie daten: Pool-Zugriff und der geteilte Shader-Text.
var _konfig: Welt_AtmosphaereKonfig = null
var _shader: Shader = null

## Kategorie logik: Material bauen; Bewegung und Wind rechnet der Shader.

## Der Shader holt die Bewegung aus TIME und den Wind aus Konfig-Uniforms:
## Kein CPU-Update je Tick, keine Materialliste, kein zweiter Takt. Die
## Konfig-Werte werden einmal je Material gesetzt, die Objekt-Wucht und der
## Orts-Versatz kommen als statische Uniforms dazu.
const SWAY_SHADER_TEXT := "
shader_type canvas_item;
uniform float staerke = 0.0;
uniform float schwingung = 0.008;
uniform float phase_versatz = 0.0;
uniform float wind_minimum = 0.15;
uniform float wind_spanne = 0.45;
uniform float wind_frequenz = 0.07;

void vertex() {
	// Der Stamm bleibt stehen, die Spitze wiegt sich: Der Ausschlag waechst
	// mit der Hoehe der Textur. Die Zeit liefert die Engine, der Wind folgt
	// derselben deterministischen Welle wie der Wind-Rechner des Overlays.
	float gewicht = VERTEX.y / max(1.0, 160.0);
	float wind = wind_minimum + wind_spanne * (0.5 + 0.5 * sin(TIME * 6.2831853 * wind_frequenz * 24.0));
	VERTEX.x += sin(TIME * 1.8 + phase_versatz + VERTEX.y * schwingung) * wind * staerke * gewicht * -6.0;
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
## Alle Uniforms werden genau hier gesetzt; der Lauf braucht kein Update.
func material_fuer(objekt: Objekt_Basis, lokal_x: float = 0.0) -> ShaderMaterial:
	if objekt == null or not bool(objekt.schluessel_daten.get("wind_sway", false)):
		return null
	var material := ShaderMaterial.new()
	material.shader = shader_instanz()
	var wucht := float(objekt.schluessel_daten.get("wind_sway_wucht", 1.0))
	var richtung_zeichen := 1.0 if int(objekt.schluessel_daten.get("wind_sway_richtung", 1)) >= 0 else -1.0
	material.set_shader_parameter("staerke", wucht * richtung_zeichen)
	material.set_shader_parameter("schwingung", float(objekt.schluessel_daten.get("wind_sway_schwingung", 0.008)))
	material.set_shader_parameter("phase_versatz", lokal_x * 0.02)
	material.set_shader_parameter("wind_minimum", _konfig.wind_wert("mindest_staerke", 0.15) if _konfig != null else 0.15)
	material.set_shader_parameter("wind_spanne", _konfig.wind_wert("staerke_spanne", 0.45) if _konfig != null else 0.45)
	material.set_shader_parameter("wind_frequenz", _konfig.wind_wert("rausch_frequenz", 0.07) if _konfig != null else 0.07)
	return material
