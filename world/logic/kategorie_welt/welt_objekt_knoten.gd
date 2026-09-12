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
var _schatten_lage: LightOccluder2D = null

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

## Die Schatten-Lage des Objekts: Ein simples Rechteck-Okkluder über der
## unteren Bildhälfte wirft im Papierlicht die weiche Boden-Schattenlage.
## Die Szene schaltet sie nur für Katalog-Einträge mit schatten_wurf an.
func schatten_wurf_setzen(aktiv: bool, breite: float, hoehe: float) -> void:
	if aktiv:
		if _schatten_lage == null:
			_schatten_lage = LightOccluder2D.new()
			_schatten_lage.name = "SchattenLage"
			var umriss := OccluderPolygon2D.new()
			var halb_b := maxf(breite * 0.35, 8.0)
			var halb_h := maxf(hoehe * 0.3, 8.0)
			umriss.polygon = PackedVector2Array([
				Vector2(-halb_b, 0.0), Vector2(halb_b, 0.0),
				Vector2(halb_b, -halb_h), Vector2(-halb_b, -halb_h),
			])
			_schatten_lage.occluder = umriss
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
