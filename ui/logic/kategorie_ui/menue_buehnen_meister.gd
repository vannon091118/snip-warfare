extends Node2D
class_name Menue_BuehnenMeister
## Die Buehne der Menue-Story: Sie haelt alle Figuren und Stuecke und
## fuehrt je Event genau eine Geste aus. Genau eine Verantwortung: Die
## Buehne und ihre Gesten. Keine Ablauflogik, keine Zeit; den Takt liefert
## der Regisseur von der Weltuhr, die Daten kommen aus dem Pool.

const RAHMEN_LINKS := -160.0
const RAHMEN_RECHTS := 2080.0
const FEUER_SCALE := 0.5
const BAUM_SCALE := 0.24
const HAUS_SCALE := 0.8
const FIGUR_SCALE := 1.6

## Kategorie daten: die Figuren unter ihrer Event-Nummer und der Erzaehler.
var actoren: Dictionary = {}
var unterschrift: Menue_Unterschrift = null

## Kategorie logik: Gesten je Event-Art; jede Geste ist ein kleiner Satz.

func fuehre_aus(event: Dictionary) -> void:
	match str(event.get("art", "")):
		"einritt", "siedler":
			_geste_einritt(event)
		"feuer":
			_geste_feuer(event)
		"baum":
			_geste_baum(event)
		"hase":
			_geste_hase(event)
		"vogel":
			_geste_vogel(event)
		"hacker":
			_geste_hacker(event)
		"hackt":
			_geste_hackt(event)
		"faellt":
			_geste_faellt(event)
		"flieht":
			_geste_flieht(event)
		"vannon":
			_geste_vannon(event)
		"puls":
			_geste_puls(event)
		"verbeugt":
			_geste_verbeugt(event)
		_:
			pass
	if unterschrift != null and str(event.get("text", "")) != "":
		unterschrift.zeige(str(event.get("text", "")), 96)

## Kategorie figuren: Aufbau aus den vorhandenen Papier-Sheets.

func _sheet_frames(pfad: String, frame_breite: int, animation: String, tempo: float) -> SpriteFrames:
	var textur: Texture2D = load(pfad)
	var frames := SpriteFrames.new()
	frames.add_animation(animation)
	frames.set_animation_speed(animation, tempo)
	frames.set_animation_loop(animation, true)
	if textur == null:
		return frames
	var spalten := maxi(int(floor(float(textur.get_width()) / float(frame_breite))), 1)
	for spalte in range(spalten):
		var ausschnitt := AtlasTexture.new()
		ausschnitt.atlas = textur
		ausschnitt.region = Rect2(float(spalte * frame_breite), 0.0, float(frame_breite), float(textur.get_height()))
		frames.add_frame(animation, ausschnitt)
	return frames

func _fuss(stelle: Vector2, hoehe: float) -> Vector2:
	# Die angegebene Stelle ist der Bodenkontakt; das Bild steht darueber.
	return Vector2(stelle.x, stelle.y - hoehe * 0.5)

func _aushaengen(actor: Node2D, dauer: float) -> void:
	var tween := actor.create_tween()
	tween.tween_property(actor, "modulate:a", 0.0, dauer)
	tween.tween_callback(actor.queue_free)
	actoren.erase(int(actor.get_meta("event_id", 0)))

## Gesten im Einzelnen.

func _geste_einritt(event: Dictionary) -> void:
	var figur := AnimatedSprite2D.new()
	figur.sprite_frames = _sheet_frames("res://world/assets/ui/laeufer_rechts.svg", 48, "gehen", 8.0)
	figur.animation = "gehen"
	figur.scale = Vector2.ONE * FIGUR_SCALE
	var richtung := float(event.get("richtung", 1.0))
	figur.flip_h = richtung < 0.0
	figur.position = _fuss(Vector2(RAHMEN_LINKS if richtung > 0.0 else RAHMEN_RECHTS, float(event.get("y", 900.0))), 64.0 * FIGUR_SCALE)
	_anhaengen(figur, event)
	figur.play()
	var ziel := Vector2(float(event.get("x", 900.0)), figur.position.y)
	var dauer := absf(ziel.x - figur.position.x) / 240.0
	var tween := figur.create_tween()
	tween.tween_property(figur, "position:x", ziel.x, dauer)
	if str(event.get("art", "")) == "siedler":
		tween.tween_callback(_siedler_ankommen.bind(figur, ziel))
	else:
		tween.tween_callback(figur.stop)
		tween.tween_callback(func() -> void: figur.frame = 0)

