extends Welt_RegistryBasis
class_name Kern_LogikRegistry
## Registry der generischen Logiken des Projekts.
## Jede Logik ist objektunabhängig wiederverwendbar. Die Quelle ist
## core/data/kern_logik.json; jede Logik erhält eine eigene Instanz von
## Kern_LogikBasis. Objekte und Tiere verweisen nur über logik_id darauf.

const LOGIK_PFAD := "res://core/data/kern_logik.json"

## Kategorie daten: getypte Liste aller Logiken.

var logiken: Array[Kern_LogikBasis] = []
var _logiken_nach_id: Dictionary = {}

## Kategorie logik: Laden und Zugriff.

func _init() -> void:
	super(LOGIK_PFAD)

func schema_name() -> String:
	return "Kern_LogikRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Logik-Daten haben ein ungültiges Format: %s" % LOGIK_PFAD)
		return false
	logiken.clear()
	_logiken_nach_id.clear()
	for eintrag_id: String in (gelesen as Dictionary).keys():
		var eintrag: Dictionary = gelesen[eintrag_id]
		var logik := Kern_LogikBasis.new()
		logik.aus_eintrag(eintrag_id, eintrag)
		logiken.append(logik)
		_logiken_nach_id[eintrag_id] = logik
		registrieren(eintrag_id, logik)
	return true

func logik_fuer(logik_id: String) -> Kern_LogikBasis:
	if _logiken_nach_id.has(logik_id):
		return _logiken_nach_id[logik_id]
	return null

func hat_logik(logik_id: String) -> bool:
	return _logiken_nach_id.has(logik_id)

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["logiken"] = "Array[Kern_LogikBasis]"
	return arten
