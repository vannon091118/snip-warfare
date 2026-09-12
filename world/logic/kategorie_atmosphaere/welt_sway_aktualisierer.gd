extends RefCounted
class_name Welt_SwayAktualisierer
## Freischalt-Spitze der Sway-Materials: Fuer jedes Sprite mit
## freigeschaltetem Katalog-Eintrag (wind_sway) wird ein Material erzeugt
## und am Sprite gesetzt. Bewegung und Wind rechnet der Shader selbst aus
## TIME und Konfig-Uniforms; es gibt kein CPU-Update je Tick und keine
## Materialliste mehr. Der Renderer ruft nur sprite_verwenden.

## Kategorie logik: Material setzen und Lauf-Auskunft.

var _sway: Welt_SwayMaterial = null

func einrichten(sway: Welt_SwayMaterial) -> void:
	_sway = sway

## Erzeugt und setzt das Sway-Material am Sprite, wenn der Katalog-Eintrag
## wind_sway traegt; ohne Feld bleibt das Sprite unberuehrt und statisch.
## Der Orts-Versatz kommt aus der Weltposition, damit Baeume versetzt wedeln.
func sprite_verwenden(sprite: Sprite2D, objekt: Objekt_Basis) -> void:
	if _sway == null or sprite == null or objekt == null:
		return
	var material := _sway.material_fuer(objekt, _lokal_x_von(sprite))
	if material == null:
		return
	sprite.material = material

func _lokal_x_von(sprite: Sprite2D) -> float:
	return sprite.global_position.x if sprite.is_inside_tree() else sprite.position.x
