extends RefCounted
class_name Welt_ErschoepfungMaschine
## Erschöpfungs-Rechnung der Welt: Pro Chunk und Ressourcentyp wird der
## Abbaudruck gezählt. Erschöpfung wird einmalig bei Generierung gesetzt und
## kann nur durch neue Chunkgenerierung via Expansion erhöht (bzw. zurück-
## gesetzt) werden. Wenn lager_bestand / erschoepfungs_maximum über der
## Spawn-Schwelle liegt, blockiert der Spawn. Das Welt_Model hält nur noch
## den Datenkasten; die Regel allein wohnt in dieser Maschine.

## Kategorie daten: Schwellen, Chunks und Ressourcentypen.
var _erschoepfung_maximum: int = 100
var _erschoepfung_spawn_schwelle: float = 0.8
var _erschoepfung_pro_chunk: Dictionary = {}
var _erschopfung_config_geladen := false

## Standard-Ressourcentypen für Erschöpfungstracking.
const RESSOURCE_TYPEN: Array[String] = ["holz", "stein", "erz", "beeren", "wasser", "fisch", "wild", "kraut", "eis", "pilz"]

## Kategorie logik: Config laden, Zähler pflegen, Spawn beantworten.

func _init() -> void:
	_lade_config()

func _lade_config() -> void:
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

func maximum() -> int:
	return _erschoepfung_maximum

func initialisieren(chunk_groesse: int, raster_breite: int, raster_hoehe: int) -> void:
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

func holen(chunk_key: String, ressource_typ: String) -> int:
	# Liefert aktuellen Erschöpfungswert für Ressource in Chunk (0-100).
	if not _erschoepfung_pro_chunk.has(chunk_key):
		return 0
	var chunk_daten: Dictionary = _erschoepfung_pro_chunk[chunk_key]
	return int(chunk_daten.get(ressource_typ, 0))

func setzen(chunk_key: String, ressource_typ: String, wert: int) -> void:
	# Setzt Erschöpfungswert (geklemmt 0-100). Nur Generator/Expansion darf schreiben.
	if not _erschoepfung_pro_chunk.has(chunk_key):
		var chunk_daten: Dictionary = {}
		for typ in RESSOURCE_TYPEN:
			chunk_daten[typ] = 0
		_erschoepfung_pro_chunk[chunk_key] = chunk_daten
	_erschoepfung_pro_chunk[chunk_key][ressource_typ] = clampi(wert, 0, _erschoepfung_maximum)

func erhoehen(chunk_key: String, ressource_typ: String, delta: int) -> void:
	# Erhöht Erschöpfung beim Abbau/Ernte. Kann nicht über Maximum hinaus.
	var aktuell := holen(chunk_key, ressource_typ)
	setzen(chunk_key, ressource_typ, aktuell + delta)

func prozent(chunk_key: String, ressource_typ: String) -> float:
	# Liefert Erschöpfung als 0.0-1.0 Wert.
	return float(holen(chunk_key, ressource_typ)) / float(_erschoepfung_maximum)

func kann_ressource_spawnen(chunk_key: String, ressource_typ: String, lager_bestand: int) -> bool:
	# Prüft ob Ressource in Chunk spawnen darf.
	# Blockiert wenn lager_bestand / erschoepfungs_maximum > spawn_schwelle.
	var erschoepfung := holen(chunk_key, ressource_typ)
	if float(erschoepfung) / float(_erschoepfung_maximum) > _erschoepfung_spawn_schwelle:
		return false
	# Zusatzprüfung: Wenn Lagerbestand hoch aber Erschöpfung auch hoch -> kein Spawn.
	# Dies erzwingt Expansion als einzige Wachstumsstrategie.
	if lager_bestand > 0 and float(erschoepfung) / float(_erschoepfung_maximum) > 0.5:
		var verh := float(lager_bestand) / float(_erschoepfung_maximum)
		if verh > _erschoepfung_spawn_schwelle:
			return false
	return true

func zuruecksetzen_fuer_chunk(chunk_key: String) -> void:
	# Setzt Erschöpfung für alle Ressourcentypen eines Chunks auf 0.
	# Wird bei Expansion (neue Karte) aufgerufen.
	if _erschoepfung_pro_chunk.has(chunk_key):
		var chunk_daten: Dictionary = _erschoepfung_pro_chunk[chunk_key]
		for typ in RESSOURCE_TYPEN:
			chunk_daten[typ] = 0

func alle_chunks_zuruecksetzen() -> void:
	# Setzt alle Chunks auf 0 (für neue Karten bei Expansion).
	for chunk_key in _erschoepfung_pro_chunk:
		zuruecksetzen_fuer_chunk(chunk_key)

func zustand_holen() -> Dictionary:
	# Für Speicherung und Debugging.
	return _erschoepfung_pro_chunk.duplicate(true)

func zustand_setzen(daten: Dictionary) -> void:
	# Für Laden: Der gespeicherte Zustand ersetzt die Zähler komplett.
	_erschoepfung_pro_chunk = daten.duplicate(true)
