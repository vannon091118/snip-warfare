extends RefCounted
class_name Welt_RegistryKlassenZuordnung
## Zentrale Klassen-Zuordnung der Welt-Registry: Sie entscheidet je
## Element-ID, welche konkrete Objekt_Basis-Klasse den Katalog-Eintrag
## trägt. Die Zuordnung ist eine Tabelle, keine Logik; neue Objekte mit
## script-Feld laufen ohnehin über den Plugin-Naht der Registry-Basis.

## Kategorie daten: die ID-zu-Klassen-Tabelle.
const ZUORDNUNG := {
	"baum": "Objekt_Baum",
	"baum_stumpf": "Objekt_Baumstumpf",
	"stein": "Objekt_Stein",
	"steine_gruppe": "Objekt_Steingruppe",
	"berg": "Objekt_Berg",
	"felswand": "Objekt_Felswand",
	"erzader": "Objekt_Erzader",
	"ruine": "Objekt_Ruine",
	"steinkreis": "Objekt_Steinkreis",
	"haus": "Objekt_Haus",
	"haus_gross": "Objekt_Hausgross",
	"kadaver": "Objekt_Kadaver",
	"lagerfeuer": "Objekt_Lagerfeuer",
	"tisch": "Objekt_Tisch",
	"stuhl": "Objekt_Stuhl",
	"betten": "Objekt_Bett",
	"schrank": "Objekt_Schrank",
	"tisch_stahl": "Objekt_TischStahl",
	"boden": "Objekt_Kachel",
	"wiese": "Objekt_Kachel",
}

## Kategorie logik: die reine Anfrage über die Tabelle.

static func klasse_name_fuer(element_id: String) -> String:
	return str(ZUORDNUNG.get(element_id, ""))