func _siedler_ankommen(figur: AnimatedSprite2D, stelle: Vector2) -> void:
	figur.stop()
	figur.frame = 0
	# Das Haus waechst aus dem Bauplan: ein Stueck Papier, das sich aufrichtet.
	var haus := Sprite2D.new()
	haus.texture = load("res://world/assets/terrain/haus.svg")
	haus.scale = Vector2.ONE * HAUS_SCALE
	haus.position = _fuss(stelle + Vector2(70.0, 0.0), 144.0 * HAUS_SCALE)
	haus.scale.y = 0.05
	haus.modulate = Color("#D8C9A8")
	haus.set_meta("event_id", -1)
	add_child(haus)
	var tween := haus.create_tween()
	tween.tween_property(haus, "scale:y", HAUS_SCALE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(haus, "modulate", Color.WHITE, 0.9)

func _geste_feuer(event: Dictionary) -> void:
	var feuer := AnimatedSprite2D.new()
	feuer.sprite_frames = _sheet_frames("res://world/assets/terrain/lagerfeuer_flackern.svg", 128, "flackern", 6.0)
	feuer.animation = "flackern"
	feuer.scale = Vector2.ONE * FEUER_SCALE
	feuer.position = _fuss(Vector2(float(event.get("x", 900.0)), float(event.get("y", 930.0))), 128.0 * FEUER_SCALE)
	_anhaengen(feuer, event)
	feuer.play()
	_staub(feuer.position + Vector2(0.0, 40.0))

func _geste_baum(event: Dictionary) -> void:
	var baum := Sprite2D.new()
	var textur: Texture2D = load("res://world/assets/progression/baum_stufe.svg")
	var stufe := maxi(int(event.get("stufe", 3)), 0)
	var ausschnitt := AtlasTexture.new()
	ausschnitt.atlas = textur
	ausschnitt.region = Rect2(float(stufe * 128), 0.0, 128.0, 512.0)
	baum.texture = ausschnitt
	baum.scale = Vector2.ONE * BAUM_SCALE
	baum.position = _fuss(Vector2(float(event.get("x", 900.0)), float(event.get("y", 870.0))), 512.0 * BAUM_SCALE)
	# Der Baum atmet hoch: aus dem Boden gewachsen statt gepoppt.
	baum.scale.y = 0.02
	_anhaengen(baum, event)
	var tween := baum.create_tween()
	tween.tween_property(baum, "scale:y", BAUM_SCALE, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _geste_hase(event: Dictionary) -> void:
	var hase := AnimatedSprite2D.new()
	hase.sprite_frames = _sheet_frames("res://world/assets/tiere/hase.svg", 32, "hoppeln", 7.0)
	hase.animation = "hoppeln"
	hase.scale = Vector2.ONE * 1.4
	var richtung := float(event.get("richtung", 1.0))
	hase.flip_h = richtung < 0.0
	var start := RAHMEN_LINKS if richtung > 0.0 else RAHMEN_RECHTS
	hase.position = _fuss(Vector2(start, float(event.get("y", 950.0))), 72.0 * 1.4)
	_anhaengen(hase, event)
	hase.play()
	var ziel_x := float(event.get("bis_x", 1500.0))
	var dauer := absf(ziel_x - start) / 160.0
	var tween := hase.create_tween()
	tween.tween_property(hase, "position:x", ziel_x, dauer)
	tween.tween_callback(hase.stop)
	tween.tween_callback(func() -> void: hase.frame = 0)

func _geste_vogel(event: Dictionary) -> void:
	var vogel := AnimatedSprite2D.new()
	vogel.sprite_frames = _sheet_frames("res://world/assets/tiere/vogel.svg", 32, "fliegen", 9.0)
	vogel.animation = "fliegen"
	vogel.scale = Vector2.ONE * 1.4
	var richtung := float(event.get("richtung", 1.0))
	vogel.flip_h = richtung > 0.0
	var von_x := float(event.get("von_x", RAHMEN_LINKS))
	var hoehe := float(event.get("hoehe", 300.0))
	vogel.position = Vector2(von_x, hoehe)
	_anhaengen(vogel, event)
	vogel.play()
	var tween := vogel.create_tween()
	if richtung == 0.0:
		# Der unbekannte Vogel: er landet einfach und bleibt sitzen.
		vogel.flip_h = false
		tween.tween_property(vogel, "position:y", hoehe + 180.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(vogel.stop)
		tween.tween_callback(func() -> void: vogel.set_meta("van", true))
		_staub(vogel.position + Vector2(0.0, 96.0))
	else:
		var ziel_x := RAHMEN_RECHTS if richtung > 0.0 else RAHMEN_LINKS
		var dauer := absf(ziel_x - von_x) / 260.0
		tween.tween_property(vogel, "position:x", ziel_x, dauer)
		# Der Wellenflug lebt im Tween: sanftes Auf und Ab quer durchs Bild.
		var bob := vogel.create_tween().set_loops()
		bob.tween_property(vogel, "position:y", hoehe - float(event.get("amplitude", 30.0)), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(vogel, "position:y", hoehe + float(event.get("amplitude", 30.0)), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _geste_hacker(event: Dictionary) -> void:
	var hacker := AnimatedSprite2D.new()
	hacker.sprite_frames = _sheet_frames("res://world/assets/ui/hacken_rechts.svg", 64, "hacken", 8.0)
	hacker.animation = "hacken"
	hacker.scale = Vector2.ONE * FIGUR_SCALE
	hacker.flip_h = float(event.get("richtung", 1.0)) < 0.0
	hacker.position = _fuss(Vector2(float(event.get("x", 900.0)) - 60.0, float(event.get("y", 910.0))), 64.0 * FIGUR_SCALE)
	_anhaengen(hacker, event)
	hacker.play()
	hacker.set_meta("ziel_id", int(event.get("ziel", 0)))

func _geste_hackt(event: Dictionary) -> void:
	# Der Hacker schlaegt drei Mal, der Baum schrumpft unter jedem Schlag.
	var hacker := actoren.get(int(event.get("ziel", 0))) as AnimatedSprite2D
	if hacker == null:
		return
	var ziel_id := int(hacker.get_meta("ziel_id", 0))
	var baum := actoren.get(ziel_id) as Sprite2D
	if baum == null:
		return
	var wiederholung := 0
	var schlag := baum.create_tween()
	while wiederholung < 3:
		schlag.tween_interval(0.7)
		schlag.tween_callback(_ein_schlag.bind(hacker, baum, wiederholung))
		wiederholung += 1

func _ein_schlag(_hacker: AnimatedSprite2D, baum: Sprite2D, schlag: int) -> void:
	# Der Haackende bleibt als Meta am Ereignis haengen, der Blick des Beweises
	# gilt dem Baum: Staub und Masse sind seine Antwort auf jeden Schlag.
	_staub(baum.position + Vector2(0.0, 60.0))
	var masse := 1.0 - 0.18 * float(schlag + 1)
	var tween := baum.create_tween()
	tween.tween_property(baum, "scale:x", BAUM_SCALE * masse, 0.2)

func _geste_faellt(event: Dictionary) -> void:
	var baum := actoren.get(int(event.get("ziel", 0))) as Sprite2D
	if baum == null:
		return
	# Der Baum kippt zum naechsten Feuer und hinterlaesst die Luecke.
	var feuer := _feuer_nahe(baum.position.x)
	var dreh := baum.create_tween()
	dreh.tween_property(baum, "rotation_degrees", 90.0 if baum.position.x < 960.0 else -90.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)
	dreh.tween_property(baum, "modulate:a", 0.0, 0.6)
	dreh.tween_callback(baum.queue_free)
	actoren.erase(int(event.get("ziel", 0)))
	if feuer != null:
		var puls := feuer.create_tween()
		puls.tween_property(feuer, "scale", Vector2.ONE * FEUER_SCALE * 1.35, 0.4)
		puls.tween_property(feuer, "scale", Vector2.ONE * FEUER_SCALE, 0.6)

func _feuer_nahe(x: float) -> AnimatedSprite2D:
	var bestes: AnimatedSprite2D = null
	var beste_distanz := 999999.0
	for actor: Node2D in actoren.values():
		if actor is AnimatedSprite2D and actor.get_meta("art", "") == "feuer":
			var distanz := absf(actor.position.x - x)
			if distanz < beste_distanz:
				beste_distanz = distanz
				bestes = actor as AnimatedSprite2D
	return bestes

func _geste_flieht(event: Dictionary) -> void:
	var tier := actoren.get(int(event.get("ziel", 0))) as AnimatedSprite2D
	if tier == null:
		return
	var ziel_x := RAHMEN_RECHTS if tier.position.x < 960.0 else RAHMEN_LINKS
	tier.flip_h = ziel_x > tier.position.x
	tier.play()
	var dauer := absf(ziel_x - tier.position.x) / 300.0
	var tween := tier.create_tween()
	tween.tween_property(tier, "position:x", ziel_x, dauer)
	tween.tween_callback(_aushaengen.bind(tier, 0.3))

func _geste_vannon(event: Dictionary) -> void:
	# Das Easter-Egg: Der Vogel wird zum Stehenden, der immer da war.
	var vogel: AnimatedSprite2D = null
	for actor: Node2D in actoren.values():
		if actor is AnimatedSprite2D and actor.has_meta("van"):
			vogel = actor as AnimatedSprite2D
			break
	var stelle := Vector2(float(event.get("x", 960.0)), float(event.get("y", 620.0)))
	if vogel != null:
		stelle = vogel.position
		vogel.set_meta("event_id", -1)
		var weg := vogel.create_tween()
		weg.tween_property(vogel, "modulate:a", 0.0, 0.5)
		weg.tween_callback(vogel.queue_free)
	var figur := Sprite2D.new()
	figur.texture = load("res://world/assets/ui/strichmaennchen_stehend.svg")
	figur.scale = Vector2.ONE * FIGUR_SCALE
	figur.position = stelle
	figur.scale *= 0.1
	add_child(figur)
	var tween := figur.create_tween()
	tween.tween_property(figur, "scale", Vector2.ONE * FIGUR_SCALE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_staub(figur.position + Vector2(0.0, 40.0))

func _geste_puls(event: Dictionary) -> void:
	var ziel := str(event.get("ziel", ""))
	if ziel == "feuer":
		for actor: Node2D in actoren.values():
			if actor is AnimatedSprite2D and actor.get_meta("art", "") == "feuer":
				var feuer_puls := actor.create_tween()
				feuer_puls.tween_property(actor, "scale", Vector2.ONE * FEUER_SCALE * 1.3, 0.35)
				feuer_puls.tween_property(actor, "scale", Vector2.ONE * FEUER_SCALE, 0.55)
	elif ziel == "titel":
		var titel := get_node_or_null("../../Titel") as Control
		if titel != null:
			var titel_puls := titel.create_tween()
			titel_puls.tween_property(titel, "scale", Vector2.ONE * 1.06, 0.3)
			titel_puls.tween_property(titel, "scale", Vector2.ONE, 0.5)

func _geste_verbeugt(event: Dictionary) -> void:
	var figur := actoren.get(int(event.get("ziel", 0))) as Sprite2D
	if figur == null:
		return
	var tween := figur.create_tween()
	tween.tween_property(figur, "rotation_degrees", 28.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(figur, "rotation_degrees", 0.0, 0.8).set_trans(Tween.TRANS_SINE)

## Kategorie hilfe: Anhaengen und Staub.

func _anhaengen(actor: Node2D, event: Dictionary) -> void:
	actor.set_meta("event_id", int(event.get("id", 0)))
	actor.set_meta("art", str(event.get("art", "")))
	add_child(actor)
	actoren[int(event.get("id", 0))] = actor

func _staub(stelle: Vector2) -> void:
	# Ein Papier-Staubpuff: ein weicher Kreis, der sich loest.
	var puff := Sprite2D.new()
	var verlauf := Gradient.new()
	verlauf.colors = PackedColorArray([Color(0.96, 0.93, 0.86, 0.75), Color(0.96, 0.93, 0.86, 0.0)])
	verlauf.offsets = PackedFloat32Array([0.2, 1.0])
	var bild := GradientTexture2D.new()
	bild.gradient = verlauf
	bild.fill = GradientTexture2D.FILL_RADIAL
	bild.fill_from = Vector2(0.5, 0.5)
	bild.fill_to = Vector2(0.5, 0.0)
	bild.width = 64
	bild.height = 64
	puff.texture = bild
	puff.position = stelle
	puff.scale = Vector2.ONE * 0.4
	add_child(puff)
	var tween := puff.create_tween()
	tween.tween_property(puff, "scale", Vector2.ONE * 1.3, 0.5)
	tween.parallel().tween_property(puff, "position:y", stelle.y - 26.0, 0.5)
	tween.tween_callback(puff.queue_free)

## Die Buehne leer raeumen, wenn die Story von vorn beginnt.
func buehne_leeren() -> void:
	for actor: Node2D in actoren.values():
		if actor != null:
			_aushaengen(actor, 0.4)
	actoren.clear()
