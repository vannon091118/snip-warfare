extends RefCounted
class_name Pop_RassenSchema
## Datenklasse eines Rassen-Schemas. Reines Einlesen aus rassen_schemata.json.
## Jede Rasse trägt Multiplikatoren, mit denen die Need-Maschinen ihre Werte
## skalieren: Nahrungsverbrauch, Dringlichkeit, Abfall, Schwellwert und
## Bewegung. Der zentrale Modifikator-Faktor multipliziert zusätzlich; das
## Schema selbst enthält keine Logik und ruft nichts auf.

var rasse_id: String = ""
var angezeigter_name: String = ""
var beschreibung: String = ""
var faktor_nahrung: float = 1.0
var faktor_dringlichkeit: float = 1.0
var faktor_abfall: float = 1.0
var faktor_schwellwert: float = 1.0
var faktor_bewegung: float = 1.0
var icon_pfad: String = ""

func aus_eintrag(eintrag_id: String, eintrag: Dictionary) -> void:
	rasse_id = eintrag_id
	angezeigter_name = str(eintrag.get("name", eintrag_id))
	beschreibung = str(eintrag.get("beschreibung", ""))
	faktor_nahrung = float(eintrag.get("faktor_nahrung", 1.0))
	faktor_dringlichkeit = float(eintrag.get("faktor_dringlichkeit", 1.0))
	faktor_abfall = float(eintrag.get("faktor_abfall", 1.0))
	faktor_schwellwert = float(eintrag.get("faktor_schwellwert", 1.0))
	faktor_bewegung = float(eintrag.get("faktor_bewegung", 1.0))
	icon_pfad = str(eintrag.get("icon_pfad", ""))