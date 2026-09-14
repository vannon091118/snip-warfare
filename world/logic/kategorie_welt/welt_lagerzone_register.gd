extends RefCounted
class_name Welt_LagerzoneRegister
## Einzige Schreibstelle für markierte Lagerflächen (Lagerzonen) im Weltzustand.
## Eine Lagerzone ist der bewusste Akt "Dieser geschlossene Raum ist jetzt
## mein Lager": Markierung im Raum, Lager-Anlage beim Manager, Signal am Bus.
##
## Verantwortlichkeit: Lagerflächen-Zustand.
##
## Die Zonen selbst wohnen als Zusatzfelder im Welt_Model (Schlüssel
## lagerzone_<id>). Ein neuer Raum liest sie nicht; die Progressionsmaschine
## allein entscheidet, ob die erste eigene Lagerzone die nächste Stufe öffnet.

const SCHLUESSEL_PREFIX := "lagerzone_"
const SCHLUESSEL_ANZAHL := "lagerzone_anzahl"
const SCHLUESSEL_LETZTE := "lagerzone_letzte_position"

var _model: Welt_Model = null
var _lager: Lager_Manager = null
var _erkenner := Welt_RaumErkenner.new()

func einrichten(model: Welt_Model, lager: Lager_Manager) -> void:
	_model = model
	_lager = lager

func model_setzen(model: Welt_Model, lager: Lager_Manager = null) -> void:
	_model = model
	if lager != null:
		_lager = lager

func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager

func lagerzone_registrieren(welt_position: Vector2) -> Dictionary:
	if _model == null or _lager == null:
		return {"ok": false, "grund": "nicht bereit"}
	var raum := _erkenner.raum_an_position(welt_position, _model)
	if raum == null:
		return {"ok": false, "grund": "kein geschlossener Raum"}
	if raum.innen_flaeche < 16 or raum.breite < 4 or raum.hoehe < 4:
		return {"ok": false, "grund": "Raum braucht mindestens 4x4 Innenfläche"}
	if not raum.hat_tuer:
		return {"ok": false, "grund": "Raum braucht eine Tür"}
	if not raum.geschlossen:
		return {"ok": false, "grund": "Raum ist nicht geschlossen"}
	# Idempotenz: Dieselbe Kachel innerhalb desselben Raumes zählt einmal
	var raum_schluessel := "%s:%d:%d" % [raum.id, raum.min_kachel.x, raum.min_kachel.y]
	var marker := SCHLUESSEL_PREFIX + raum_schluessel
	if _model.objekt_feld(0, marker, null) != null:
		return {"ok": false, "grund": "Raum bereits Lagerzone"}
	var zufall := Kern_Zufall.new()
	zufall.start_zustand_setzen(_model.welt_seed + int(welt_position.x) * 73856093 + int(welt_position.y) * 19349663)
	var zone_id := "%s_%d" % [marker, zufall.zahl_bereich(0, 99999)]
	var zone_index := _lager.lager_anlegen("lagerflaeche", raum.zentrum)
	if zone_index < 0:
		# Fallback: typ lagerflaeche unbekannt -> kleinstes lager
		zone_index = _lager.lager_anlegen("kleines_lager", raum.zentrum)
	if zone_index < 0:
		return {"ok": false, "grund": "Lager nicht anlegbar"}
	_lagerzone_schreiben(zone_id, raum, welt_position, zone_index)
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_lagerzone_registriert(welt_position)
	return {"ok": true, "raum_id": raum.id, "zone_id": zone_id, "lager_index": zone_index, "zentrum": raum.zentrum}

func anzahl() -> int:
	if _model == null:
		return 0
	var zahl: Variant = _model.objekt_feld(0, SCHLUESSEL_ANZAHL, 0)
	return int(zahl) if typeof(zahl) in [TYPE_INT, TYPE_FLOAT] else 0

func hat_mindestens_eine_zone() -> bool:
	return anzahl() > 0

func letzte_zone_position() -> Vector2:
	if _model == null:
		return Vector2.INF
	var wert: Variant = _model.objekt_feld(0, SCHLUESSEL_LETZTE, null)
	if wert is Array and (wert as Array).size() == 2:
		var arr: Array = wert as Array
		return Vector2(float(arr[0]), float(arr[1]))
	return Vector2.INF

func _lagerzone_schreiben(zone_id: String, raum: Welt_Raum, markierung: Vector2, lager_index: int) -> void:
	var bisher := anzahl()
	var wort := {
		"raum_id": raum.id,
		"innen_flaeche": raum.innen_flaeche,
		"hat_tuer": raum.hat_tuer,
		"zentrum": [raum.zentrum.x, raum.zentrum.y],
		"markierung": [markierung.x, markierung.y],
		"lager_index": lager_index,
		"z_ebene": raum.z_ebene,
	}
	_model.objekt_feld_setzen(0, zone_id, wort)
	_model.objekt_feld_setzen(0, SCHLUESSEL_ANZAHL, bisher + 1)
	_model.objekt_feld_setzen(0, SCHLUESSEL_LETZTE, [markierung.x, markierung.y])

func alle_zonen() -> Array[Dictionary]:
	if _model == null:
		return []
	var ergebnis: Array[Dictionary] = []
	for eintrag in _model.objekte:
		for schluessel in (eintrag as Dictionary).keys():
			if str(schluessel).begins_with(SCHLUESSEL_PREFIX):
				var wert: Variant = (eintrag as Dictionary)[schluessel]
				if typeof(wert) == TYPE_DICTIONARY:
					ergebnis.append(wert as Dictionary)
	return ergebnis
