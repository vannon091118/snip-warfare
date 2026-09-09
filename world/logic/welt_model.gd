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

## Kategorie logik: Aufbau, Änderung und Ein-/Auslesen der Welt-Daten.
var raster_breite: int = RASTER_BREITE
var raster_hoehe: int = RASTER_HOEHE
var raster: Array[String] = []
var objekte: Array[Dictionary] = []
var biom_id: String = "gemaaessigt"
var _naechste_objekt_nummer: int = 1
var _biom_manager: Welt_BiomManager = null

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

func objekt_bei(ziel: Vector2, such_radius: float) -> int:
	# Gibt den Index des Objekts zurück, das den Punkt (nahe) abdeckt; sonst -1.
	# Für die Trefferprüfung wird nur die Datenklasse Objekt_Basis gelesen;
	# hier fließt keine Logik einer anderen Domäne ein.
	var registry := Welt_Registry.new()
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

func nach_woerterbuch() -> Dictionary:
	return {
		"version": 3,
		"kachel_groesse": KACHEL_GROESSE,
		"raster_breite": raster_breite,
		"raster_hoehe": raster_hoehe,
		"raster": raster,
		"objekte": objekte,
		"biom_id": biom_id,
	}

func aus_woerterbuch(daten: Dictionary) -> bool:
	if daten.is_empty():
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
				objekt_hinzufuegen(str(eintrag["element_id"]), Vector2(position_werte[0], position_werte[1]))
	return true
