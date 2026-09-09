extends RefCounted
class_name Welt_Model
## Datenhaltung einer Welt: Fliesenraster plus Liste platzierter Objekte.
## RT-Pyramide: Basisobjekt der Pyramide. Darauf stehen Registries und
## Mutationen. Das aktive Biom wirkt über die Mutationsmaschine auf den
## Zustand, nie direkt auf die Daten. Karten sind relativ groß: 32x24 Kacheln à 512 Pixel.

## Kategorie daten: Raster und Objektliste, ausschließlich durch eigene Funktionen geändert.
const KACHEL_GROESSE := 512
const RASTER_BREITE := 32
const RASTER_HOEHE := 24
const RASTER_MIN := 4
const RASTER_MAX := 64

## Kategorie daten: Regionen als räumliche Makrostruktur der Welt.
## Jede Region trägt Biom, Seed-Beitrag und Chunk-Anzahl; Chunks sind die
## technische Partition (Generator-Groesse), Objekte die konkreten Inhalte.
var regionen: Array[Dictionary] = []
var region_kante: int = 4
var welt_seed: int = 0
const SPEICHER_VERSION := 5
const MIN_KOMPATIBLE_VERSION := 2

## Kategorie logik: Aufbau, Änderung und Ein-/Auslesen der Welt-Daten.
var raster_breite: int = RASTER_BREITE
var raster_hoehe: int = RASTER_HOEHE
var raster: Array[String] = []
var objekte: Array[Dictionary] = []
var biom_id: String = "gemaaessigt"
var _naechste_objekt_nummer: int = 1
var _biom_manager: Welt_BiomManager = null
var _welt_registry: Welt_Registry = null

func _init() -> void:
	ueberziehe_fliesen("boden")

func _raster_anlegen(element_id: String) -> void:
	raster.clear()
	for _i in raster_breite * raster_hoehe:
		raster.append(element_id)

func karte_erzeugen(breite: int, hoehe: int, element_id: String) -> void:
	raster_breite = clampi(breite, RASTER_MIN, RASTER_MAX)
	raster_hoehe = clampi(hoehe, RASTER_MIN, RASTER_MAX)
	ueberziehe_fliesen(element_id)

func groesse() -> Vector2i:
	return Vector2i(raster_breite, raster_hoehe)

func ueberziehe_fliesen(element_id: String) -> void:
	_raster_anlegen(element_id)

