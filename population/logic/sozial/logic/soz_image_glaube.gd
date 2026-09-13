extends RefCounted
class_name Soz_ImageGlaube
## Kategorie daten: Was ein Beobachter über ein Ziel glaubt: Wert plus Konfidenz.
## Kategorie logik: Nur Zustand; das Mischen geschieht in den Maschinen.

## Kategorie daten: Der geglaubte Wert und wie sicher der Beobachter ist.
var wert: float = 0.0
var konfidenz: float = 0.0

func mischen(neuer_wert: float, staerke: float) -> void:
	# Neues Wissen drückt sich mit seiner Stärke in den Glauben; die
	# Konfidenz wächst mit jeder Bestätigung gegen die Decke 1.
	var gegen_gewicht := (1.0 - konfidenz) * staerke
	wert = wert * (1.0 - gegen_gewicht) + neuer_wert * gegen_gewicht
	konfidenz = minf(konfidenz + staerke * 0.5, 1.0)
