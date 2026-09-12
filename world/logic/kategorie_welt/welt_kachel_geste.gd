extends RefCounted
class_name Welt_KachelGeste
## Die sichtbare Geste einer neuen Kachel: Der kurze Hauch, mit dem frisches
## Papier auf dem Tisch landet. Genau eine Verantwortung: Der Sprite einer
## Kachel wackelt kurz auf und verblasst zur Ruhe, wenn sich sein Bild
## wirklich geändert hat. Keine Domänenlogik, keine Zeit außer der eigenen
## Tween-Laufzeit, keine zweite Zeichenstelle.

## Höhe des Aufstoßens in Pixeln und Dauer der Geste in Sekunden.
const HAUCH_HOEHE := 3.0
const DAUER := 0.35

## Der Sichtbefehl des Renderers: Er meldet, welche Kachel neu ist.
var _sichtbefehl: Callable = func(_x: int, _y: int, _element_id: String, _z_ebene: int) -> void: pass

## Kategorie logik: Einrichten und Ausspielen der Geste.

func einrichten(sichtbefehl: Callable) -> void:
	# Die Szene koppelt Modell-Signal und Renderer über diesen Befehl; die
	# Geste selbst kennt weder Modell noch Bus.
	_sichtbefehl = sichtbefehl

func verbinden() -> void:
	# Lauscht am Bus auf die Zustandsmeldung des Modells. Fehlt der Autoload
	# (Prüfläufe), bleibt die Geste still; doppelte Verbindung wird verhindert.
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("kachel_geaendert") and not bus.kachel_geaendert.is_connected(kachel_neu):
		bus.kachel_geaendert.connect(kachel_neu)

func kachel_neu(x: int, y: int, element_id: String, z_ebene: int) -> void:
	_sichtbefehl.call(x, y, element_id, z_ebene)

func platzieren_falls_neu(sprite: Sprite2D, vorherige_textur: Texture2D) -> void:
	# Ein echter Bildwechsel verdient einen Hauch; ein Neuaufbau derselben
	# Kachel bleibt still. Der Sprite kehrt exakt in seine Ruheposition
	# zurück, damit der Rasterbau nicht driftet.
	if sprite == null or vorherige_textur == sprite.texture:
		return
	var ruhe := sprite.position
	sprite.position = ruhe + Vector2(0.0, -HAUCH_HOEHE)
	var verwandlung := sprite.create_tween()
	verwandlung.tween_property(sprite, "position", ruhe, DAUER).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
