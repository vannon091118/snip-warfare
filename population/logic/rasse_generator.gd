extends RefCounted
class_name Bevölkerung_RassenGenerator
## Rassen_Generator: Erzeugt Pop_RassenSchema aus Keimpunkt-Archetypen.
-- Liest Archetyp jeder Keimpunkt aus dem Fraktions_Keimling_Analysator.
-- Zeichnet mit Kern_Zufall.abgeleitet_fuer("rasse", keimpunkt_id) Werte.
-- Zieht aus Bereichen (Min/Max) in rassen_vorlagen.json anstatt fester Zahlen.
-- Ergebnis: vollständig instantiertes, immutables Pop_RassenSchema.
-- Pop_RassenSchemaRegistry registriert unter generiertem rassen_id.
-- Generiert auch deterministische Namen pro Archetyp via Pop_NamensGenerator.

## Kategorie daten: Konfigurationspfad für Rassen-Vorlagen.
var vorlagen_pfad := "res://population/data/rassen_vorlagen.json"

## Mapping: Archetyp -> Vorlagen-Key in rassen_vorlagen.json
const ARCHETYP_ZU_VORLAGE: Dictionary = {
	"wald": "elf",
	"berg": "ork",
	"wasser": "mensch",
	"steppe": "mensch",
	"tundra": "ork"
}

## Kategorie logik: Generiere Rassen-Schemata aus Keimpunkten.

func _init() -> void:
	pass

func generiere_aus_keimpunkten(keimpunkte: Array[Dictionary], welt_seed: int) -> void:
	## Für jeden Keimpunkt das passende Rassen-Schema generieren
	for keimpunkt in keimpunkte:
		var archetyp := keimpunkt.dominante_archetyp
		var keimpunkt_id := keimpunkt.zellen_id

		## Hole die Vorlagen-Range für diesen Archetyp
		var vorlagen := _lade_vorlagen()
		var vorlagen_key := ARCHETYP_ZU_VORLAGE.get(archetyp, "mensch")
		if not vorlagen.has(vorlagen_key):
			push_warning("Keine Vorlage für Archetyp %s (Key: %s) gefunden" % [archetyp, vorlagen_key])
			continue

		var vorlage := vorlagen[vorlagen_key]
		var rassen_id := _generiere_rassen_id(archetyp, keimpunkt_id, welt_seed)

		## Generiere deterministischen Namen für diese Rasse
		var rassen_name := Pop_NamensGenerator.generiere_rassen_name(archetyp, keimpunkt_id, welt_seed)

		## Erstelle neues Schema
		var neue_rasse := Pop_RassenSchema.new()
		neue_rasse._initialisiere_generiert(rassen_id, rassen_name, vorlage.beschreibung)

		## Deterministischer RNG für diese Rasse (Seed + Keimpunkt + Archetyp)
		var rassen_rng := Kern_Zufall.abgeleitet_fuer(welt_seed, Pop_NamensGenerator.hash(keimpunkt_id + "_werte_" + archetyp))

		## Jeden Wertbereich zeichnen: Float-Range [min, max]
		for wert_name, bereich in vorlage.werte:
			var min_wert := float(bereich[0])
			var max_wert := float(bereich[1])
			var spanne := max_wert - min_wert

			## Ziehe deterministischen Float-Wert aus Bereich
			## Nächste 64-bit Zahl -> normalisiert auf [0,1] -> skaliert auf [min, max]
			var rohrwert := float(rassen_rng.naechste_zahl()) / float(0x7FFFFFFFFFFFFFFF)
			var gezogener_wert := min_wert + rohrwert * spanne

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
				_: pass

		## Icon-Pfad basierend auf Archetyp setzen
		neue_rasse._icon_pfad_setzen(_archetyp_zu_icon(archetyp))

		## Schema finalisieren (immutable machen)
		neue_rasse._finalisieren()

		## Registriere das unveränderliche Schema in der Registry
		Pop_RassenSchemaRegistry.registriere_generiert(rassen_id, neue_rasse)

func _generiere_rassen_id(archetyp: String, keimpunkt_id: String, welt_seed: int) -> String:
	## Deterministische ID: archetyp_keimpunkt_seedhash
	var seed_hash := Pop_NamensGenerator.hash(str(welt_seed) + "_" + keimpunkt_id)
	return "%s_%s_%d" % [archetyp, keimpunkt_id, seed_hash % 10000]

func _archetyp_zu_icon(archetyp: String) -> String:
	match archetyp:
		"wald": return "res://world/assets/ui/ressource_raeuchelfleisch.svg"
		"berg": return "res://world/assets/ui/ressource_fleisch.svg"
		"wasser": return "res://world/assets/ui/ressource_fisch.svg"
		"steppe": return "res://world/assets/ui/ressource_fleisch.svg"
		"tundra": return "res://world/assets/ui/ressource_fleisch.svg"
		_: return "res://world/assets/ui/ressource_fleisch.svg"

func _lade_vorlagen() -> Dictionary:
	## Lade rassen_vorlagen.json
	if FileAccess.file_exists(vorlagen_pfad):
		var text := FileAccess.open(vorlagen_pfad, FileAccess.READ).get_as_text()
		return JSON.parse_string(text)
	return {}