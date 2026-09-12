extends RefCounted
class_name Einheit_ErnteMaschine
## Verbucht fertige Arbeitsschritte ins Inventar, schlaegt Tiere/Kannibalen schlagweise.
signal beute_erlegt(status: Einheit_Status)
signal schlag_ort_gemeldet(welt_position: Vector2)
signal schlag_objekt_gemeldet(ziel_index: int)
signal inventar_voll(einheit_index: int)

var _inventar: Einheit_Inventar = null
var _ressourcen: Einheit_Ressourcen = null
var _model: Welt_Model = null
var _tiere: Tier_Manager = null
var _zufall: Kern_Zufall = null
var _manager: Einheit_Manager = null
var _aktueller_einheit_index: int = -1
var _inventare: Dictionary = {}  # einheit_index -> Einheit_Inventar

func einrichten(inventar: Einheit_Inventar, ressourcen: Einheit_Ressourcen, model: Welt_Model, tiere: Tier_Manager) -> void:
	_inventar = inventar
	_ressourcen = ressourcen
	_model = model
	_tiere = tiere

func inventar_fuer_einheit_setzen(einheit_index: int, inventar: Einheit_Inventar) -> void:
	_inventare[einheit_index] = inventar

func _inventar_fuer_einheit(einheit_index: int) -> Einheit_Inventar:
	return _inventare.get(einheit_index, _inventar)

func zufall_setzen(zufall: Kern_Zufall) -> void:
	_zufall = zufall
func manager_setzen(manager: Einheit_Manager) -> void:
	_manager = manager

func arbeitsschritt_verarbeiten(ressource: String, menge: int, status: Einheit_Status, einheit_index: int = -1) -> void:
	if _ressourcen == null or status == null:
		return
	if status.zustand != Einheit_Status.Zustand.ARBEITEN or status.ziel_ressource != ressource:
		return
	_aktueller_einheit_index = einheit_index
	var inventar := _inventar_fuer_einheit(einheit_index)
	if inventar == null:
		return
	match status.aktuelles_ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			_ressourcen.ernte_position_setzen(_objekt_position(status.aktuelles_ziel_index))
			schlag_ort_gemeldet.emit(_objekt_position(status.aktuelles_ziel_index))
			schlag_objekt_gemeldet.emit(status.aktuelles_ziel_index)

			var ok := inventar.aufnahme(ressource, menge)
			if not ok and inventar.ist_voll():
				inventar_voll.emit(einheit_index)
		Job_Basis.ZielTyp.TIER:
			_jagd_schlag(status, menge)
		Job_Basis.ZielTyp.OWN:
			_kannibale_schlag(status, menge)
			_kannibale_schlag(status, menge)

func _objekt_position(index: int) -> Vector2:
	if _model == null or index < 0 or index >= _model.objekt_anzahl():
		return Vector2.ZERO
	return _model.objekt_position(index)

func _kannibale_schlag(status: Einheit_Status, schaden: int) -> void:
	if _zufall == null:
		_zufall = Kern_Zufall.new()
	var opfer := status.aktuelles_ziel_index
	if opfer < 0:
		return

	var manager := _manager_des_opfers()
	if manager == null:
		return
	var vital := manager.einheit_vital(opfer)
	if vital == null or vital.hp <= 0:
		status.job_abbrechen()
		return
	vital.schaden_nehmen(schaden, _zufall, "kampf")
	if vital.hp <= 0:
		status.job_abbrechen()
		beute_erlegt.emit(status)

		var bus := Kern_SignalBus.bus()
		if bus != null:
			bus._emit_kannibalismus(manager.einheit_position(opfer))

func _manager_des_opfers() -> Einheit_Manager:
	return _manager

func _jagd_schlag(status: Einheit_Status, schaden: int) -> void:
	if _tiere == null:
		return
	if _tiere.tier_angreifen(status.aktuelles_ziel_index, schaden):
		_tier_ernten(status)

func _tier_ernten(status: Einheit_Status) -> void:
	if _tiere == null or _ressourcen == null:
		return
	var inventar := _inventar_fuer_einheit(_aktueller_einheit_index)
	if inventar == null:
		return

	var kadaver_position := _tiere.tier_position(status.aktuelles_ziel_index)
	var fleisch := _tiere.tier_ernten(status.aktuelles_ziel_index)
	if fleisch > 0:
		_ressourcen.ernte_position_setzen(kadaver_position)
		schlag_ort_gemeldet.emit(kadaver_position)
		var ok := inventar.aufnahme("fleisch", fleisch)
		if not ok and inventar.ist_voll():
			inventar_voll.emit(_aktueller_einheit_index)

	status.job_abbrechen()
	beute_erlegt.emit(status)
