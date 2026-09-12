extends RefCounted
class_name Welt_Model
## Datenhaltung einer Welt: Fliesenraster plus Liste platzierter Objekte.
## RT-Pyramide: Basisobjekt der Pyramide. Darauf stehen Registries und
## Mutationen. Das aktive Biom wirkt über die Mutationsmaschine auf den
## Zustand, nie direkt auf die Daten. Karten sind relativ groß: 32x24 Kacheln à 512 Pixel.

## Kategorie daten: Raster und Objektliste, ausschließlich durch eigene Funktionen geändert.
## KACHEL_GROESSE ist nur der RUECKFALL fuer Testlaeufe ohne Definitions-Registry;
## im Spiel setzt der Generator den Wert aus world/data/welt_definition.json
## ueber kachel_groesse_setzen. Es gibt damit genau eine Quelle je Lauf.
## Zusatz: Z-Ebene (höhe). Standard 0, negativ = Untergrund.
const KACHEL_GROESSE := 512
const RASTER_BREITE := 32
const RASTER_HOEHE := 24
const RASTER_MIN := 4
const RASTER_MAX := 128
const MAX_Z_EBENEN := 5 ## 0 (Oberfläche) bis -4 (Tiefster Untergrund)
var aktive_z_ebene: int = 0 ## Standard 0, negativ = Untergrund

## Kategorie daten: Regionen als räumliche Makrostruktur der Welt.
## Jede Region trägt Biom, Seed-Beitrag und Chunk-Anzahl; Chunks sind die
## technische Partition (Generator-Groesse), Objekte die konkreten Inhalte.
var regionen: Array[Dictionary] = []
var region_kante: int = 4
var welt_seed: int = 0
## map_id: Kennung dieser Karte innerhalb einer World. Leer bedeutet, dass
## die Karte als eigenständige Einzelwelt geführt wird (abwärtskompatibel).
var map_id: String = ""
const SPEICHER_VERSION := 6
const MIN_KOMPATIBLE_VERSION := 2

## Kategorie daten: Raster biom_ids (separates Dictionary parallell zum raster).
## Keys: "x:y:z" für jede Z-Ebene separat.
var biom_raster: Dictionary = {}

## Kategorie daten: Tile-Leben für abbaubare Tiles (Fels, Geröll).
## Keys: "x:y:z" -> int (Leben). Wird bei Generierung aus Katalog initialisiert.
var tile_leben: Dictionary = {}

var raster_breite: int = RASTER_BREITE
var raster_hoehe: int = RASTER_HOEHE
## raster: Dictionary mit Key "x:y:z" -> element_id für jede Z-Ebene.
var raster: Dictionary = {}
var objekte: Array[Dictionary] = []
var biom_id: String = "gemaaessigt"
## Kantenlaenge einer Rasterkachel in Pixeln; aus der Definitions-Registry.
var kachel_groesse: int = KACHEL_GROESSE
## Chunk-Kante und Region-Kante aus welt_definition.json; nie doppelt im Code.
var chunk_groesse: int = 8
var _naechste_objekt_nummer: int = 1
var _biom_manager: Welt_BiomManager = null
var _welt_registry: Welt_Registry = null
var _biom_analyser: Welt_BiomAnalyser = null

## Kategorie logik: Lesen und Schreiben des Rasters, der Regionen und
## der Tile-Leben. Alles andere delegiert an die eigenen Funktionen.
func _init() -> void:
	ueberziehe_fliesen("boden")
	_lade_erschopfung_config()

func _raster_anlegen(element_id: String) -> void:
	raster.clear()
	biom_raster.clear()
	for z in range(MAX_Z_EBENEN):
		var z_ebene := -z
		for y in range(raster_hoehe):
			for x in range(raster_breite):
				raster["%d:%d:%d" % [x, y, z_ebene]] = element_id
				biom_raster["%d:%d:%d" % [x, y, z_ebene]] = "gemaaessigt"

func karte_erzeugen(breite: int, hoehe: int, element_id: String) -> void:
	raster_breite = clampi(breite, RASTER_MIN, RASTER_MAX)
	raster_hoehe = clampi(hoehe, RASTER_MIN, RASTER_MAX)
	ueberziehe_fliesen(element_id)

func groesse() -> Vector2i:
	return Vector2i(raster_breite, raster_hoehe)

