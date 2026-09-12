extends RefCounted
class_name Welt_World
## World-Objekt: Der Anker über allen Karten einer Partie. Eine World hält
## die Liste ihrer Maps (Welt_Model-Instanzen), markiert genau eine Map als
## Basis und verwaltet die Zuordnung über map_id. Sie besitzt keine eigene
## Zeit, keinen Zufall und keine Generierung: Der globale Tick bleibt bei
## Kern_Weltuhr, der Zufall bei Kern_Zufall, die Erzeugung beim Generator.
## Maps werden über die eigene Schnittstelle eingetragen und gelesen, nie
## über fremde Arrays.
## ## Parallel-Map-Erweiterung: _karten-Dictionary hält alle Karten mit
## ihrem Aktiv-Status. Inaktive Karten laufen mit 1/6 Tick-Rate.
## Lager-Daten pro Karte: Damit Karawanen auch auf inaktiven Karten handeln
## können, speichert die World die Lager-Daten jeder Karte persistent.

## Kategorie daten: Map-Liste mit Zuordnung und Basis-Markierung.
var _maps: Array[Dictionary] = []
var _basis_map_id: String = ""
var world_name: String = ""

## Parallel-Map-Steuerung: Dictionary mit karten_id → {model, ist_aktiv, lager_daten}.
var _karten: Dictionary = {}

const SPEICHER_VERSION := 1

## Karawanen-Manager: Global für alle Karten dieser World.
var _karawanen_manager: Welt_KarawanenManager = null

## Kategorie logik: Eintragen, Suchen und Abfragen der Maps.

func map_hinzufuegen(model: Welt_Model, map_id: String, ist_basis: bool) -> bool:
	if model == null or map_id.strip_edges() == "":
		return false
	if map_id_vorhanden(map_id):
		return false
	model.map_id = map_id
	_maps.append({"map_id": map_id, "model": model})
	# Parallel-Map-Eintrag hinzufügen: Standardmäßig inaktiv, bis der
	# Spieler die Karte wechselt. Lager-Daten werden leer initialisiert.
	_karten[map_id] = {"model": model, "ist_aktiv": false, "lager_daten": []}
	if ist_basis or _basis_map_id == "":
		_basis_map_id = map_id
	# Basis-Karte beim Setzen aktiv schalten
	karte_aktiv_shetzen(map_id)
	return true

func map_entfernen(map_id: String) -> bool:
	for index in range(_maps.size()):
		if str(_maps[index].get("map_id", "")) == map_id:
			_maps.remove_at(index)
			if _basis_map_id == map_id:
				_basis_map_id = _maps[0].get("map_id", "") if not _maps.is_empty() else ""
			_karten.erase(map_id)
			return true
	return false

func lager_daten_holen(map_id: String) -> Array:
	## Gibt die gespeicherten Lager-Daten einer Karte zurück.
	if _karten.has(map_id):
		return _karten[map_id]["lager_daten"]
	return []

func lager_daten_setzen(map_id: String, lager_daten: Array) -> void:
	## Speichert die Lager-Daten einer Karte (z. B. beim Kartenwechsel).
	if _karten.has(map_id):
		_karten[map_id]["lager_daten"] = lager_daten.duplicate(true)

func map_id_vorhanden(map_id: String) -> bool:
	for eintrag: Dictionary in _maps:
		if str(eintrag.get("map_id", "")) == map_id:
			return true
	return false

func basis_setzen(map_id: String) -> bool:
	if not map_id_vorhanden(map_id):
		return false
	_basis_map_id = map_id
	return true

func basis_map_id() -> String:
	return _basis_map_id

func basis_model() -> Welt_Model:
	for eintrag: Dictionary in _maps:
		if str(eintrag.get("map_id", "")) == _basis_map_id:
			return eintrag.get("model", null)
	return null

func karte_aktiv_shetzen(map_id: String) -> void:
	# Setze vorherige Karte inaktiv und neue aktiv.
	# Dies wird aufgerufen, wenn der Spieler die Karte wechselt.
	var vorherige_map_id := aktive_map_id()
	if vorherige_map_id != "" and vorherige_map_id != map_id:
		# Vorherige deaktivieren
		if _karten.has(vorherige_map_id):
			_karten[vorherige_map_id]["ist_aktiv"] = false
	# Neue aktiv schalten
	if _karten.has(map_id):
		_karten[map_id]["ist_aktiv"] = true
	_basis_map_id = map_id

