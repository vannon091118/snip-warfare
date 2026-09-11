extends RefCounted
class_name Welt_WindRechner
## Rein optische Wind-Ableitung aus dem Tick der zentralen Weltuhr.
## Die Klasse besitzt keine eigene Zeit: Jede Staerke und jede Richtung
## folgt deterministisch aus der uebergebenen Tick-Nummer und den Werten
## des Atmosphaeren-Pools. Kette: Weltuhr -> Tick-Nummer -> dieser Rechner
## -> Overlay, Sway-Material, Blaetter.

## Kategorie daten: Konfiguration und zuletzt abgeleiteter Zustand.
var _konfig: Welt_AtmosphaereKonfig = null
var _staerke: float = 0.0
var _phase: float = 0.0
var _richtung: float = 1.0

## Kategorie logik: deterministische Ableitung je Tick-Nummer.

const ZWEI_PI := 6.283185307179586

func einrichten(konfig: Welt_AtmosphaereKonfig) -> void:
	_konfig = konfig

## Aktualisiert Staerke und Richtung fuer die gegebene Tick-Nummer und die
## lokale Position: Die Wellenlaenge erzeugt raeumliche Variation, sodass
## nicht alle Objekte synchron wedeln. Rueckgabe ist die lokale Staerke.
func staerke_an(tick_nummer: int, lokal_x: float = 0.0) -> float:
	if _konfig == null:
		return 0.0
	var phasen_laenge := maxi(int(_konfig.wind_wert("phasen_laenge_takt", 240.0)), 1)
	var frequenz := _konfig.wind_wert("rausch_frequenz", 0.07)
	var minimum := _konfig.wind_wert("mindest_staerke", 0.15)
	var spanne := _konfig.wind_wert("staerke_spanne", 0.45)
	# Zeitliche Welle ueber die Tick-Nummer plus ortsabhaengige Verschiebung:
	# dieselbe Tick-Nummer liefert an jedem Ort denselben deterministischen
	# Wert, aber verschiedene Orte wedeln versetzt.
	var zeit_anteil := sin(ZWEI_PI * frequenz * float(tick_nummer))
	var ort_anteil := sin(ZWEI_PI * 0.006 * lokal_x + float(tick_nummer % phasen_laenge) / float(phasen_laenge) * ZWEI_PI)
	_staerke = clampf(minimum + spanne * (0.5 + 0.25 * zeit_anteil + 0.25 * ort_anteil), minimum, minimum + spanne)
	_phase = float(tick_nummer % phasen_laenge) / float(phasen_laenge) * ZWEI_PI
	var basis_richtung := _konfig.wind_wert("basis_richtung", 1.0)
	_richtung = basis_richtung * (1.0 if ort_anteil >= 0.0 else -1.0)
	return _staerke

func staerke() -> float:
	return _staerke

func phase() -> float:
	return _phase

func richtung() -> float:
	return _richtung