func kachel_groesse_setzen(neue_groesse: int) -> void:
	# Einzige Schreibstelle der Kachelgroesse: Der Generator ruft sie mit dem
	# Wert aus der Definitions-Registry; alles andere liest nur.
	kachel_groesse = maxi(neue_groesse, 1)

func chunk_groesse_setzen(neue_groesse: int) -> void:
	chunk_groesse = maxi(neue_groesse, 1)

func ueberziehe_fliesen(element_id: String) -> void:
	_raster_anlegen(element_id)

func z_ebene_setzen(z_ebene: int) -> void:
	aktive_z_ebene = clampi(z_ebene, -MAX_Z_EBENEN + 1, 0)

func ist_in_raster(x: int, y: int, z_ebene: int = 0) -> bool:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	return x >= 0 and y >= 0 and x < raster_breite and y < raster_hoehe and z >= -MAX_Z_EBENEN + 1 and z <= 0

func fliese_setzen(x: int, y: int, element_id: String, z_ebene: int = 0) -> void:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return
	raster["%d:%d:%d" % [x, y, z]] = element_id

func fliese(x: int, y: int, z_ebene: int = 0) -> String:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return ""
	return str(raster.get("%d:%d:%d" % [x, y, z], ""))

func fliese_entfernen(x: int, y: int, z_ebene: int = 0) -> void:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return
	raster.erase("%d:%d:%d" % [x, y, z])
	# Tile-Leben auch entfernen
	tile_leben.erase("%d:%d:%d" % [x, y, z])

func tile_leben_initialisieren(x: int, y: int, z_ebene: int, leben: int) -> void:
	if not ist_in_raster(x, y, z_ebene):
		return
	tile_leben["%d:%d:%d" % [x, y, z_ebene]] = leben

func tile_leben_holen(x: int, y: int, z_ebene: int) -> int:
	if not ist_in_raster(x, y, z_ebene):
		return 0
	return int(tile_leben.get("%d:%d:%d" % [x, y, z_ebene], 0))

func tile_leben_setzen(x: int, y: int, z_ebene: int, leben: int) -> void:
	if not ist_in_raster(x, y, z_ebene):
		return
	tile_leben["%d:%d:%d" % [x, y, z_ebene]] = leben

func tile_leben_schaden(x: int, y: int, z_ebene: int, schaden: int) -> int:
	# Wendet Schaden an, gibt neues Leben zurück. Bei <= 0 Tile entfernen.
	var aktuell := tile_leben_holen(x, y, z_ebene)
	var neu := aktuell - schaden
	if neu <= 0:
		fliese_entfernen(x, y, z_ebene)
		return 0
	tile_leben_setzen(x, y, z_ebene, neu)
	return neu

func fliese_unterhalb(x: int, y: int, z_ebene: int = 0) -> String:
	# Liefert die Fliese genau eine Ebene tiefer (z-1)
	var z_ziel := (z_ebene if z_ebene != 0 else aktive_z_ebene) - 1
	if z_ziel < -MAX_Z_EBENEN + 1:
		return ""
	return fliese(x, y, z_ziel)

func ziel_ebene_unterhalb(z_ebene: int = 0) -> int:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	var z_ziel := z - 1
	return z_ziel if z_ziel >= -MAX_Z_EBENEN + 1 else z

func objekt_hinzufuegen(element_id: String, position: Vector2) -> int:
	# Liefert den Array-Index des neuen Objekts zurück, damit Aufrufer sofort
	# Zustandsfelder über objekt_feld_setzen schreiben können. Die fachliche
	# Objekt-Nummer bleibt als Feld "id" erhalten.
	var nummer := _naechste_objekt_nummer
	_naechste_objekt_nummer += 1
	objekte.append({
		"id": nummer,
		"element_id": element_id,
		"position": [position.x, position.y],
	})
	return objekte.size() - 1

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

func biom_raster_holen(kachel_x: int, kachel_y: int, z_ebene: int = 0) -> String:
	# Liefert das biom_id einer Kachel aus dem separaten biom_raster.
	# Gibt "gemaaessigt" zurueck, wenn out of bounds.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(kachel_x, kachel_y, z):
		return "gemaaessigt"
	var key := "%d:%d:%d" % [kachel_x, kachel_y, z]
	return str(biom_raster.get(key, "gemaaessigt"))

