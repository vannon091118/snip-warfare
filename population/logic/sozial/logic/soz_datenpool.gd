extends RefCounted
class_name Soz_Datenpool
## Kategorie daten: Der geladene Regeln-Pool aus sozial_regeln.json.
## Kategorie logik: Lesen und Zahlen-Lieferung; keine Logik, keine Zeit.

## Kategorie daten: Das rohe Regel-Verzeichnis.
var _regeln: Dictionary = {}

func laden(pfad: String) -> bool:
	var text := FileAccess.get_file_as_string(pfad)
	if text.is_empty():
		return false
	var gelesen: Variant = JSON.parse_string(text)
	if gelesen is Dictionary:
		_regeln = gelesen
		return true
	return false

func gruppe(schluessel: String) -> Dictionary:
	return _regeln.get(schluessel, {}) as Dictionary

func faktor(gruppe_name: String, schluessel: String) -> float:
	return float(gruppe(gruppe_name).get(schluessel, 0.0))
