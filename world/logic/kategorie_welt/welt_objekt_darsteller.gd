extends Node2D
class_name Welt_ObjektDarsteller
## Darstellung von Weltobjekten mit Funktions-Animation: für jeden
## Katalog-Eintrag mit Registry-Animation entsteht hier ein eigener
## AnimatedSprite2D, dessen Frames aus dem Sheet in game/data/animationen.json
## geschnitten werden. Die Geschwindigkeit läuft wie beim Einheit_Darsteller
## über die 24 Ticks der zentralen Weltuhr (24 geteilt durch ticks_pro_frame);
## diese Klasse besitzt keine Simulationslogik und keine eigene Zeit.
## Kette: Objekt_RegistryBasis (Eintrag) -> Animationseintrag -> dieser
## Darsteller -> sichtbare Bewegung. Die Registries bleiben der einzige
## Aktivierungspunkt: Ein Objekt ohne funktions_animation wird nie animiert.

const ANIMATIONEN_PFAD := "res://game/data/animationen.json"

## Kategorie daten: die geladenen Animationseinträge je Name.
var _animationen: Dictionary = {}

## Kategorie logik: Laden, Aufbau und Entfernen der Objekt-Bewegtbilder.

func _init() -> void:
	var datei := FileAccess.open(ANIMATIONEN_PFAD, FileAccess.READ)
	if datei != null:
		var gelesen: Variant = JSON.parse_string(datei.get_as_text())
		if typeof(gelesen) == TYPE_DICTIONARY:
			_animationen = gelesen

func objekt_darstellen(objekt: Objekt_Basis, welt_position: Vector2) -> void:
	# Bewegtbild nur auf Anweisung der Registry: Ohne Eintrag geschieht nichts.
	if objekt == null:
		return
	var animations_name := objekt.funktions_animation
	if animations_name == "" or not _animationen.has(animations_name):
		return
	var eintrag: Dictionary = _animationen[animations_name]
	var textur_pfad := str(eintrag.get("sheet_pfad", objekt.textur_pfad))
	if not ResourceLoader.exists(textur_pfad):
		push_warning("Animations-Sheet fehlt: %s" % textur_pfad)
		return
	var textur: Texture2D = load(textur_pfad)
	var breite := int(eintrag.get("frame_breite", objekt.anzeige_breite))
	var hoehe := int(eintrag.get("frame_hoehe", objekt.anzeige_hoehe))
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation(animations_name)
	frames.set_animation_loop(animations_name, bool(eintrag.get("schleife", true)))
	var anzahl := maxi(int(eintrag.get("frames", 4)), 1)
	# 24 Ticks pro Sekunde sind der Standard der Weltuhr.
	frames.set_animation_speed(animations_name, 24.0 / float(maxi(int(eintrag.get("ticks_pro_frame", 2)), 1)))
	for frame_index in anzahl:
		var atlas := AtlasTexture.new()
		atlas.atlas = textur
		atlas.region = Rect2(float(frame_index * breite), 0.0, float(breite), float(hoehe))
		frames.add_frame(animations_name, atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Objekt_%s_%d" % [objekt.id, get_child_count()]
	sprite.sprite_frames = frames
	sprite.animation = animations_name
	sprite.centered = false
	sprite.position = welt_position
	sprite.play(animations_name)
	# Beeren-Overlay für Büsche: datengetriebene Wahrscheinlichkeit aus dem Element-Katalog
	if objekt.schluessel_daten.has("beeren_wahrscheinlichkeit"):
		var chance := float(objekt.schluessel_daten.get("beeren_wahrscheinlichkeit", 0.0))
		var pos_hash := int(abs(hash(Vector2i(int(round(welt_position.x)), int(round(welt_position.y)))))) % 100
		var overlay_pfad := "res://world/assets/terrain/busch_beeren_overlay.svg"
		if pos_hash < int(chance * 100.0) and ResourceLoader.exists(overlay_pfad):
			var overlay_textur: Texture2D = load(overlay_pfad)
			var overlay_frames := SpriteFrames.new()
			overlay_frames.remove_animation("default")
			overlay_frames.add_animation("overlay")
			overlay_frames.set_animation_loop("overlay", bool(eintrag.get("schleife", true)))
			overlay_frames.set_animation_speed("overlay", 24.0 / float(maxi(int(eintrag.get("ticks_pro_frame", 2)), 1)))
			for frame_index in anzahl:
				var overlay_atlas := AtlasTexture.new()
				overlay_atlas.atlas = overlay_textur
				overlay_atlas.region = Rect2(float(frame_index * breite), 0.0, float(breite), float(hoehe))
				overlay_frames.add_frame("overlay", overlay_atlas)
			var overlay_sprite := AnimatedSprite2D.new()
			overlay_sprite.name = "BeerenOverlay"
			overlay_sprite.sprite_frames = overlay_frames
			overlay_sprite.animation = "overlay"
			overlay_sprite.centered = false
			overlay_sprite.position = Vector2.ZERO
			overlay_sprite.play("overlay")
			sprite.add_child(overlay_sprite)
	add_child(sprite)

func objekt_entfernen(welt_position: Vector2) -> void:
	for kind: Node in get_children():
		var sprite := kind as AnimatedSprite2D
		if sprite != null and sprite.position == welt_position:
			sprite.queue_free()
