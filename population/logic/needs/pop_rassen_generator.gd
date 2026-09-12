extends RefCounted
class_name Pop_RassenGenerator
## Rassen-Generator: Erzeugt Pop_RassenSchema aus Keimpunkt-Archetypen.
## Liest den dominanten Archetyp jedes Keimpunkts aus dem
## Fraktions-Keimling-Analysator, zieht mit Kern_Zufall.abgeleitet_fuer
## deterministische Werte aus den Bereichen (Min/Max) der
## rassen_vorlagen.json und registriert das finalisierte Schema in der
## Pop_RassenSchemaRegistry. Namen entstehen pro Archetyp über den
## Pop_NamensGenerator, damit derselbe Seed dieselben Rassen hervorbringt.

## Kategorie daten: Konfigurationspfad und Vorlagen-Zuordnung.
var vorlagen_pfad := "res://population/data/rassen_vorlagen.json"
var _registry: Pop_RassenSchemaRegistry = null

func registry_setzen(registry: Pop_RassenSchemaRegistry) -> void:
	_registry = registry
## Mapping: Archetyp -> Vorlagen-Key in rassen_vorlagen.json. Die Vorlagen
## tragen denselben Namen wie der Archetyp, deshalb bildet die Tabelle
## bewusst identisch ab und hält nur die eine Übersetzungsstelle.
const ARCHETYP_ZU_VORLAGE: Dictionary = {
	"wald": "wald",
	"berg": "berg",
	"wasser": "wasser",
	"steppe": "steppe",
	"tundra": "tundra",
}

## Kategorie logik: Generierung aus Keimpunkten.

func _init() -> void:
	pass

func generiere_aus_keimpunkten(keimpunkte: Array[Dictionary], welt_seed: int) -> void:
	## Für jeden Keimpunkt das passende Rassen-Schema generieren
	var vorlagen := _lade_vorlagen()
	for keimpunkt: Dictionary in keimpunkte:
		var archetyp := str(keimpunkt.get("dominante_archetyp", "wald"))
		var keimpunkt_id := str(keimpunkt.get("zellen_id", ""))

		## Hole die Vorlagen-Range für diesen Archetyp
		var vorlagen_key := str(ARCHETYP_ZU_VORLAGE.get(archetyp, "wald"))
		if not vorlagen.has(vorlagen_key):
			push_warning("Keine Vorlage für Archetyp %s (Key: %s) gefunden" % [archetyp, vorlagen_key])
			continue

		var vorlage: Dictionary = vorlagen[vorlagen_key]
		var rassen_id := _generiere_rassen_id(archetyp, keimpunkt_id, welt_seed)

		## Generiere deterministischen Namen für diese Rasse
		var rassen_name := Pop_NamensGenerator.generiere_rassen_name(archetyp, keimpunkt_id, welt_seed)

		## Erstelle neues Schema
		var neue_rasse := Pop_RassenSchema.new()
		neue_rasse._initialisiere_generiert(rassen_id, rassen_name, str(vorlage.get("beschreibung", "")))

		## Deterministischer RNG für diese Rasse (Seed + Keimpunkt + Archetyp)
		var rassen_rng := Kern_Zufall.abgeleitet_fuer(welt_seed, Pop_NamensGenerator.hash(keimpunkt_id + "_werte_" + archetyp))

		## Jeden Wertbereich zeichnen: Float-Range [min, max]
		var werte: Dictionary = vorlage.get("werte", {})
		for wert_name: String in werte:
			var bereich: Array = werte[wert_name]
			if bereich.size() < 2:
				continue
			var min_wert := float(bereich[0])
			var max_wert := float(bereich[1])
			var spanne := max_wert - min_wert

			## Ziehe deterministischen Float-Wert aus Bereich:
			## Nächste 64-Bit-Zahl -> normalisiert auf [0,1] -> skaliert auf [min, max]
			var rohwert := float(rassen_rng.naechste_zahl()) / float(0x7FFFFFFFFFFFFFFF)
			var gezogener_wert := min_wert + rohwert * spanne

			## Werte direkt in das Schema schreiben (vor Immutabilität)
			match wert_name:
				"nahrung_konsum":
					neue_rasse._faktor_nahrung_setzen(gezogener_wert)
				"dringlichkeit":
					neue_rasse._faktor_dringlichkeit_setzen(gezogener_wert)
				"abfall_rate":
					neue_rasse._faktor_abfall_setzen(gezogener_wert)
				"bewegung":
					neue_rasse._faktor_bewegung_setzen(gezogener_wert)
				"grab_bonus":
					neue_rasse._grab_bonus_setzen(gezogener_wert)
				_:
					pass

		## Icon-Pfad basierend auf Archetyp setzen
		neue_rasse._icon_pfad_setzen(_archetyp_zu_icon(archetyp))

		## Schema finalisieren (immutable machen) und registrieren
		neue_rasse._finalisieren()
		if _registry != null:
			_registry.registriere_generiert(rassen_id, neue_rasse)

func _generiere_rassen_id(archetyp: String, keimpunkt_id: String, welt_seed: int) -> String:
	## Deterministische ID: archetyp_keimpunkt_seedhash
	var seed_hash := Pop_NamensGenerator.hash(str(welt_seed) + "_" + keimpunkt_id)
	return "%s_%s_%d" % [archetyp, keimpunkt_id, seed_hash % 10000]

func _archetyp_zu_icon(archetyp: String) -> String:
	match archetyp:
		"wald":
			return "res://world/assets/ui/ressource_raeuchelfleisch.svg"
		"wasser":
			return "res://world/assets/ui/ressource_fisch.svg"
		"berg":
			return "res://world/assets/ui/ressource_fleisch.svg"
		"steppe":
			return "res://world/assets/ui/ressource_fleisch.svg"
		"tundra":
			return "res://world/assets/ui/ressource_fleisch.svg"
		_:
			return "res://world/assets/ui/ressource_fleisch.svg"

func _lade_vorlagen() -> Dictionary:
	## Lade rassen_vorlagen.json als einzige Quelle der Wertebereiche.
	if FileAccess.file_exists(vorlagen_pfad):
		var datei := FileAccess.open(vorlagen_pfad, FileAccess.READ)
		if datei != null:
			var gelesen: Variant = JSON.parse_string(datei.get_as_text())
			datei.close()
			if typeof(gelesen) == TYPE_DICTIONARY:
				return gelesen
	push_warning("Rassen-Vorlagen nicht lesbar: %s" % vorlagen_pfad)
	return {}
