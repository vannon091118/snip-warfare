extends RefCounted
class_name Kern_PathKnoten
## Datenklasse eines Pfad-Knotens: eine begehbare Kachel mit Kosten.
## Enthält nur Daten; die Berechnung liegt im Wegfinder. Jede Kollisionbox
## der Welt wirkt als Sperrung, Wege und Unebenheiten als Bonus oder Malus
## auf die Kosten, alles über die zentrale Registry beziehbar.

## Kategorie daten: Position, Kosten und Sperrung des Knotens.
var x: int = 0
var y: int = 0
var kachel_id: String = ""
var gesperrt: bool = false
var basis_kosten: float = 1.0
var weg_bonus: float = 0.0
var ebenen_malus: float = 0.0

## Kategorie logik: Reine Lesefunktion der effektiven Kosten.

func effektive_kosten() -> float:
	# Ein gebauter Weg senkt die Kosten, eine unebene Flaeche erhoeht sie.
	return maxf(0.05, basis_kosten - weg_bonus + ebenen_malus)