func biom_raster_anlegen(z_ebene: int = 0) -> void:
	# Initialisiert biom_raster für die angegebene Z-Ebene.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	for y in range(raster_hoehe):
		for x in range(raster_breite):
			biom_raster["%d:%d:%d" % [x, y, z]] = "gemaaessigt"

func biom_raster_schreiben(hoehe_raster: Array[float], feuchtigkeit_raster: Array[float], temperatur_raster: Array[float], z_ebene: int = 0) -> void:
	# Wendet die Biom-Analyse auf jedes Tile an und schreibt das biom_id
	# in das biom_raster. Dies ist das "separate dictionary" parallell zum raster.
	if hoehe_raster.size() < raster_breite * raster_hoehe or feuchtigkeit_raster.size() < raster_breite * raster_hoehe or temperatur_raster.size() < raster_breite * raster_hoehe:
		push_warning("Biom-Analyzer: Noise-Rastergroesse stimmt nicht mit Welt-Raster überein.")
		return
	if _biom_analyser == null:
		_biom_analyser = Welt_BiomAnalyser.new()
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	for y in range(raster_hoehe):
		for x in range(raster_breite):
			var index := y * raster_breite + x
			var height := hoehe_raster[index]
			var moisture := feuchtigkeit_raster[index]
			var temperature := temperatur_raster[index]
			var ermitteltes_biom_id: String = _biom_analyser.analysiere_biom(height, moisture, temperature)
			biom_raster["%d:%d:%d" % [x, y, z]] = ermitteltes_biom_id

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

func region_an(position: Vector2, z_ebene: int = 0) -> Dictionary:
	# Liefert die Region der Kachel unter der Welt-Position; sonst leer.
	var kachel_x := int(position.x / float(kachel_groesse))
	var kachel_y := int(position.y / float(kachel_groesse))
	return region_an_kachel(kachel_x, kachel_y, z_ebene)

func region_an_kachel(kachel_x: int, kachel_y: int, _z_ebene: int = 0) -> Dictionary:
	for region: Dictionary in regionen:
		var start_x := int(region.get("region_x", 0)) * region_kante
		var start_y := int(region.get("region_y", 0)) * region_kante
		if kachel_x >= start_x and kachel_x < start_x + region_kante and kachel_y >= start_y and kachel_y < start_y + region_kante:
			return region
	return {}

func biom_an_kachel(kachel_x: int, kachel_y: int, z_ebene: int = 0) -> String:
	# Einziger Ort der die Biom-Zugehörigkeit einer Kachel ableitet:
	# Region zuerst, sonst das globale Welt-Biom.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	var region := region_an_kachel(kachel_x, kachel_y, z)
	if not region.is_empty():
		return str(region.get("biom_id", biom_id))
	return biom_id

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
	var neues_raster: Variant = daten.get("raster", {})
	if typeof(neues_raster) == TYPE_DICTIONARY:
		# Format: Dictionary mit "x:y:z" Schlüsseln
		for schluessel: String in neues_raster:
			raster[schluessel] = str(neues_raster[schluessel])
	var neues_biom_raster: Variant = daten.get("biom_raster", {})
	if typeof(neues_biom_raster) == TYPE_DICTIONARY:
		for schluessel: String in neues_biom_raster:
			biom_raster[schluessel] = str(neues_biom_raster[schluessel])
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
	_eskalation_anwenden(version)
	return true

