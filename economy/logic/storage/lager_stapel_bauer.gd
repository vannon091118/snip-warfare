extends RefCounted
class_name Lager_StapelBauer
## Bau-Spitze des Lager-Darstellers: Errichtet und räumt den Sprite-Stapel
## einer Ressource samt Mengen-Label ab. Genau eine Verantwortung: Bilder
## stapeln und zahlen. Kein Bus, kein Lager-Wissen; der Darsteller reicht
## nur Container und Werte herein.

## Deckel und Raster des Stapels.
const MAX_ICONS := 5
const ICON_ABSTAND := 18.0
const STAPEL_VERSATZ_Y := -24.0

## Kategorie daten: Behälter und Bücher des Stapels.
var _container: Node2D = null
var _sprites: Dictionary = {}
var _labels: Dictionary = {}

func _init(container: Node2D) -> void:
	_container = container

## Kategorie logik: Aufbau und Abbau des Stapels.

func anzeigen_aktualisieren(ressource_id: String, menge: int, icon_pfad: String) -> void:
	if menge <= 0:
		ressource_entfernen(ressource_id)
		return
	var textur: Texture2D = null
	if icon_pfad != "" and ResourceLoader.exists(icon_pfad):
		textur = load(icon_pfad)
	if textur == null:
		return
	# Ein ungetypter Array laesst sich nicht auf Array[Sprite2D] umtypen; die
	# Stapel-Liste wird deshalb elementweise uebernommen. Vorher brach hier
	# jeder Lager-Aufbau mit einem Laufzeitfehler ab.
	var sprites: Array[Sprite2D] = []
	for eintrag: Variant in (_sprites.get(ressource_id, []) as Array):
		if eintrag is Sprite2D:
			sprites.append(eintrag)
	var ziel := mini(menge, MAX_ICONS)
	while sprites.size() < ziel:
		var sprite := Sprite2D.new()
		sprite.texture = textur
		sprite.scale = Vector2(0.5, 0.5)
		_container.add_child(sprite)
		sprites.append(sprite)
	while sprites.size() > ziel:
		var entfernte_flaeche: Sprite2D = sprites.pop_back()
		entfernte_flaeche.queue_free()
	var start_x := -((ziel - 1) * ICON_ABSTAND) * 0.5
	for i in ziel:
		var gestapelt: Sprite2D = sprites[i]
		gestapelt.position = Vector2(start_x + i * ICON_ABSTAND, STAPEL_VERSATZ_Y)
		gestapelt.z_index = i
	_sprites[ressource_id] = sprites
	_label_pflegen(ressource_id, menge, ziel, start_x)

func _label_pflegen(ressource_id: String, menge: int, ziel: int, start_x: float) -> void:
	var label: Label = _labels.get(ressource_id, null) as Label
	if label == null:
		label = Label.new()
		label.name = "Anzahl_%s" % ressource_id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
		_container.add_child(label)
		_labels[ressource_id] = label
	if menge > MAX_ICONS:
		label.text = "x%d" % menge
		label.position = Vector2(start_x + ziel * ICON_ABSTAND + 12.0, STAPEL_VERSATZ_Y - 4.0)
		label.visible = true
	else:
		label.visible = false

func ressource_entfernen(ressource_id: String) -> void:
	var sprites: Array[Sprite2D] = _sprites.get(ressource_id, []) as Array[Sprite2D]
	for sprite: Sprite2D in sprites:
		if sprite.is_inside_tree():
			sprite.queue_free()
	_sprites.erase(ressource_id)
	var label: Label = _labels.get(ressource_id, null) as Label
	if label != null and label.is_inside_tree():
		label.queue_free()
	_labels.erase(ressource_id)

func alles_entfernen() -> void:
	for sprites: Array[Sprite2D] in _sprites.values() as Array[Array]:
		for sprite: Sprite2D in sprites:
			if sprite.is_inside_tree():
				sprite.queue_free()
	_sprites.clear()
	for label: Label in _labels.values() as Array[Label]:
		if label.is_inside_tree():
			label.queue_free()
	_labels.clear()

func aktuelle_ressourcen() -> Array:
	return _sprites.keys()
