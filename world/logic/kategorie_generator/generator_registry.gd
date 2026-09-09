extends Welt_RegistryBasis
class_name Welt_GeneratorRegistry
## Finale Registry des Weltgenerators. Neue Objekte, Gegner, Tiere, Fraktionen
## oder Gebäude werden nur hier nachgetragen: je Eintrag mit Spawn-Gewichtung,
## Ressourcen-Wert und Biom-Bevorzugung. Der Generator nimmt ausschließlich die
## hier gelisteten Dinge und berechnet daraus die Verteilung; er erfindet nichts.

const KATALOG_PFAD := "res://world/data/generator_gewichte.json"

## Kategorie daten: Gewichte je Eintrag mit Werten aus der Gewichte-Datei.
var _gewichte_nach_id: Dictionary = {}

## Kategorie logik: Laden und gewichtete Auslesen.

func _init() -> void:
	super(KATALOG_PFAD)

func schema_name() -> String:
	return "Welt_GeneratorRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Generator-Gewichte haben ein ungueltiges Format: %s" % KATALOG_PFAD)
		return false
	_gewichte_nach_id.clear()
	eintraege.clear()
	eintraege_nach_id.clear()
	for eintrag_id: String in (gelesen as Dictionary).keys():
		var wert: Variant = (gelesen as Dictionary)[eintrag_id]
		if eintrag_id.begins_with("_") or typeof(wert) != TYPE_DICTIONARY:
			continue
		_gewichte_nach_id[eintrag_id] = (wert as Dictionary).duplicate(true)
		registrieren(eintrag_id, null)
	return true

func ids_mit_gewicht(kategorie: String) -> Array[String]:
	# Liefert alle Eintrags-IDs einer Kategorie (objekte, tiere, biome, gebaeude),
	# sortiert, damit der Generator deterministisch läuft.
	var treffer: Array[String] = []
	for eintrag_id: String in _gewichte_nach_id.keys():
		var wort: Dictionary = _gewichte_nach_id[eintrag_id]
		if str(wort.get("kategorie", "")) == kategorie and float(wort.get("gewicht", 0.0)) > 0.0:
			treffer.append(eintrag_id)
	treffer.sort()
	return treffer

func gewicht_fuer(eintrag_id: String) -> float:
	return float((_gewichte_nach_id.get(eintrag_id, {}) as Dictionary).get("gewicht", 0.0))

func biom_vorliebe_fuer(eintrag_id: String) -> Array[String]:
	var vorliebe: Variant = (_gewichte_nach_id.get(eintrag_id, {}) as Dictionary).get("biome", [])
	var ergebnis: Array[String] = []
	if typeof(vorliebe) == TYPE_ARRAY:
		for biom_id: Variant in (vorliebe as Array):
			ergebnis.append(str(biom_id))
	return ergebnis

func element_pfad_fuer(eintrag_id: String) -> String:
	return str((_gewichte_nach_id.get(eintrag_id, {}) as Dictionary).get("element_id", eintrag_id))

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["gewichte"] = "Dictionary"
	return arten