func _eskalation_anwenden(geladene_version: int) -> void:
	# Abwärtskompatibel: Neue Systeme ab Update in neu generierten Chunks,
	# alte Saves bleiben lesbar. Version 5 führt welt_seed und erweiterte
	# Regionen ein; fehlende Felder werden deterministisch ergänzt.
	# Version 6 führt Z-Ebenen und biom_raster als Dictionary mit "x:y:z" Keys ein.
	if geladene_version >= SPEICHER_VERSION:
		return
	if geladene_version < 5:
		# Version 4 hatte region_kante als 4, Chunk-Kante war 2 — ab 5
		# ist die Generator-Konvention Chunk 8, Region 4 bindend.
		if regionen.is_empty() and welt_seed == 0:
			# Alter Save ohne Seed: deterministisch aus biom_id ableiten,
			# damit gleiche alte Welt nicht zufällig neu würfelt.
			welt_seed = int(Pop_NamensGenerator.hash(biom_id) & 0x7FFFFFFF)
		for region in regionen:
			if int(region.get("chunk_kante", 0)) == 2:
				region["chunk_kante"] = Welt_Generator.CHUNK_GROESSE
	if geladene_version < 6:
		# Version 5 hatte biom_raster als Array oder Dictionary ohne Z-Ebene — ab 6 ist es Dictionary mit "x:y:z" Keys.
		# Migration: alten Array/Dict in neues Format mit Z=0 konvertieren.
		var alt_biom_raster := biom_raster.duplicate()
		biom_raster.clear()
		if typeof(alt_biom_raster) == TYPE_ARRAY:
			for i in range(alt_biom_raster.size()):
				var biom_spalte := int(i / float(raster_breite))
				var biom_zeile := i % raster_breite
				biom_raster["%d:%d:0" % [biom_zeile, biom_spalte]] = str(alt_biom_raster[i])
		elif typeof(alt_biom_raster) == TYPE_DICTIONARY:
			for schluessel: String in alt_biom_raster:
				# Alte Keys ohne Z: "x:y" -> "x:y:0"
				var biom_teile := schluessel.split(":")
				if biom_teile.size() == 2:
					biom_raster["%s:0" % [schluessel]] = str(alt_biom_raster[schluessel])
				else:
					biom_raster[schluessel] = str(alt_biom_raster[schluessel])
		# Raster migrieren falls altes Format
		var alt_raster := raster.duplicate()
		raster.clear()
		if typeof(alt_raster) == TYPE_ARRAY:
			for i in range(alt_raster.size()):
				var raster_spalte := int(i / float(raster_breite))
				var raster_zeile := i % raster_breite
				raster["%d:%d:0" % [raster_zeile, raster_spalte]] = str(alt_raster[i])
		elif typeof(alt_raster) == TYPE_DICTIONARY:
			for schluessel: String in alt_raster:
				var raster_teile := schluessel.split(":")
				if raster_teile.size() == 2:
					raster["%s:0" % [schluessel]] = str(alt_raster[schluessel])
				else:
					raster[schluessel] = str(alt_raster[schluessel])

## Erschöpfungssystem: Pro Chunk und Ressourcentyp.
## Erschöpfung wird einmalig bei Generierung gesetzt und kann nur durch
## neue Chunkgenerierung via Expansion erhöht (bzw. zurückgesetzt) werden.
## Wenn lager_bestand / erschoepfungs_maximum > 0.8 blockiert Spawn.
var _erschoepfung_maximum: int = 100
var _erschoepfung_spawn_schwelle: float = 0.8
var _erschoepfung_pro_chunk: Dictionary = {}
var _erschopfung_config_geladen := false

## Standard-Ressourcentypen für Erschöpfungstracking.
const RESSOURCE_TYPEN: Array[String] = ["holz", "stein", "erz", "beeren", "wasser", "fisch", "wild", "kraut", "eis", "pilz"]

func _lade_erschopfung_config() -> void:
	if _erschopfung_config_geladen:
		return
	var config_pfad := "res://world/data/fraktions_ki_config.json"
	var datei := FileAccess.open(config_pfad, FileAccess.READ)
	if datei != null:
		var text := datei.get_as_text()
		datei.close()
		var config: Variant = JSON.parse_string(text)
		if typeof(config) == TYPE_DICTIONARY:
			if config.has("erschoepfung_spawn_schwelle"):
				_erschoepfung_spawn_schwelle = float(config["erschoepfung_spawn_schwelle"])
			if config.has("erschoepfung_maximum"):
				_erschoepfung_maximum = int(config["erschoepfung_maximum"])
	_erschopfung_config_geladen = true

func _chunk_key_aus_position(x: int, y: int) -> String:
	var cx := int(float(x) / float(chunk_groesse))
	var cy := int(float(y) / float(chunk_groesse))
	return "%d_%d" % [cx, cy]

func _chunk_key_aus_kachel(kachel_x: int, kachel_y: int) -> String:
	var cx := int(float(kachel_x) / float(chunk_groesse))
	var cy := int(float(kachel_y) / float(chunk_groesse))
	return "%d_%d" % [cx, cy]

