extends Welt_ModellBasis
class_name Welt_ModellObjekte
## Zweite Stufe der Kette: die Objektliste.
## Kategorie daten: die Objektliste und ihre naechste Nummer.
## Kategorie logik: Lesen und Schreiben nur ueber die eigenen Funktionen.

var objekte: Array[Dictionary] = []
var _naechste_objekt_nummer: int = 1

func objekt_hinzufuegen(element_id: String, position: Vector2) -> int:
	# Liefert den Array-Index des neuen Objekts zurueck, damit Aufrufer sofort
	# Zustandsfelder ueber objekt_feld_setzen schreiben koennen. Die fachliche
	# Objekt-Nummer bleibt als Feld "id" erhalten.
	var nummer := _naechste_objekt_nummer
	_naechste_objekt_nummer += 1
	objekte.append({
		"id": nummer,
		"element_id": element_id,
		"position": [position.x, position.y],
	})
	return objekte.size() - 1

func objekt_position(index: int) -> Vector2:
	var position_werte: Array = objekte[index]["position"]
	return Vector2(position_werte[0], position_werte[1])

func objekt_verschieben(index: int, neue_position: Vector2) -> void:
	objekte[index]["position"] = [neue_position.x, neue_position.y]

func objekt_entfernen(index: int) -> void:
	objekte.remove_at(index)

func objekt_anzahl() -> int:
	return objekte.size()

func objekt_element_id(index: int) -> String:
	if index < 0 or index >= objekte.size():
		return ""
	return str(objekte[index].get("element_id", ""))

func objekt_daten(index: int) -> Dictionary:
	if index < 0 or index >= objekte.size():
		return {}
	return objekte[index]

func objekt_feld(index: int, schluessel: String, default: Variant = null) -> Variant:
	# Gelesener Zustand eines Objekt-Feldes (zum Beispiel Gebaeudezustand);
	# die Daten gehoeren dem Modell, Fremde lesen nur ueber diese Schnittstelle.
	if index < 0 or index >= objekte.size():
		return default
	return objekte[index].get(schluessel, default)

func objekt_feld_setzen(index: int, schluessel: String, wert: Variant) -> void:
	# Einzige Schreibstelle fuer Zusatzfelder am Objekt (Gebaeudezustand,
	# Fortschritte); der Besitzer bleibt dieses Modell.
	if index < 0 or index >= objekte.size():
		return
	objekte[index][schluessel] = wert

func objekte_mit_element_id(element_id: String) -> Array[int]:
	# Alle Objekt-Indizes einer Element-Art; fuer Gebaeude- und Statusabfragen.
	var treffer: Array[int] = []
	for index in objekte.size():
		if str(objekte[index].get("element_id", "")) == element_id:
			treffer.append(index)
	return treffer

func objekt_ids() -> Array[String]:
	var ids: Array[String] = []
	for eintrag in objekte:
		ids.append(str(eintrag.get("element_id", "")))
	return ids

func objekte_leeren() -> void:
	objekte.clear()
