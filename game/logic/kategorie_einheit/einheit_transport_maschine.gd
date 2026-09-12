extends RefCounted
class_name Einheit_TransportMaschine
## Zustandsmaschine fuer den Materialtransport von Einheiten zwischen
## Lager und Baustellen. Steuert die Phasen und die Ladung.

enum Zustand {
	IDLE,
	GEHE_ZU_LAGER,
	MATERIAL_AUFNEHMEN,
	GEHE_ZU_BAUSTELLE,
	MATERIAL_ABLIEFERN,
	FERTIG
}

var zustand: Zustand = Zustand.IDLE
var baustelle_index: int = -1
var baustelle_position: Vector2 = Vector2.ZERO
var lager_index: int = -1
var lager_position: Vector2 = Vector2.ZERO
var ressource: String = ""
var soll_menge: int = 0
var ist_menge: int = 0

func transport_starten(p_baustelle_idx: int, p_baustelle_pos: Vector2, p_ressource: String, p_menge: int, p_lager_idx: int, p_lager_pos: Vector2) -> void:
	baustelle_index = p_baustelle_idx
	baustelle_position = p_baustelle_pos
	ressource = p_ressource
	soll_menge = p_menge
	ist_menge = 0
	lager_index = p_lager_idx
	lager_position = p_lager_pos
	zustand = Zustand.GEHE_ZU_LAGER

func lager_erreicht() -> void:
	if zustand == Zustand.GEHE_ZU_LAGER:
		zustand = Zustand.MATERIAL_AUFNEHMEN

func material_aufgenommen(menge: int) -> void:
	ist_menge = menge
	if ist_menge > 0:
		zustand = Zustand.GEHE_ZU_BAUSTELLE
	else:
		zustand = Zustand.FERTIG

func baustelle_erreicht() -> void:
	if zustand == Zustand.GEHE_ZU_BAUSTELLE:
		zustand = Zustand.MATERIAL_ABLIEFERN

func ablieferung_fertig() -> void:
	ist_menge = 0
	zustand = Zustand.FERTIG

func zuruecksetzen() -> void:
	zustand = Zustand.IDLE
	baustelle_index = -1
	lager_index = -1
	ressource = ""
	soll_menge = 0
	ist_menge = 0
