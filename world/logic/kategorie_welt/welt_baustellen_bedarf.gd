extends RefCounted
class_name Welt_BaustellenBedarf
## Bedarfs- und Materiallogistikmaschine fuer Baustellen.
## Ermittelt fuer alle Objekte im Bauplan-Zustand die noch benoetigten Baustoffe
## und wickelt die Anlieferung von Traegern am Modell ab.

var _model: Welt_Model = null

func einrichten(model: Welt_Model) -> void:
	_model = model

func modell_setzen(model: Welt_Model) -> void:
	_model = model

func offener_bedarf(objekt_index: int) -> Dictionary:
	## Liefert ein Dictionary {ressource: noch_benoetigte_menge}.
	var ergebnis: Dictionary = {}
	if _model == null or objekt_index < 0 or objekt_index >= _model.objekt_anzahl():
		return ergebnis
	var bedarf: Dictionary = _model.objekt_feld(objekt_index, "bedarf", {})
	var geliefert: Dictionary = _model.objekt_feld(objekt_index, "geliefert", {})
	for ressource: String in bedarf.keys():
		var soll := int(bedarf.get(ressource, 0))
		var ist := int(geliefert.get(ressource, 0))
		if ist < soll:
			ergebnis[ressource] = soll - ist
	return ergebnis

func hat_offenen_bedarf(objekt_index: int) -> bool:
	return not offener_bedarf(objekt_index).is_empty()

func bedarf_anteil(objekt_index: int) -> float:
	## Liefert den Lieferfortschritt zwischen 0.0 (nichts da) und 1.0 (vollstaendig).
	if _model == null or objekt_index < 0 or objekt_index >= _model.objekt_anzahl():
		return 1.0
	var bedarf: Dictionary = _model.objekt_feld(objekt_index, "bedarf", {})
	if bedarf.is_empty():
		return 1.0
	var geliefert: Dictionary = _model.objekt_feld(objekt_index, "geliefert", {})
	var gesamt_soll := 0
	var gesamt_ist := 0
	for ressource: String in bedarf.keys():
		var soll := int(bedarf.get(ressource, 0))
		var ist := mini(int(geliefert.get(ressource, 0)), soll)
		gesamt_soll += soll
		gesamt_ist += ist
	if gesamt_soll <= 0:
		return 1.0
	return clampf(float(gesamt_ist) / float(gesamt_soll), 0.0, 1.0)

func material_anliefern(objekt_index: int, ressource: String, menge: int) -> int:
	## Liefert Material an der Baustelle ab und bucht es in das Modell.
	## Gibt die tatsaechlich angenommene Menge zurueck.
	if _model == null or objekt_index < 0 or objekt_index >= _model.objekt_anzahl() or menge <= 0:
		return 0
	var bedarf: Dictionary = _model.objekt_feld(objekt_index, "bedarf", {})
	var geliefert: Dictionary = _model.objekt_feld(objekt_index, "geliefert", {})
	var soll := int(bedarf.get(ressource, 0))
	var ist := int(geliefert.get(ressource, 0))
	if ist >= soll:
		return 0
	var noch_offen := soll - ist
	var annehmen := mini(menge, noch_offen)
	var neu_geliefert := geliefert.duplicate(true)
	neu_geliefert[ressource] = ist + annehmen
	_model.objekt_feld_setzen(objekt_index, "geliefert", neu_geliefert)

	# Wenn vollstaendig: Uebergang zu BAU_ANGEFORDERT
	if not hat_offenen_bedarf(objekt_index):
		var bau_phase := int(_model.objekt_feld(objekt_index, "bau_phase", Gebaeude_BauMaschine.Phase.NICHT_GEBAUT))
		if bau_phase == Gebaeude_BauMaschine.Phase.BAUPLAN:
			_model.objekt_feld_setzen(objekt_index, "bau_phase", int(Gebaeude_BauMaschine.Phase.BAU_ANGEFORDERT))
	return annehmen

func alle_baustellen_mit_bedarf() -> Array[int]:
	var liste: Array[int] = []
	if _model == null:
		return liste
	for idx in _model.objekt_anzahl():
		var gebaeude_id := str(_model.objekt_feld(idx, "gebaeude_id", ""))
		if gebaeude_id == "":
			continue
		var bau_phase := int(_model.objekt_feld(idx, "bau_phase", Gebaeude_BauMaschine.Phase.NICHT_GEBAUT))
		if bau_phase == Gebaeude_BauMaschine.Phase.BAUPLAN and hat_offenen_bedarf(idx):
			liste.append(idx)
	return liste

func naechste_baustelle_fuer(position: Vector2, verfuegbare_ressourcen: Array[String] = []) -> int:
	var baustellen := alle_baustellen_mit_bedarf()
	var bester := -1
	var beste_distanz := INF
	for b_idx in baustellen:
		if not verfuegbare_ressourcen.is_empty():
			var offen := offener_bedarf(b_idx)
			var passt := false
			for res in verfuegbare_ressourcen:
				if offen.has(res):
					passt = true
					break
			if not passt:
				continue
		var pos := _model.objekt_position(b_idx)
		var dist := position.distance_to(pos)
		if dist < beste_distanz:
			beste_distanz = dist
			bester = b_idx
	return bester
