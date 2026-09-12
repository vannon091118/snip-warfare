extends RefCounted
class_name Einheit_TransportMaschine
## Zustandsmaschine fuer den Materialtransport von Einheiten zum Lager.
## Phasen: GEHE_ZU_LAGER -> ABLIEFERN -> FERTIG
## Verallgemeinert den Transport fuer jede Einheit mit Inventar.

enum Zustand {
	IDLE,
	GEHE_ZU_LAGER,
	ABLIEFERN,
	FERTIG
}

var zustand: Zustand = Zustand.IDLE
var lager_index: int = -1
var lager_position: Vector2 = Vector2.ZERO
var inventar_vorher: Dictionary = {}

func transport_starten(p_lager_idx: int, p_lager_pos: Vector2, p_inventar: Dictionary) -> void:
	lager_index = p_lager_idx
	lager_position = p_lager_pos
	inventar_vorher = p_inventar.duplicate(true)
	zustand = Zustand.GEHE_ZU_LAGER

func lager_erreicht() -> void:
	if zustand == Zustand.GEHE_ZU_LAGER:
		zustand = Zustand.ABLIEFERN

func ablieferung_fertig() -> void:
	zustand = Zustand.FERTIG

func zuruecksetzen() -> void:
	zustand = Zustand.IDLE
	lager_index = -1
	lager_position = Vector2.ZERO
	inventar_vorher.clear()

func ist_aktiv() -> bool:
	return zustand != Zustand.IDLE and zustand != Zustand.FERTIG
