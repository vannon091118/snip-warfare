extends Node2D
class_name Welt_ObjektKnoten
## Der sichtbare Knoten genau eines Weltobjekts. Er hat eine einzige
## Verantwortung: Er richtet Blatt und Bewegtbild eines Objekts so aus, dass
## der Ursprung des Knotens sein Fußpunkt ist. Damit ist die Zeichenreihenfolge
## im tiefensortierten Objekt-Container ausschließlich die Fußposition und nie
## die Reihenfolge der Erzeugung: Ein Objekt weiter unten im Bild deckt das
## darüber liegende zu, egal welches zuletzt entstand.
## Der Knoten rechnet nicht und besitzt keine eigene Zeit. Seine Daten bezieht
## er ausschließlich vom Renderer, der sie aus dem Modell liest.

## Kategorie daten: der Datenbehälter des Objekts aus dem Modell, das Standbild
## und das optionale Bewegtbild.
var _objekt_daten: Dictionary = {}
var _standbild: Sprite2D = null
var _bewegtbild: AnimatedSprite2D = null
var _schatten_lage: Sprite2D = null

## Die geteilte Ellipsen-Textur aller Bodenschatten: einmal erzeugt, von
## jedem Knoten nur skaliert. Kein Licht, kein Okkluder, kein Vollbild-Schleier.
static var _schatten_textur: GradientTexture2D = null

static func _schatten_ellipse() -> GradientTexture2D:
	if _schatten_textur == null:
		var farbverlauf := Gradient.new()
		farbverlauf.colors = PackedColorArray([Color(0.05, 0.04, 0.08, 0.38), Color(0.05, 0.04, 0.08, 0.0)])
		farbverlauf.offsets = PackedFloat32Array([0.4, 1.0])
		_schatten_textur = GradientTexture2D.new()
		_schatten_textur.gradient = farbverlauf
		_schatten_textur.fill = GradientTexture2D.FILL_RADIAL
		_schatten_textur.fill_from = Vector2(0.5, 0.5)
		_schatten_textur.fill_to = Vector2(1.0, 0.5)
		_schatten_textur.width = 64
		_schatten_textur.height = 64
	return _schatten_textur

## Kategorie logik: Fußpunkt, Standbild und Bewegtbild setzen und lesen.

func daten_setzen(daten: Dictionary) -> void:
	# Die Identität dieses Behälters ist der Schlüssel zum Modell: Das Modell
	# liefert denselben Behälter auch dann, wenn sich Objekt-Indizes verschieben.
	_objekt_daten = daten

func objekt_daten() -> Dictionary:
	return _objekt_daten

func fusspunkt_setzen(neuer_fusspunkt: Vector2) -> void:
	position = neuer_fusspunkt

func fusspunkt() -> Vector2:
	return position

func standbild_setzen(textur: Texture2D) -> Sprite2D:
	# Jeder Blattwechsel richtet neu aus: Die Höhe kommt aus der Textur, damit
	# Standbild und Stufenblatt denselben Fuß behalten. Die Unterkante liegt
	# nach der Verschiebung um die halbe Höhe auf dem Ursprung.
	if _standbild == null:
		_standbild = Sprite2D.new()
		_standbild.name = "Standbild"
		_standbild.position = Vector2.ZERO
		add_child(_standbild)
	_standbild.texture = textur
	_standbild.centered = true
	_standbild.offset = Vector2(0.0, -_hoehe_von(textur) * 0.5)
	return _standbild

## Der Bodenschatten des Objekts: Eine flache, weiche Ellipse liegt am
## Fußpunkt und skaliert exakt mit der Objektgröße. Größere Objekte werfen
## größere Schatten, kleine kaum einen; kein Schleier über die Karte.
func schatten_wurf_setzen(aktiv: bool, breite: float, hoehe: float) -> void:
	if aktiv:
		if _schatten_lage == null:
			_schatten_lage = Sprite2D.new()
			_schatten_lage.name = "SchattenLage"
			_schatten_lage.texture = _schatten_ellipse()
			# Flache Ellipse: Breite folgt dem Objekt, Tiefe bleibt gedrückt.
			var halb_b := maxf(breite * 0.65, 10.0)
			var halb_h := maxf(hoehe * 0.22, 5.0)
			_schatten_lage.scale = Vector2(halb_b * 2.0 / 64.0, halb_h * 2.0 / 64.0)
			_schatten_lage.position = Vector2(0.0, -3.0)
			_schatten_lage.z_index = -1
			_schatten_lage.show_behind_parent = true
			add_child(_schatten_lage)
		return
	if _schatten_lage != null:
		_schatten_lage.queue_free()
		_schatten_lage = null

func standbild() -> Sprite2D:
	return _standbild

func bewegtbild_setzen(neues_bewegtbild: AnimatedSprite2D) -> void:
	# Das Bewegtbild hängt am Objekt-Knoten und nicht in einer eigenen Ebene:
	# Nur so nimmt es an derselben Tiefensortierung teil wie sein Standbild.
	bewegtbild_entfernen()
	if neues_bewegtbild == null:
		return
	_bewegtbild = neues_bewegtbild
	add_child(_bewegtbild)

func bewegtbild() -> AnimatedSprite2D:
	return _bewegtbild

func bewegtbild_entfernen() -> void:
	if _bewegtbild != null and is_instance_valid(_bewegtbild):
		_bewegtbild.queue_free()
	_bewegtbild = null

func _hoehe_von(textur: Texture2D) -> float:
	if textur == null:
		return 0.0
	return float(textur.get_height())
