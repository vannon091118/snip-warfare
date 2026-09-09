extends RefCounted
class_name Kern_ModifikatorBasis
## Datenklasse eines Modifikators. Ein Modifikator ist eine eigene Klasse
## mit einem Faktor. Der Faktor 1.0 bedeutet 10 Sekunden Takt; die Ticks
## ergeben sich aus der globalen Weltuhr (faktor * 10 Sekunden in Ticks).
## Objekte und Tiere kombinieren eine Logik mit einem Modifikator über ihre
## Registries; damit entstehen Varianten ohne neue Verhaltensklassen.

var modifikator_id: String = ""
var angezeigter_name: String = ""
var faktor: float = 1.0
var beschreibung: String = ""

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	modifikator_id = eintrag_id
	angezeigter_name = str(eintrag.get("name", eintrag_id))
	faktor = float(eintrag.get("faktor", 1.0))
	beschreibung = str(eintrag.get("beschreibung", ""))
