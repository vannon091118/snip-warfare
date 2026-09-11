extends RefCounted
class_name Welt_WaermeFeld
## Reine Zustandsmaschine für das Wärmefeld. Genau eine Verantwortung:
## Aus Feuer-Positionen einen abfallenden Wert je Kachel berechnen.
## Keine UI, keine zweite Zeitquelle, rein deterministisch über Abstände.

## Kategorie daten: Feuer-Quellen und Feld-Kacheln.
var _quellen: Array[Vector2] = []
var _radius_kacheln: int = 5
var _staerke: float = 1.0
## RUECKFALL: Ohne gesetzten Wert gilt die Standardkante; im Spiel reicht
## der Einheit_Manager die echte Kachelgroesse des Modells herein.
var _kachel_groesse: float = float(Welt_Model.KACHEL_GROESSE)

## Kategorie logik: Quellen setzen und Feld je Position abfragen.
func kachel_groesse_setzen(kante: int) -> void:
	# Einzige Schreibstelle der Kachelkante in dieser Maschine.
	_kachel_groesse = maxf(float(kante), 1.0)

func quellen_setzen(feuer_welt_positionen: Array[Vector2], radius_kacheln: int = 5, staerke: float = 1.0) -> void:
	_quellen = feuer_welt_positionen.duplicate()
	_radius_kacheln = maxi(radius_kacheln, 1)
	_staerke = clampf(staerke, 0.1, 5.0)

func waerme_an(welt_position: Vector2, tages_haelligkeit: float = 1.0) -> float:
	# tages_haelligkeit 0..1 dämpft nachts die Grundwärme, Feuer bleibt.
	var grund := -0.3 * (1.0 - clampf(tages_haelligkeit, 0.0, 1.0))
	var best := grund
	for quelle: Vector2 in _quellen:
		var abstand_kacheln := welt_position.distance_to(quelle) / _kachel_groesse
		if abstand_kacheln > float(_radius_kacheln):
			continue
		var beitrag := _staerke * (1.0 - abstand_kacheln / float(_radius_kacheln))
		if quelle.distance_to(welt_position) < _kachel_groesse * 0.5:
			beitrag += 0.4
		best = maxf(best, beitrag)
	return clampf(best, -1.0, 1.5)

func naechstes_feuer_fuer(welt_position: Vector2) -> Vector2:
	if _quellen.is_empty():
		return Vector2.INF
	var best := _quellen[0]
	var best_abstand := welt_position.distance_to(best)
	for quelle: Vector2 in _quellen:
		var abstand := welt_position.distance_to(quelle)
		if abstand < best_abstand:
			best_abstand = abstand
			best = quelle
	return best
