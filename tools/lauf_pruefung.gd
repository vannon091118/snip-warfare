extends SceneTree
## Temporäre Lauf-Prüfung: Registries liefern echte Einträge, das
## Mutationsschema liefert bei gleichem Startzustand identische Ergebnisse.

func _init() -> void:
	var registry := Welt_Registry.new()
	print("Registry-Kategorien: ", registry.kategorien())
	print("Terrain/Natur/Gebaeude: ", registry.terrain().anzahl(), "/", registry.natur().anzahl(), "/", registry.gebaeude().anzahl())
	print("Baum ueber Fassade: ", registry.finde_objekt("baum") != null, ", ueber Natur: ", registry.natur().baum("baum") != null)
	var tier_registry := Tier_Registry.new()
	print("Tier-Arten: ", tier_registry.eintrag_ids())
	var schema := Einheit_RessourcenSchema.new()
	var start := {"erntebuchung": {"ressource": "holz", "menge": 10}}
	var ergebnis_eins := schema.ausfuehren(start)
	var schema_zwei := Einheit_RessourcenSchema.new()
	var ergebnis_zwei := schema_zwei.ausfuehren(start)
	print("Lauf 1: ", str(ergebnis_eins["bestaende"]), " Zufall: ", schema.zufall.zustaende_als_wort())
	print("Lauf 2: ", str(ergebnis_zwei["bestaende"]), " Zufall: ", schema_zwei.zufall.zustaende_als_wort())
	if str(ergebnis_eins["bestaende"]) != str(ergebnis_zwei["bestaende"]):
		push_error("Determinismus verletzt: gleiche Startzustaende, verschiedene Ergebnisse")
		quit(1)
		return
	quit(0)
