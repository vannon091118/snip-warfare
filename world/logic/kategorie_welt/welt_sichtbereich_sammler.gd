extends RefCounted
class_name Welt_SichtbereichSammler
## Sichtbereich-Sammler der Karte: Er rechnet aus, wann der sichtbare
## Objektbestand neu abgeglichen werden muss und ob ein Punkt im Blick
## liegt. Das Modell bleibt die volle Wahrheit; der Knotenbestand folgt
## dem Blick. Der Renderer führt nur noch die Knoten und fragt hier.
## Ohne gesetzten Bereich (Editor) gilt alles als sichtbar, wie bisher.

## Rand um den Kamera-Bereich, damit Objekte am Bildrand nicht flackern.
const SICHT_RAND_PX := 384.0
## Erst ab dieser Blickverschiebung wird neu gesammelt, nicht je Frame.
const SCAN_SCHRITT_PX := 64.0
## Deckel für Anhänge je Ruf, damit ein Ruck nie den ganzen Frame frisst.
const MAX_ANHAENGE_PRO_RUF := 256

## Kategorie daten: Der aktuelle Blick und sein Abgleich-Zustand.
var _sichtbereich := Rect2()
var _scan_mitte := Vector2.INF
var _sichtgebiet_dirty := true

func bereich_setzen(bereich: Rect2) -> bool:
	## Setzt den Kamera-Bereich samt Rand und meldet, ob ein Neuabgleich
	## fällig ist: bei echtem Blickwechsel oder Modelländerung, nicht bei
	## stillstehender Kamera.
	_sichtbereich = bereich
	var mitte := _sichtbereich.get_center()
	if _sichtgebiet_dirty or _scan_mitte.distance_to(mitte) >= SCAN_SCHRITT_PX:
		_scan_mitte = mitte
		_sichtgebiet_dirty = false
		return true
	return false

func deaktivieren() -> void:
	## Der Editor und Prüfläufe ohne Kamera hängen alles an, wie bisher.
	_sichtbereich = Rect2()

func dirty_setzen() -> void:
	## Erzwingt den Neuabgleich beim nächsten Ruf: nach Gebäudeplatzierung
	## oder Spawn-Ereignissen, ohne auf Kamerabewegung warten zu müssen.
	_sichtgebiet_dirty = true

func ist_aktiv() -> bool:
	return _sichtbereich.size != Vector2.ZERO

func enthaelt(punkt: Vector2) -> bool:
	return _sichtbereich.has_point(punkt)

func rechteck() -> Rect2:
	return _sichtbereich
