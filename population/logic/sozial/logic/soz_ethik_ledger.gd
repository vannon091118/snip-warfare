extends RefCounted
class_name Soz_EthikLedger
## Kategorie daten: Der private Kontostand einer Einheit und ihre Taten-Erinnerung.
## Kategorie logik: Nur Buchung und Lesen; wer bucht, entscheidet die Zeugen-Maschine.

## Kategorie daten: Ringpuffer der letzten Taten (Tiefe kommt aus den Daten).
var _erinnerung: Array[float] = []
var _tiefe: int = 8

func tiefe_setzen(tiefe: int) -> void:
	_tiefe = maxi(tiefe, 1)

func buchen(stoss: float) -> void:
	_erinnerung.append(stoss)
	while _erinnerung.size() > _tiefe:
		_erinnerung.pop_front()

func kontostand() -> float:
	var summe := 0.0
	for wert in _erinnerung:
		summe += wert
	return summe

func leer() -> bool:
	return _erinnerung.is_empty()
