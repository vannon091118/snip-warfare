extends RefCounted
class_name Einheit_JobQueue
## Eigene Warteschlange einer Einheit: Jeder Stickman sammelt seine Aufträge
## selbst. Ein Eintrag ist nur eine Vormerkung; den Job selbst erzeugt erst der
## Manager, wenn die Reihe an ihm ist.

## Kategorie daten: die vorgemerkten Aufträge in ihrer Reihenfolge.
var _eintraege: Array[Dictionary] = []

## Kategorie logik: Vormerken, Reihenfolge und Entnahme.
func vormerken(job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ressource: String) -> void:
	# Nur eine Vormerkung pro Auftrag: Gleicher Job auf gleichem Ziel wird
	# nicht doppelt eingetragen.
	for eintrag: Dictionary in _eintraege:
		if str(eintrag.get("job_id", "")) == job_id \
				and int(eintrag.get("ziel_typ", -1)) == int(ziel_typ) \
				and int(eintrag.get("ziel_index", -1)) == ziel_index:
			return
	_eintraege.append({
		"job_id": job_id,
		"ziel_typ": int(ziel_typ),
		"ziel_index": ziel_index,
		"ressource": ressource,
	})

func laenge() -> int:
	return _eintraege.size()

func leer() -> bool:
	return _eintraege.is_empty()

func naechster() -> Dictionary:
	# Holt die älteste Vormerkung, ohne sie zu entfernen.
	if _eintraege.is_empty():
		return {}
	return _eintraege[0].duplicate(true)

func vorne_entfernen() -> void:
	# Entfernt die älteste Vormerkung, nachdem der Manager den Job gestartet hat.
	if not _eintraege.is_empty():
		_eintraege.remove_at(0)