func erschoepfung_initialisieren() -> void:
	# Setzt Erschöpfung für alle Chunks auf 0 bei Weltgenerierung.
	_erschoepfung_pro_chunk.clear()
	var chunk_x_max := maxi(1, raster_breite / chunk_groesse)
	var chunk_y_max := maxi(1, raster_hoehe / chunk_groesse)
	for cx in range(chunk_x_max):
		for cy in range(chunk_y_max):
			var chunk_key := "%d_%d" % [cx, cy]
			var chunk_daten: Dictionary = {}
			for typ in RESSOURCE_TYPEN:
				chunk_daten[typ] = 0
			_erschoepfung_pro_chunk[chunk_key] = chunk_daten

func erschoepfung_holen(chunk_key: String, ressource_typ: String) -> int:
	# Liefert aktuellen Erschöpfungswert für Ressource in Chunk (0-100).
	if not _erschoepfung_pro_chunk.has(chunk_key):
		return 0
	var chunk_daten: Dictionary = _erschoepfung_pro_chunk[chunk_key]
	return int(chunk_daten.get(ressource_typ, 0))

func erschoepfung_setzen(chunk_key: String, ressource_typ: String, wert: int) -> void:
	# Setzt Erschöpfungswert (geklemmt 0-100). Nur Generator/Expansion darf schreiben.
	if not _erschoepfung_pro_chunk.has(chunk_key):
		var chunk_daten: Dictionary = {}
		for typ in RESSOURCE_TYPEN:
			chunk_daten[typ] = 0
		_erschoepfung_pro_chunk[chunk_key] = chunk_daten
	_erschoepfung_pro_chunk[chunk_key][ressource_typ] = clampi(wert, 0, _erschoepfung_maximum)

func erschoepfung_erhoehen(chunk_key: String, ressource_typ: String, delta: int) -> void:
	# Erhöht Erschöpfung beim Abbau/Ernte. Kann nicht über Maximum hinaus.
	var aktuell := erschoepfung_holen(chunk_key, ressource_typ)
	erschoepfung_setzen(chunk_key, ressource_typ, aktuell + delta)

func erschoepfung_prozent(chunk_key: String, ressource_typ: String) -> float:
	# Liefert Erschöpfung als 0.0-1.0 Wert.
	return float(erschoepfung_holen(chunk_key, ressource_typ)) / float(_erschoepfung_maximum)

func kann_ressource_spawnen(chunk_key: String, ressource_typ: String, lager_bestand: int) -> bool:
	# Prüft ob Ressource in Chunk spawnen darf.
	# Blockiert wenn lager_bestand / erschoepfungs_maximum > erschoepfung_spawn_schwelle
	# (d.h. Erschöpfung > erschoepfung_spawn_schwelle bei vollem Lagerbestand relativ zum Maximum).
	var erschoepfung := erschoepfung_holen(chunk_key, ressource_typ)
	if float(erschoepfung) / float(_erschoepfung_maximum) > _erschoepfung_spawn_schwelle:
		return false
	# Zusatzprüfung: Wenn Lagerbestand hoch aber Erschöpfung auch hoch -> kein Spawn
	# Dies erzwingt Expansion als einzige Wachstumsstrategie.
	if lager_bestand > 0 and float(erschoepfung) / float(_erschoepfung_maximum) > 0.5:
		var verh := float(lager_bestand) / float(_erschoepfung_maximum)
		if verh > _erschoepfung_spawn_schwelle:
			return false
	return true

func erschoepfung_zuruecksetzen_fuer_chunk(chunk_key: String) -> void:
	# Setzt Erschöpfung für alle Ressourcentypen eines Chunks auf 0.
	# Wird bei Expansion (neue Karte) aufgerufen.
	if _erschoepfung_pro_chunk.has(chunk_key):
		var chunk_daten: Dictionary = _erschoepfung_pro_chunk[chunk_key]
		for typ in RESSOURCE_TYPEN:
			chunk_daten[typ] = 0

func erschoepfung_alle_chunks_zuruecksetzen() -> void:
	# Setzt alle Chunks auf 0 (für neue Karten bei Expansion).
	for chunk_key in _erschoepfung_pro_chunk:
		erschoepfung_zuruecksetzen_fuer_chunk(chunk_key)

func erschoepfung_zustand_holen() -> Dictionary:
	# Für Speicherung und Debugging.
	return _erschoepfung_pro_chunk.duplicate(true)

func erschoepfung_zustand_setzen(daten: Dictionary) -> void:
	# Für Laden aus Savegame.
	_erschoepfung_pro_chunk = daten.duplicate(true)
