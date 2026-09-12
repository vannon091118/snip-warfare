extends AnimatedSprite2D
class_name Einheit_Darsteller
## Darstellung eines Strichmännchens. Die Animationen werden aus den zentralen
## Sheets in game/data/animationen.json geschnitten; Logik liegt in
## Einheit_Status, die Position legt ausschließlich der Spieler fest.

var _status: Einheit_Status
var _animationen: Dictionary = {}
var _frames_fertig: bool = false

func einrichten(status: Einheit_Status, animationen_pfad: String = "res://game/data/animationen.json") -> void:
	_status = status
	var datei := FileAccess.open(animationen_pfad, FileAccess.READ)
	if datei != null:
		var gelesen: Variant = JSON.parse_string(datei.get_as_text())
		if typeof(gelesen) == TYPE_DICTIONARY:
			_animationen = gelesen
	_baue_frames()
	if _status != null:
		_status.zustand_geaendert.connect(_auf_zustand)
		_wende_richtung(_status.blick_richtung_rechts())

func _baue_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animations_name: String in _animationen.keys():
		var daten: Dictionary = _animationen[animations_name]
		if not frames.has_animation(animations_name):
			frames.add_animation(animations_name)
		frames.set_animation_loop(animations_name, bool(daten.get("schleife", true)))
		var anzahl := maxi(int(daten.get("frames", 4)), 1)
		var ticks_pro_frame := maxi(int(daten.get("ticks_pro_frame", 2)), 1)
		# 24 Ticks pro Sekunde sind der Standard der Weltuhr.
		frames.set_animation_speed(animations_name, 24.0 / float(ticks_pro_frame))
		var textur_pfad := str(daten.get("sheet_pfad", ""))
		var textur: Texture2D = load(textur_pfad) if ResourceLoader.exists(textur_pfad) else null
		if textur == null:
			push_warning("Animations-Sheet fehlt: %s" % textur_pfad)
			continue
		var breite := int(daten.get("frame_breite", 48))
		var hoehe := int(daten.get("frame_hoehe", 64))
		for frame_index in anzahl:
			var atlas := AtlasTexture.new()
			atlas.atlas = textur
			atlas.region = Rect2(frame_index * breite, 0, breite, hoehe)
			frames.add_frame(animations_name, atlas)
	sprite_frames = frames
	_frames_fertig = true
	centered = true
	var standard_hoehe := 64.0
	for daten: Dictionary in _animationen.values():
		if daten.has("frame_hoehe"):
			standard_hoehe = float(daten["frame_hoehe"])
			break
	offset = Vector2(0.0, -standard_hoehe * 0.5)

func animation_setzen(animations_name: String) -> void:
	if not _frames_fertig:
		return
	if sprite_frames != null and sprite_frames.has_animation(animations_name):
		animation = animations_name
		play()
	else:
		push_warning("Unbekannte Animation: %s" % animations_name)

func _wende_richtung(rechts: bool) -> void:
	flip_h = not rechts

func _auf_zustand(_neuer_zustand: Einheit_Status.Zustand) -> void:
	if _status != null:
		animation_setzen(_status.animation())
		_wende_richtung(_status.blick_richtung_rechts())

var _markierung: Node2D = null
const _MarkierungSkript := preload("res://ui/logic/kategorie_ui/ui_auswahl_markierung.gd")

func markierung_setzen(sichtbar: bool) -> void:
	if _markierung == null and sichtbar:
		_markierung = _MarkierungSkript.new()
		add_child(_markierung)
	if _markierung != null:
		(_markierung as Variant).aktiv_setzen(sichtbar)
