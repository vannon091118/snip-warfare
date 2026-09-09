extends RefCounted
class_name Lager_Manager
## Verwaltung aller lokalen Lager-Instanzen einer Partie.
## Jedes Haus/Gebäude ist ein Lager: Ressourcen liegen verortet, nie global.
## Der Manager ist die einzige Stelle, die Lager anlegt und die Mutationen
## darauf anwendet. Der globale Bestand ist nur die abgeleitete UX-Summe.

## Kategorie daten: Lager-Instanzen mit Position und Bestand.

var _lager: Array[Dictionary] = []
var _registry := Lager_Registry.new()
var _zufall := Kern_Zufall.new()

## Kategorie logik: Anlegen, Befüllen, Entnehmen, Abfragen.

func _init() -> void:
	_zufall.start_zustand_setzen(42)

func lager_anlegen(typ_id: String, welt_position: Vector2) -> int:
	if not _registry.hat_typ(typ_id):
		push_warning("Unbekannter Lager-Typ: %s" % typ_id)
		return -1
	var typ := _registry.typ_fuer(typ_id)
	var eintrag: Dictionary = {
		"typ_id": typ_id,
		"position": [welt_position.x, welt_position.y],
		"bestaende": {},
		"kapazitaet": typ.kapazitaet,
	}
	_lager.append(eintrag)
	return _lager.size() - 1

func lager_zahl() -> int:
	return _lager.size()

func lager_position(index: int) -> Vector2:
	if index < 0 or index >= _lager.size():
		return Vector2.INF
	var pos: Array = _lager[index]["position"]
	return Vector2(pos[0], pos[1])

func lager_typ_id(index: int) -> String:
	if index < 0 or index >= _lager.size():
		return ""
	return str(_lager[index].get("typ_id", ""))

## Lokale Bestände je Lager.

func bestand_im_lager(lager_index: int, ressource: String) -> int:
	if lager_index < 0 or lager_index >= _lager.size():
		return 0
	var bestaende: Dictionary = _lager[lager_index].get("bestaende", {})
	return int(bestaende.get(ressource, 0))

func gesamt_bestand(ressource: String) -> int:
	var summe := 0
	for lager: Dictionary in _lager:
		var bestaende: Dictionary = lager.get("bestaende", {})
		summe += int(bestaende.get(ressource, 0))
	return summe

func gesamt_bestand_alle() -> Dictionary:
	var summe: Dictionary = {}
	for lager: Dictionary in _lager:
		var bestaende: Dictionary = lager.get("bestaende", {})
		for ressource: String in bestaende.keys():
			summe[ressource] = int(summe.get(ressource, 0)) + int(bestaende[ressource])
	return summe

## Nächstes Lager für eine Weltposition (für Ernte und Verbrauch).

func naechstes_lager_fuer(welt_position: Vector2) -> int:
	if _lager.is_empty():
		return -1
	var bester := 0
	var beste_distanz := INF
	for idx in _lager.size():
		var distanz := lager_position(idx).distance_to(welt_position)
		if distanz < beste_distanz:
			beste_distanz = distanz
			bester = idx
	return bester

## Über Mutationen schreiben — nie direkt.

func einlagern(ressource: String, menge: int, lager_index: int) -> bool:
	if menge <= 0 or lager_index < 0 or lager_index >= _lager.size():
		return false
	var zustand: Dictionary = {"lager": _lager.duplicate(true)}
	var mutation := Lager_MutationEinlagern.new(ressource, menge, lager_index)
	if not mutation.anwendbar(zustand):
		return false
	var ergebnis := mutation.anwenden(zustand, _zufall)
	_lager = ergebnis["lager"]
	return true

func entnehmen(ressource: String, menge: int, lager_index: int) -> bool:
	if menge <= 0 or lager_index < 0 or lager_index >= _lager.size():
		return false
	var zustand: Dictionary = {"lager": _lager.duplicate(true)}
	var mutation := Lager_MutationEntnehmen.new(ressource, menge, lager_index)
	if not mutation.anwendbar(zustand):
		return false
	var ergebnis := mutation.anwenden(zustand, _zufall)
	_lager = ergebnis["lager"]
	return true

## Für Speicher/Tests.

func nach_woerterbuch() -> Dictionary:
	return {"lager": _lager.duplicate(true)}

func aus_woerterbuch(daten: Dictionary) -> void:
	var arr: Variant = daten.get("lager", [])
	if typeof(arr) == TYPE_ARRAY:
		_lager = arr.duplicate(true)
