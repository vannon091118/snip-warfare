extends RefCounted
class_name Welt_SwayAktualisierer
## Pflegt die Wind-Sway-Materials der Objekt-Sprites: Fuer jedes Sprite mit
## freigeschaltetem Katalog-Eintrag (wind_sway) wird ein Material erzeugt,
## am Sprite gesetzt und im eigenen Nachweis registriert. Der Renderer ruft
## nur sprite_verwenden und aktualisieren; die Shader-Details liegen in der
## Welt_SwayMaterial-Spitze der Atmosphaeren-Domaene. Keine eigene Zeit.

## Kategorie daten: der gepflegte Material-Nachweis je Sprite-Instanz.
var _materials: Array[Dictionary] = []
var _sway: Welt_SwayMaterial = null

## Kategorie logik: Material setzen, sammeln und je Tick aktualisieren.

func einrichten(sway: Welt_SwayMaterial) -> void:
	_sway = sway
	_materials.clear()

## Erzeugt und setzt das Sway-Material am Sprite, wenn der Katalog-Eintrag
## wind_sway traegt; ohne Feld bleibt das Sprite unberuehrt und statisch.
func sprite_verwenden(sprite: Sprite2D, objekt: Objekt_Basis) -> void:
	if _sway == null or sprite == null or objekt == null:
		return
	var material := _sway.material_fuer(objekt)
	if material == null:
		return
	sprite.material = material
	_materials.append({"material": material, "sprite": sprite, "objekt": objekt})

func anzahl() -> int:
	return _materials.size()

## Setzt Staerke und Phase je Material: Die raeumliche Variation kommt aus
## der Weltposition, damit Baeume und Buesche versetzt wedeln.
func aktualisieren(wind_staerke: float, phase: float) -> void:
	if _sway == null:
		return
	for eintrag: Dictionary in _materials:
		var sprite := eintrag["sprite"] as Sprite2D
		if not is_instance_valid(sprite):
			continue
		var objekt := eintrag["objekt"] as Objekt_Basis
		var material := eintrag["material"] as ShaderMaterial
		var lokal_x := sprite.global_position.x if sprite.is_inside_tree() else sprite.position.x
		material.set_shader_parameter("phase", phase + lokal_x * 0.02)
		material.set_shader_parameter("staerke", _sway.staerke_fuer(objekt, wind_staerke))
