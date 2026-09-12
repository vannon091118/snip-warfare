extends Job_Basis
class_name Job_Transport
## Transport-Job: Einheit bringt ihr Inventar zum nächsten Lager.
## Phasen: GEHE_ZU_LAGER -> ABLIEFERN -> FERTIG
## Verallgemeinert die Einheit_TransportMaschine für Einheit->Lager.

var _phase: int = 0
var _lager_index: int = -1
var _lager_position: Vector2 = Vector2.ZERO
var _inventar_vorher: Dictionary = {}

const PHASE_GEHE_ZU_LAGER := 0
const PHASE_ABLIEFERN := 1
const PHASE_FERTIG := 2

func _init() -> void:
	_phase = PHASE_GEHE_ZU_LAGER

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func _passt_zu_objekt_fallback(_element_id: String) -> bool:
	return true

func phase() -> int:
	return _phase

func lager_index_setzen(idx: int) -> void:
	_lager_index = idx

func lager_index() -> int:
	return _lager_index

func lager_position_setzen(pos: Vector2) -> void:
	_lager_position = pos

func lager_position() -> Vector2:
	return _lager_position

func inventar_vorher_setzen(inv: Dictionary) -> void:
	_inventar_vorher = inv.duplicate(true)

func inventar_vorher() -> Dictionary:
	return _inventar_vorher.duplicate(true)

func startet_neu() -> void:
	super.startet_neu()
	_phase = PHASE_GEHE_ZU_LAGER

func schritt_vorruecken() -> bool:
	# Transport-Job hat keine Erntezeit; die Phasen werden extern gesteuert
	# über lager_erreicht() und ablieferung_fertig().
	return false

func arbeitsschritt(_ziel_ressource: String) -> void:
	# Wird nicht für Ernte verwendet; Abgabe passiert über die Phase.
	pass

func phase_wechseln(neue_phase: int) -> void:
	_phase = neue_phase

func ist_bei_lager() -> bool:
	return _phase == PHASE_ABLIEFERN

func ist_fertig() -> bool:
	return _phase == PHASE_FERTIG

func zuruecksetzen() -> void:
	_phase = PHASE_GEHE_ZU_LAGER
	_lager_index = -1
	_lager_position = Vector2.ZERO
	_inventar_vorher.clear()