func map_model(map_id: String) -> Welt_Model:
	for eintrag: Dictionary in _maps:
		if str(eintrag.get("map_id", "")) == map_id:
			return eintrag.get("model", null)
	return null

func model_uebernehmen(map_id: String, model: Welt_Model) -> bool:
	# Laufzeit-Übernahme: Die laufende Instanz ersetzt den World-Eintrag,
	# sodass Welt-Szene und World dasselbe Welt_Model teilen. Es entsteht
	# keine zweite Kartenwahrheit, und die map_id-Zuordnung bleibt bestehen.
	if model == null or not map_id_vorhanden(map_id):
		return false
	for index in _maps.size():
		if str(_maps[index].get("map_id", "")) == map_id:
			_maps[index]["model"] = model
			model.map_id = map_id
			return true
	return false

func map_ids() -> Array[String]:
	var ids: Array[String] = []
	for eintrag: Dictionary in _maps:
		ids.append(str(eintrag.get("map_id", "")))
	return ids

func map_zahl() -> int:
	return _maps.size()

func map_karte(map_id: String) -> Dictionary:
	# Gibt das Parallel-Map-Info zurück: {"model": Welt_Model, "ist_aktiv": bool, "lager_daten": Array}
	if _karten.has(map_id):
		var info: Dictionary = _karten[map_id].duplicate(true)
		return info
	return {"model": null, "ist_aktiv": false, "lager_daten": []}

func map_zahl_aktiv() -> int:
	# Anzahl der aktiv geschalteten Karten
	var zaehler: int = 0
	for key: String in _karten.keys():
		if _karten[key]["ist_aktiv"]:
			zaehler += 1
	return zaehler

func aktive_map_id() -> String:
	return _basis_map_id if _basis_map_id != "" else (map_ids()[0] if not _maps.is_empty() else "")

func nach_woerterbuch() -> Dictionary:
	# Persistenz der World: Nur die Map-Daten wandern in den Speicher, die
	# Model-Instanzen werden beim Laden neu erzeugt.
	var map_daten: Array[Dictionary] = []
	for eintrag: Dictionary in _maps:
		var model: Welt_Model = eintrag.get("model", null)
		if model != null:
			var map_info := model.nach_woerterbuch()
			var map_id := str(eintrag.get("map_id", ""))
			if _karten.has(map_id):
				map_info["lager_daten"] = _karten[map_id]["lager_daten"]
			map_daten.append(map_info)
	return {
		"version": SPEICHER_VERSION,
		"world_name": world_name,
		"basis_map_id": _basis_map_id,
		"maps": map_daten,
	}

func aus_woerterbuch(daten: Dictionary) -> bool:
	if daten.is_empty() or int(daten.get("version", 0)) != SPEICHER_VERSION:
		return false
	world_name = str(daten.get("world_name", ""))
	_maps.clear()
	_basis_map_id = ""
	var neue_maps: Variant = daten.get("maps", [])
	if typeof(neue_maps) != TYPE_ARRAY:
		return false
	for eintrag: Variant in neue_maps:
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		var model := Welt_Model.new()
		if not model.aus_woerterbuch(eintrag):
			continue
		var map_id := model.map_id
		map_hinzufuegen(model, map_id, false)
		# Lager-Daten wiederherstellen
		if _karten.has(map_id) and eintrag.has("lager_daten"):
			_karten[map_id]["lager_daten"] = eintrag["lager_daten"]
	basis_setzen(str(daten.get("basis_map_id", "")))
	return not _maps.is_empty()

## Parallel-Map: Karawanen-Handel zwischen Karten.

