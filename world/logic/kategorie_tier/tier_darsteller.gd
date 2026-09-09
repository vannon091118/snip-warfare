extends AnimatedSprite2D
class_name Tier_Darsteller
## Darstellung eines Tieres: schneidet die Frames aus dem Sprite-Sheet,
## spielt die Animation ab und setzt Flip sowie Verblassen um.
## Die Logik liegt in Tier_Status; diese Klasse stellt nur dar.

var status: Tier_Status
var _basis_modulate := Color(1, 1, 1, 1)
var _faehrt_aus: bool = false
var _verschwindet: bool = false
var _verschwinde_takt: float = 0.0

func einrichten(tier_id: String, verhalten: Tier_Registry, neue_status: Tier_Status) -> void:
	status = neue_status
	var pfad := verhalten.textur_pfad(tier_id)
	var groesse := verhalten.frame_groesse(tier_id)
	var quell_textur: Texture2D = load(pfad) if ResourceLoader.exists(pfad) else null
	var frames := SpriteFrames.new()
	frames.add_animation("laufen")
	frames.set_animation_speed("laufen", 10.0)
	frames.set_animation_loop("laufen", true)
	if quell_textur != null:
		for frame_index in 4:
			var atlas := AtlasTexture.new()
			atlas.atlas = quell_textur
			atlas.region = Rect2(frame_index * groesse.x, 0, groesse.x, groesse.y)
			frames.add_frame("laufen", atlas)
	sprite_frames = frames
	animation = "laufen"
	_basis_modulate = Color(1, 1, 1, 1)
	status.zustand_geaendert.connect(_auf_zustand)

func _auf_zustand(neuer_zustand: Tier_Status.Zustand) -> void:
	match neuer_zustand:
		Tier_Status.Zustand.RUHE:
			_faehrt_aus = false
			modulate = _basis_modulate
	if neuer_zustand == Tier_Status.Zustand.WEGFLIEGEN:
		speed_scale = 1.6
	elif neuer_zustand == Tier_Status.Zustand.VERFOLGEN:
		speed_scale = 1.2
	elif neuer_zustand == Tier_Status.Zustand.AUFGESCHRECKT:
		speed_scale = 2.0

func verschwinden() -> void:
	# Kurzes Ausblenden nach dem Ernten, danach Entfernen im Tick.
	_verschwindet = true
	_verschwinde_takt = 0.0

func _ready() -> void:
	# Tiere bewegen sich im Takt der globalen Weltuhr, nicht pro Frame.
	Weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	if Weltuhr.tick.is_connected(_auf_tick):
		Weltuhr.tick.disconnect(_auf_tick)

func _auf_tick(_nummer: int, delta: float) -> void:
	if status == null:
		return
	# Nach dem Ernten zügig ausblenden und sich selbst entfernen.
	if _verschwindet:
		_verschwinde_takt += delta
		modulate = Color(_basis_modulate.r, _basis_modulate.g, _basis_modulate.b, maxf(0.0, 1.0 - _verschwinde_takt / 0.25))
		if modulate.a <= 0.02:
			queue_free()
		return
	# Richtung darstellen: Flucht und Flug entgegen der Richtung, Verfolgen zum Ziel.
	if status.zustand == Tier_Status.Zustand.VERFOLGEN:
		flip_h = status.ziel_position.x < global_position.x
	else:
		flip_h = status.flucht_richtung.x < 0.0
	# Verblassen: Vögel blenden im Flug aus, sobald die Steigphase endet.
	if status.zustand == Tier_Status.Zustand.WEGFLIEGEN and status.ist_vogel():
		var tier_daten := status.verhalten.tier_daten(status.tier_id)
		var steig_anteil := 40 if tier_daten == null else tier_daten.steig_anteil_ticks
		var fade_dauer := 90 if tier_daten == null else tier_daten.fade_dauer_ticks
		if status.tick_in_zustand > steig_anteil:
			_faehrt_aus = true
			var rest := float(status.tick_in_zustand - steig_anteil)
			var anteil := clampf(rest / maxf(float(fade_dauer), 1.0), 0.0, 1.0)
			modulate = Color(_basis_modulate.r, _basis_modulate.g, _basis_modulate.b, 1.0 - anteil)
	# Nach der Fade-Phase entfernt sich der Darsteller selbst.
	if _faehrt_aus and modulate.a <= 0.02:
		queue_free()
