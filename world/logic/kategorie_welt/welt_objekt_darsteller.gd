extends RefCounted
class_name Welt_ObjektDarsteller
## Übersetzt einen Katalog-Eintrag mit Registry-Animation in ein fertiges
## Bewegtbild: Für jeden Eintrag mit funktions_animation entsteht ein
## AnimatedSprite2D, dessen Frames aus dem Sheet in game/data/animationen.json
## geschnitten werden. Die Geschwindigkeit läuft wie beim Einheit_Darsteller
## über die 24 Ticks der zentralen Weltuhr (24 geteilt durch ticks_pro_frame).
## Das Bewegtbild ist bereits am Fuß ausgerichtet: Seine Unterkante liegt auf
## dem Ursprung des Objekt-Knotens, in den es gehängt wird. Diese Klasse hält
## selbst keine Knoten, besitzt keine Simulationslogik und keine eigene Zeit.
## Die Registries bleiben der einzige Aktivierungspunkt: Ein Objekt ohne
## funktions_animation erhält nie ein Bewegtbild.

const ANIMATIONEN_PFAD := "res://game/data/animationen.json"
const BEEREN_OVERLAY_PFAD := "res://world/assets/terrain/busch_beeren_overlay.svg"

## Kategorie daten: die geladenen Animationseinträge je Name.
var _animationen: Dictionary = {}

## Kategorie logik: Einlesen und Bauen des Bewegtbildes.

func _init() -> void:
	var datei := FileAccess.open(ANIMATIONEN_PFAD, FileAccess.READ)
	if datei != null:
		var gelesen: Variant = JSON.parse_string(datei.get_as_text())
		if typeof(gelesen) == TYPE_DICTIONARY:
			_animationen = gelesen

func hat_bewegtbild(objekt: Objekt_Basis) -> bool:
	if objekt == null or objekt.funktions_animation == "":
		return false
	return _animationen.has(objekt.funktions_animation)

func objekt_darstellen(objekt: Objekt_Basis, fusspunkt: Vector2) -> AnimatedSprite2D:
	# Bewegtbild nur auf Anweisung der Registry: Ohne Eintrag geschieht nichts.
	# Der Fußpunkt kommt herein, weil der Knoten selbst keine Weltposition
	# mehr trägt: Er ist der Ursprung, an dem das Bewegtbild steht.
	if not hat_bewegtbild(objekt):
		return null
	var eintrag: Dictionary = _animationen[objekt.funktions_animation]
	var textur_pfad := str(eintrag.get("sheet_pfad", objekt.textur_pfad))
	if not ResourceLoader.exists(textur_pfad):
		push_warning("Animations-Sheet fehlt: %s" % textur_pfad)
		return null
	var textur: Texture2D = load(textur_pfad)
	var breite := int(eintrag.get("frame_breite", objekt.anzeige_breite))
	var hoehe := int(eintrag.get("frame_hoehe", objekt.anzeige_hoehe))
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation(objekt.funktions_animation)
	frames.set_animation_loop(objekt.funktions_animation, bool(eintrag.get("schleife", true)))
	var anzahl := maxi(int(eintrag.get("frames", 4)), 1)
	# 24 Ticks pro Sekunde sind der Standard der Weltuhr.
	frames.set_animation_speed(objekt.funktions_animation, 24.0 / float(maxi(int(eintrag.get("ticks_pro_frame", 2)), 1)))
	for frame_index in anzahl:
		var atlas := AtlasTexture.new()
		atlas.atlas = textur
		atlas.region = Rect2(float(frame_index * breite), 0.0, float(breite), float(hoehe))
		frames.add_frame(objekt.funktions_animation, atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Bewegtbild"
	sprite.sprite_frames = frames
	sprite.animation = objekt.funktions_animation
	# Fußausrichtung: Der Knoten trägt den Fußpunkt als Ursprung, deshalb
	# zeichnet das Bewegtbild mittig und um die halbe Frame-Höhe gehoben.
	sprite.centered = true
	sprite.offset = Vector2(0.0, -float(hoehe) * 0.5)
	sprite.position = Vector2.ZERO
	sprite.play(objekt.funktions_animation)
	# Beeren-Overlay für Büsche: datengetriebene Wahrscheinlichkeit aus dem Element-Katalog
	if objekt.schluessel_daten.has("beeren_wahrscheinlichkeit"):
		var chance := float(objekt.schluessel_daten.get("beeren_wahrscheinlichkeit", 0.0))
		var pos_hash := int(abs(hash(Vector2i(int(round(fusspunkt.x)), int(round(fusspunkt.y)))))) % 100
		if chance > 0.0 and ResourceLoader.exists(BEEREN_OVERLAY_PFAD):
			var overlay_sprite := _beeren_overlay(breite, hoehe, eintrag, chance, pos_hash)
			if overlay_sprite != null:
				# Das Overlay liegt auf demselben Fuß wie sein Busch.
				sprite.add_child(overlay_sprite)
	return sprite

func _beeren_overlay(breite: int, hoehe: int, eintrag: Dictionary, chance: float, pos_hash: int) -> AnimatedSprite2D:
	# Der Beerenbewuchs ist eine Datenentscheidung des Katalogs: Nur über der
	# gezogenen Wahrscheinlichkeit erscheint das zweite Blatt.
	if pos_hash >= int(chance * 100.0):
		return null
	var overlay_textur: Texture2D = load(BEEREN_OVERLAY_PFAD)
	var overlay_frames := SpriteFrames.new()
	overlay_frames.remove_animation("default")
	overlay_frames.add_animation("overlay")
	overlay_frames.set_animation_loop("overlay", bool(eintrag.get("schleife", true)))
	overlay_frames.set_animation_speed("overlay", 24.0 / float(maxi(int(eintrag.get("ticks_pro_frame", 2)), 1)))
	var anzahl := maxi(int(eintrag.get("frames", 4)), 1)
	for frame_index in anzahl:
		var overlay_atlas := AtlasTexture.new()
		overlay_atlas.atlas = overlay_textur
		overlay_atlas.region = Rect2(float(frame_index * breite), 0.0, float(breite), float(hoehe))
		overlay_frames.add_frame("overlay", overlay_atlas)
	var overlay_sprite := AnimatedSprite2D.new()
	overlay_sprite.name = "BeerenOverlay"
	overlay_sprite.sprite_frames = overlay_frames
	overlay_sprite.animation = "overlay"
	overlay_sprite.centered = true
	overlay_sprite.offset = Vector2(0.0, -float(hoehe) * 0.5)
	overlay_sprite.position = Vector2.ZERO
	overlay_sprite.play("overlay")
	return overlay_sprite