func ist_in_raster(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < raster_breite and y < raster_hoehe

func fliese_setzen(x: int, y: int, element_id: String) -> void:
	if not ist_in_raster(x, y):
		return
	raster[y * raster_breite + x] = element_id

func fliese(x: int, y: int) -> String:
	if not ist_in_raster(x, y):
		return ""
	return raster[y * raster_breite + x]

func objekt_hinzufuegen(element_id: String, position: Vector2) -> int:
	var nummer := _naechste_objekt_nummer
	_naechste_objekt_nummer += 1
	objekte.append({
		"id": nummer,
		"element_id": element_id,
		"position": [position.x, position.y],
	})
	return nummer

func objekt_position(index: int) -> Vector2:
	var position_werte: Array = objekte[index]["position"]
	return Vector2(position_werte[0], position_werte[1])

func objekt_verschieben(index: int, neue_position: Vector2) -> void:
	objekte[index]["position"] = [neue_position.x, neue_position.y]

func objekt_entfernen(index: int) -> void:
	objekte.remove_at(index)

func objekt_anzahl() -> int:
	return objekte.size()

func objekt_element_id(index: int) -> String:
	if index < 0 or index >= objekte.size():
		return ""
	return str(objekte[index].get("element_id", ""))

func objekt_daten(index: int) -> Dictionary:
	if index < 0 or index >= objekte.size():
		return {}
	return objekte[index]

func objekt_feld(index: int, schluessel: String, default: Variant = null) -> Variant:
	# Gelesener Zustand eines Objekt-Feldes (zum Beispiel Gebäudezustand);
	# die Daten gehören dem Modell, Fremde lesen nur über diese Schnittstelle.
	if index < 0 or index >= objekte.size():
		return default
	return objekte[index].get(schluessel, default)

func objekt_feld_setzen(index: int, schluessel: String, wert: Variant) -> void:
	# Einzige Schreibstelle für Zusatzfelder am Objekt (Gebäudezustand,
	# Fortschritte); der Besitzer bleibt dieses Modell.
	if index < 0 or index >= objekte.size():
		return
	objekte[index][schluessel] = wert

func objekte_mit_element_id(element_id: String) -> Array[int]:
	# Alle Objekt-Indizes einer Element-Art; für Gebäude- und Statusabfragen.
	var treffer: Array[int] = []
	for index in objekte.size():
		if str(objekte[index].get("element_id", "")) == element_id:
			treffer.append(index)
	return treffer

func objekt_ids() -> Array[String]:
	var ids: Array[String] = []
	for eintrag in objekte:
		ids.append(str(eintrag.get("element_id", "")))
	return ids

func objekt_bei(ziel: Vector2, such_radius: float) -> int:
	# Gibt den Index des Objekts zurück, das den Punkt (nahe) abdeckt; sonst -1.
	# Für die Trefferprüfung wird nur die Datenklasse Objekt_Basis gelesen;
	# hier fließt keine Logik einer anderen Domäne ein.
	if _welt_registry == null:
		_welt_registry = Welt_Registry.new()
	var registry := _welt_registry
	var bester_index := -1
	var beste_flaeche := INF
	for index in objekte.size():
		var objekt: Objekt_Basis = registry.finde_objekt(str(objekte[index]["element_id"]))
		if objekt == null:
			continue
		var halbe_breite := objekt.anzeige_breite / 2.0
		var hoehe := objekt.anzeige_hoehe
		var mitte := objekt_position(index) + Vector2(0, -hoehe / 2.0)
		var abstand := (mitte - ziel).abs()
		if abstand.x <= halbe_breite + such_radius and abstand.y <= hoehe / 2.0 + such_radius:
			var flaeche := halbe_breite * hoehe
			if flaeche < beste_flaeche:
				beste_flaeche = flaeche
				bester_index = index
	return bester_index

func biom_setzen(neues_biom_id: String) -> bool:
	if _biom_manager == null:
		_biom_manager = Welt_BiomManager.new()
	if not _biom_manager.biom_wechseln(neues_biom_id):
		return false
	biom_id = neues_biom_id
	return true

func biom_manager() -> Welt_BiomManager:
	if _biom_manager == null:
		_biom_manager = Welt_BiomManager.new()
		_biom_manager.biom_wechseln(biom_id)
	return _biom_manager

func biom_zustand() -> Dictionary:
	# Einziger Ort der die Biom Mutation als Zustand ausfuehrt.
	var manager := biom_manager()
	var basis := {"biom_id": biom_id, "raster_breite": raster_breite, "raster_hoehe": raster_hoehe}
	return manager.zustand_fuer_tick(basis)

func objekte_leeren() -> void:
	objekte.clear()

func regionen_leeren() -> void:
	regionen.clear()

func region_ergaenzen(region_x: int, region_y: int, biom: String, seed_beitrag: int, chunk_kante: int) -> void:
	regionen.append({
		"region_x": region_x,
		"region_y": region_y,
		"biom_id": biom,
		"seed_beitrag": seed_beitrag,
		"chunk_kante": chunk_kante,
	})

func region_an(position: Vector2) -> Dictionary:
	# Liefert die Region der Kachel unter der Welt-Position; sonst leer.
	var kachel_x := int(position.x / Welt_Model.KACHEL_GROESSE)
	var kachel_y := int(position.y / Welt_Model.KACHEL_GROESSE)
	return region_an_kachel(kachel_x, kachel_y)

func region_an_kachel(kachel_x: int, kachel_y: int) -> Dictionary:
	for region: Dictionary in regionen:
		var start_x := int(region.get("region_x", 0)) * region_kante
		var start_y := int(region.get("region_y", 0)) * region_kante
		if kachel_x >= start_x and kachel_x < start_x + region_kante and kachel_y >= start_y and kachel_y < start_y + region_kante:
			return region
	return {}

func biom_an_kachel(kachel_x: int, kachel_y: int) -> String:
	# Einziger Ort der die Biom-Zugehörigkeit einer Kachel ableitet:
	# Region zuerst, sonst das globale Welt-Biom.
	var region := region_an_kachel(kachel_x, kachel_y)
	if not region.is_empty():
		return str(region.get("biom_id", biom_id))
	return biom_id

func nach_woerterbuch() -> Dictionary:
	return {
		"version": SPEICHER_VERSION,
		"kachel_groesse": KACHEL_GROESSE,
		"raster_breite": raster_breite,
		"raster_hoehe": raster_hoehe,
		"raster": raster,
		"objekte": objekte,
		"biom_id": biom_id,
		"region_kante": region_kante,
		"regionen": regionen,
		"welt_seed": welt_seed,
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
	biom_id = str(daten.get("biom_id", "gemaaessigt"))
	biom_manager().biom_wechseln(biom_id)
	_raster_anlegen("boden")
	var neues_raster: Variant = daten.get("raster", [])
	if typeof(neues_raster) == TYPE_ARRAY:
		var index := 0
		for wert: Variant in neues_raster:
			if index >= raster.size():
				break
			raster[index] = str(wert)
			index += 1
	objekte.clear()
	_naechste_objekt_nummer = 1
	var neue_objekte: Variant = daten.get("objekte", [])
	if typeof(neue_objekte) == TYPE_ARRAY:
		for eintrag: Variant in neue_objekte:
			if typeof(eintrag) == TYPE_DICTIONARY and eintrag.has("element_id") and eintrag.has("position"):
				var position_werte: Array = eintrag["position"]
				var objekt_index := objekt_hinzufuegen(str(eintrag["element_id"]), Vector2(position_werte[0], position_werte[1]))
				# Zusatzfelder (Gebäudezustand, Fortschritte) müssen den
				# Speicher-Rundlauf überstehen: alle fremden Schlüssel kopieren.
				for schluessel: String in (eintrag as Dictionary).keys():
					if schluessel == "id" or schluessel == "element_id" or schluessel == "position":
						continue
					objekt_feld_setzen(objekt_index, schluessel, (eintrag as Dictionary)[schluessel])
	regionen.clear()
	region_kante = maxi(int(daten.get("region_kante", 4)), 1)
	welt_seed = int(daten.get("welt_seed", 0))
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
	_eskalation_anwenden(version)
	return true

func _eskalation_anwenden(geladene_version: int) -> void:
	# Abwärtskompatibel: Neue Systeme ab Update in neu generierten Chunks,
	# alte Saves bleiben lesbar. Version 5 führt welt_seed und erweiterte
	# Regionen ein; fehlende Felder werden deterministisch ergänzt.
	if geladene_version >= SPEICHER_VERSION:
		return
	if geladene_version < 5:
		# Version 4 hatte region_kante als 4, Chunk-Kante war 2 — ab 5
		# ist die Generator-Konvention Chunk 8, Region 4 bindend.
		if regionen.is_empty() and welt_seed == 0:
			# Alter Save ohne Seed: deterministisch aus biom_id ableiten,
			# damit gleiche alte Welt nicht zufällig neu würfelt.
			welt_seed = int(hash(biom_id) & 0x7FFFFFFF)
		for region in regionen:
			if int(region.get("chunk_kante", 0)) == 2:
				region["chunk_kante"] = Welt_Generator.CHUNK_GROESSE
