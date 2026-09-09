extends RefCounted
class_name Welt_RegistryBasis
## Basis aller Kategorie-Registries des Projekts.
## Eine Registry hält die exakten Datenklassen ihrer Kategorie zentral;
## Preflight und State Machines ziehen ihre Referenzen ausschließlich aus
## diesen Registries, nie aus verstreuten Wörterbüchern.
## Jede Registry markiert die Bereiche und stellt die Prüf-Interfaces bereit,
## die der Preflight per Konvention erwartet (eintraege_lesen, datenfeld_arten).

## Kategorie daten: zentrale Zuordnung und getypte Eintragsliste.
## Die Datenklassen des Projekts erweitern RefCounted, daher ist die
## Eintragsliste getypt auf RefCounted und nicht auf Resource.
var eintraege_nach_id: Dictionary = {}
var eintraege: Array[RefCounted] = []

## Kategorie logik: Laden, Registrieren und Zugriff.
var _quelle_pfad: String = ""

func _init(quelle_pfad: String) -> void:
	_quelle_pfad = quelle_pfad
	laden()

func laden() -> bool:
	eintraege_nach_id.clear()
	eintraege.clear()
	if _quelle_pfad == "" or not FileAccess.file_exists(_quelle_pfad):
		if _quelle_pfad != "":
			push_warning("Registry-Quelle nicht gefunden: %s" % _quelle_pfad)
		return false
	var datei := FileAccess.open(_quelle_pfad, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	return _eintraege_uebernehmen(gelesen)

func _eintraege_uebernehmen(_gelesen: Variant) -> bool:
	# Unterklassen übersetzen die Rohdaten in ihre exakten Datenklassen.
	return false

func registrieren(id: String, eintrag: RefCounted) -> void:
	if eintraege_nach_id.has(id):
		push_warning("Registry '%s': doppelte id '%s'" % [schema_name(), id])
		return
	eintraege_nach_id[id] = eintrag
	eintraege.append(eintrag)

func schema_name() -> String:
	# Der Preflight liest diesen Namen als Kategorie-Referenz.
	return "RegistryBasis"

func eintrag_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in eintraege_nach_id.keys():
		ids.append(id)
	ids.sort()
	return ids

func hat_eintrag(id: String) -> bool:
	return eintraege_nach_id.has(id)

func finde_eintrag(id: String) -> RefCounted:
	if eintraege_nach_id.has(id):
		return eintraege_nach_id[id]
	return null

func anzahl() -> int:
	return eintraege.size()

func datenfeld_arten() -> Dictionary:
	# Der Preflight prüft daraus, welche Datenfelder jede Kategorie bereitstellt.
	return {"eintraege": "Array", "eintraege_nach_id": "Dictionary"}
