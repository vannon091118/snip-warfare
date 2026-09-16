extends Welt_ModellMigration
class_name Welt_ModellSpeicher
## Siebte Stufe der Kette: Der Woerterbuch-Rundlauf. Diese Stufe allein
## kennt das Speicherformat und wandelt Zustand in Woerterbuch und zurueck.

func nach_woerterbuch() -> Dictionary:
	return {
		"version": SPEICHER_VERSION,
		"kachel_groesse": kachel_groesse,
		"chunk_groesse": chunk_groesse,
		"raster_breite": raster_breite,
		"raster_hoehe": raster_hoehe,
		"raster": raster,
		"biom_raster": biom_raster,
		"objekte": objekte,
		"biom_id": biom_id,
		"region_kante": region_kante,
		"regionen": regionen,
		"welt_seed": welt_seed,
		"map_id": map_id,
		"aktive_z_ebene": aktive_z_ebene,
	}

func aus_woerterbuch(daten: Dictionary) -> bool:
	if daten.is_empty():
		return false
	var version := int(daten.get("version", 3))
	if version < MIN_KOMPATIBLE_VERSION:
		push_warning("Welt zu alt: Version %d < %d, Migration nicht möglich" % [version, MIN_KOMPATIBLE_VERSION])
		return false
	raster_breite = clampi(int(daten.get("raster_breite", RASTER_BREITE)), RASTER_MIN, RASTER_MAX)
	raster_hoehe = clampi(int(daten.get("raster_hoehe", RASTER_HOEHE)), RASTER_MIN, RASTER_MAX)
	kachel_groesse = maxi(int(daten.get("kachel_groesse", KACHEL_GROESSE)), 1)
	chunk_groesse = maxi(int(daten.get("chunk_groesse", 8)), 1)
	biom_id = str(daten.get("biom_id", "gemaaessigt"))
	biom_manager().biom_wechseln(biom_id)
	aktive_z_ebene = int(daten.get("aktive_z_ebene", 0))
	_raster_anlegen("boden")
	_raster_einlesen(daten)
	_objekte_einlesen(daten)
	_regionen_einlesen(daten)
	_eskalation_anwenden(version)
	return true

func _raster_einlesen(daten: Dictionary) -> void:
	# Format: Dictionary mit "x:y:z" Schluesseln.
	var neues_raster: Variant = daten.get("raster", {})
	if typeof(neues_raster) == TYPE_DICTIONARY:
		for schluessel: String in neues_raster:
			raster[schluessel] = str(neues_raster[schluessel])
	var neues_biom_raster: Variant = daten.get("biom_raster", {})
	if typeof(neues_biom_raster) == TYPE_DICTIONARY:
		for schluessel: String in neues_biom_raster:
			biom_raster[schluessel] = str(neues_biom_raster[schluessel])

func _objekte_einlesen(daten: Dictionary) -> void:
	objekte.clear()
	_naechste_objekt_nummer = 1
	var neue_objekte: Variant = daten.get("objekte", [])
	if typeof(neue_objekte) == TYPE_ARRAY:
		for eintrag: Variant in neue_objekte:
			if typeof(eintrag) == TYPE_DICTIONARY and eintrag.has("element_id") and eintrag.has("position"):
				_objekt_einlesen(eintrag)

func _objekt_einlesen(eintrag: Dictionary) -> void:
	var position_werte: Array = eintrag["position"]
	var objekt_index := objekt_hinzufuegen(str(eintrag["element_id"]), Vector2(position_werte[0], position_werte[1]))
	# Die fachliche Objekt-Nummer uebersteht den Rundlauf: Entfernte
	# Objekte hinterlassen Luecken, und ohne diese Rueckgabe rueckt jedes
	# folgende Objekt beim Laden eine Nummer weiter.
	var gespeicherte_nummer := int(eintrag.get("id", 0))
	if gespeicherte_nummer > 0:
		objekt_feld_setzen(objekt_index, "id", gespeicherte_nummer)
		_naechste_objekt_nummer = maxi(_naechste_objekt_nummer, gespeicherte_nummer + 1)
	# Zusatzfelder (Gebaeudezustand, Fortschritte) muessen den
	# Speicher-Rundlauf ueberstehen: alle fremden Schluessel kopieren.
	for schluessel: String in eintrag.keys():
		if schluessel == "id" or schluessel == "element_id" or schluessel == "position":
			continue
		objekt_feld_setzen(objekt_index, schluessel, eintrag[schluessel])

func _regionen_einlesen(daten: Dictionary) -> void:
	regionen.clear()
	region_kante = maxi(int(daten.get("region_kante", 4)), 1)
	welt_seed = int(daten.get("welt_seed", 0))
	map_id = str(daten.get("map_id", ""))
	var neue_regionen: Variant = daten.get("regionen", [])
	if typeof(neue_regionen) == TYPE_ARRAY:
		for region: Variant in neue_regionen:
			if typeof(region) == TYPE_DICTIONARY and (region as Dictionary).has("region_x") and (region as Dictionary).has("region_y"):
				var wort := region as Dictionary
				regionen.append({
					"region_x": int(wort.get("region_x", 0)),
					"region_y": int(wort.get("region_y", 0)),
					"biom_id": str(wort.get("biom_id", biom_id)),
					"seed_beitrag": int(wort.get("seed_beitrag", 0)),
					"chunk_kante": int(wort.get("chunk_kante", 2)),
				})