func karawane_ankunft_verarbeiten(karawane: Welt_Karawane) -> bool:
	## Verarbeitet die Ankunft einer Karawane auf der Zielkarte.
	## Führt die Einlagerung direkt über Mutation auf dem Ziel-Modell aus.
	## Funktioniert auch auf inaktiven Karten (kein SubViewport, kein Threading,
	## nur reduzierte Tick-Kosten). Nutzt die gespeicherten Lager-Daten.
	var ziel_map_id := karawane.nach_map_id
	if not _karten.has(ziel_map_id):
		push_warning("Karawane %s: Zielkarte %s nicht gefunden" % [karawane.karawanen_id, ziel_map_id])
		return false
	
	var ziel_model: Welt_Model = _karten[ziel_map_id]["model"]
	if ziel_model == null:
		push_warning("Karawane %s: Ziel-Modell für %s ist null" % [karawane.karawanen_id, ziel_map_id])
		return false
	
	# Lager-Daten der Zielkarte holen (funktioniert auch für inaktive Karten)
	var lager_daten: Array = _karten[ziel_map_id]["lager_daten"]
	if lager_daten == null:
		lager_daten = []
	
	# Lager_MutationEinlagern direkt auf den Lager-Daten anwenden
	var alles_erfolgreich := true
	var fracht := karawane.fracht()
	var zufall := Kern_Zufall.new()
	zufall.start_zustand_setzen(42)
	
	for ressource: String in fracht.keys():
		var menge := int(fracht[ressource])
		if menge <= 0:
			continue
		
		# Ersten verfügbaren Lager-Index finden oder 0 als Fallback
		var lager_index := _erster_gueltiger_lager_index(lager_daten)
		if lager_index < 0:
			# Kein Lager vorhanden: Erstes Lager anlegen (Typ "lagerfeuer" als Fallback)
			lager_daten.append({
				"typ_id": "lagerfeuer",
				"position": [karawane.nach_position.x, karawane.nach_position.y],
				"bestaende": {},
				"kapazitaet": 1000
			})
			lager_index = lager_daten.size() - 1
		
		# Mutation direkt anwenden
		var mutation := Lager_MutationEinlagern.new(ressource, menge, lager_index)
		var zustand := {"lager": lager_daten.duplicate(true)}
		
		if mutation.anwendbar(zustand):
			var ergebnis := mutation.anwenden(zustand, zufall)
			lager_daten = ergebnis["lager"]
		else:
			push_warning("Karawane %s: Mutation nicht anwendbar für %d %s in Lager %d" % [karawane.karawanen_id, menge, ressource, lager_index])
			alles_erfolgreich = false
	
	# Aktualisierte Lager-Daten speichern
	_karten[ziel_map_id]["lager_daten"] = lager_daten
	
	return alles_erfolgreich

func _erster_gueltiger_lager_index(lager_daten: Array) -> int:
	## Findet den ersten Lager-Index mit Kapazität > 0, oder -1 wenn keins.
	for idx in lager_daten.size():
		var lager: Variant = lager_daten[idx]
		var kapazitaet := int(lager.get("kapazitaet", 0))
		if kapazitaet > 0:
			return idx
	return -1

func lager_mutation_direkt_ausfuehren(map_id: String, ressource: String, menge: int, lager_index: int) -> bool:
	## Führt eine Lager-Mutation direkt auf den gespeicherten Lager-Daten aus.
	## Wird für Karawanen-Handel auf inaktiven Karten verwendet.
	## Kein SubViewport, kein Threading - nur direkte Methoden-Aufrufe.
	if not _karten.has(map_id):
		push_warning("Lager-Mutation: Karte %s nicht gefunden" % map_id)
		return false
	
	var lager_daten: Array = _karten[map_id]["lager_daten"]
	if lager_daten == null:
		lager_daten = []
	
	if lager_index < 0 or lager_index >= lager_daten.size():
		push_warning("Lager-Mutation: Ungültiger Lager-Index %d für Karte %s" % [lager_index, map_id])
		return false
	
	var mutation := Lager_MutationEinlagern.new(ressource, menge, lager_index)
	var zustand := {"lager": lager_daten.duplicate(true)}
	var zufall := Kern_Zufall.new()
	zufall.start_zustand_setzen(42)
	
	if not mutation.anwendbar(zustand):
		return false
	
	var ergebnis := mutation.anwenden(zustand, zufall)
	_karten[map_id]["lager_daten"] = ergebnis["lager"]
	return true

func karte_ist_aktiv(map_id: String) -> bool:
	## Prüft, ob eine Karte aktuell aktiv ist.
	if _karten.has(map_id):
		return _karten[map_id]["ist_aktiv"]
	return false

func karawanen_manager() -> Welt_KarawanenManager:
	## Gibt den globalen Karawanen-Manager zurück (erzeugt ihn bei Bedarf).
	if _karawanen_manager == null:
		_karawanen_manager = Welt_KarawanenManager.new()
	return _karawanen_manager

func karawanen_manager_setzen(manager: Welt_KarawanenManager) -> void:
	_karawanen_manager = manager