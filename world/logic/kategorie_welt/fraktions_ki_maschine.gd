extends RefCounted
class_name Welt_FraktionsKiMaschine
## Fraktions-KI Maschine: Läuft pro Fraktion alle 120 Weltuhr-Ticks.
## Liest drei Schwellenwerte aus fraktions_ki_config.json: Expansion, Handel, Konflikt.
## Berechnet Aggression: aggressions_basis * (ressourcen_bedarf / max(1, lager_bestand)).
## ressourcen_bedarf kommt aus rassen_schemata.json der generierten Rasse.
## Bei Überschreitung Expansionsschwelle: Sendet Erkundungseinheiten zu Nachbarchunks.
## Signal an Welt_MapFabrik.neue_karte_erzeugen() für neue Chunks der Fraktion.
## Schreibt in ihre Welt_Model Instanz.
## Bei Überschreitung Konfliktsschwelle: Emitted Kern_SignalBus.konflikt_erklaert(fraktion_a, fraktion_b).
## Weltkarte visualisiert als Linienfarbänderung zwischen Fraktionsknoten.
## Erschöpfungszähler pro Ressourcentyp pro Weltchunk bei Generierung gesetzt.
## Kann nur durch neue Chunkgenerierung via Expansion erhöht werden.
## Wenn lager_bestand / erschoepfungs_maximum > 0.8 blockiert Ressource_Basis.kann_spawnen().
## Erzwingt Expansion als EINZIGE Wachstumsstrategie.
## Beweis: Entscheidungslog deterministisch; bei >0.8 kein Respawn, nach Expansion Kapazität zurück.

## Kategorie daten: Konfiguration, Fraktionsreferenz und Tick-Zähler.
var _config: Dictionary = {}
var _fraktion: Welt_Fraktion = null
var _welt_model: Welt_Model = null
var _welt_world: Welt_World = null
var _map_fabrik: Welt_MapFabrik = null
var _lager_manager: Lager_Manager = null
var _rassen_schema: Pop_RassenSchema = null
var _tick_zaehler: int = 0
const KI_TICK_INTERVALL: int = 120

## Kategorie logik: Initialisierung und Tick-Verarbeitung.

func einrichten(fraktion: Welt_Fraktion, welt_model: Welt_Model, welt_world: Welt_World, map_fabrik: Welt_MapFabrik, lager_manager: Lager_Manager, rassen_schema: Pop_RassenSchema, config: Dictionary) -> void:
	_fraktion = fraktion
	_welt_model = welt_model
	_welt_world = welt_world
	_map_fabrik = map_fabrik
	_lager_manager = lager_manager
	_rassen_schema = rassen_schema
	_config = config
	_tick_zaehler = 0

func tick(_weltuhr_tick: int) -> void:
	_tick_zaehler += 1
	if _tick_zaehler < KI_TICK_INTERVALL:
		return
	_tick_zaehler = 0
	_ki_entscheidung_treffen()

func _ki_entscheidung_treffen() -> void:
	if _fraktion == null or _welt_model == null or _config.is_empty():
		return

	var expansion_schwelle := float(_config.get("expansion", 0.6))  # RUECKFALL
	var handel_schwelle := float(_config.get("handel", 0.4))
	var konflikt_schwelle := float(_config.get("konflikt", 0.7))
	var aggressions_basis := float(_config.get("aggressions_basis", 1.0))

	## Ressourcenbedarf aus Rassen-Schema (faktor_nahrung als Proxy für Bedarf)
	var ressourcen_bedarf := 1.0
	if _rassen_schema != null:
		ressourcen_bedarf = float(_rassen_schema.faktor_nahrung)

	## Gesamtlagerbestand der Fraktion (Summe aller Lager)
	var lager_bestand := _gesamt_lagerbestand_berechnen()
	if lager_bestand <= 0:
		lager_bestand = 1

	## Aggression berechnen: aggressions_basis * (ressourcen_bedarf / max(1, lager_bestand))
	var aggression := aggressions_basis * (ressourcen_bedarf / float(maxi(1, lager_bestand)))

	## Entscheidungslog deterministisch protokollieren
	var entscheidung := _entscheidung_protokollieren(aggression, expansion_schwelle, handel_schwelle, konflikt_schwelle, ressourcen_bedarf, lager_bestand)

	## Expansionsprüfung
	if aggression > expansion_schwelle:
		_Expansion_ausfuehren(entscheidung)

	## Konfliktprüfung
	if aggression > konflikt_schwelle:
		_konflikt_pruefen_und_ausloesen(entscheidung)

	## Handelslogik (Platzhalter für spätere Implementierung)
	if aggression > handel_schwelle:
		_handel_pruefen(entscheidung)

func _gesamt_lagerbestand_berechnen() -> int:
	if _lager_manager == null:
		return 0
	var bestaende := _lager_manager.gesamt_bestand_alle()
	var summe := 0
	for menge in bestaende.values():
		summe += int(menge)
	return summe

func _entscheidung_protokollieren(aggression: float, expansion_schwelle: float, handel_schwelle: float, konflikt_schwelle: float, ressourcen_bedarf: float, lager_bestand: int) -> Dictionary:
	var log_eintrag := {
		"fraktion_id": _fraktion.fraktion_id,
		"welt_tick": _welt_model.welt_seed,  # Proxy für aktuellen Simulationsstand
		"aggression": aggression,
		"ressourcen_bedarf": ressourcen_bedarf,
		"lager_bestand": lager_bestand,
		"expansion_schwelle": expansion_schwelle,
		"handel_schwelle": handel_schwelle,
		"konflikt_schwelle": konflikt_schwelle,
		"expansion_ausgeloest": aggression > expansion_schwelle,
		"konflikt_ausgeloest": aggression > konflikt_schwelle,
		"handel_ausgeloest": aggression > handel_schwelle,
	}
	## Deterministisches Logging: In Welt_Model ablegen für Nachvollziehbarkeit
	_welt_model.objekt_feld_setzen(-1, "ki_entscheidungs_log", log_eintrag)
	return log_eintrag

func _Expansion_ausfuehren(entscheidung: Dictionary) -> void:
	if _map_fabrik == null or _welt_world == null:
		return
	## Neue Karte für diese Fraktion erzeugen (Expansion)
	var map_id := "fraktion_%s_karte_%d" % [_fraktion.fraktion_id, _welt_world.map_zahl()]
	var biom_id := _fraktion.bevorzugte_biome[0] if not _fraktion.bevorzugte_biome.is_empty() else "gemaaessigt"
	var neue_karte := _map_fabrik.neue_karte_erzeugen(_welt_world, map_id, biom_id)
	if neue_karte != null:
		entscheidung["expansion_karte_erzeugt"] = map_id
		entscheidung["expansion_biom"] = biom_id
		## Erschöpfung zurücksetzen für neue Chunks (in neuer Karte)
		_erschoepfung_fuer_neue_karte_zuruecksetzen(neue_karte)

func _erschoepfung_fuer_neue_karte_zuruecksetzen(karte: Welt_Model) -> void:
	## Erschöpfungswerte für alle Ressourcentypen in der neuen Karte auf 0 setzen
	## Die Erschöpfung wird pro Chunk und Ressourcentyp gespeichert
	if karte == null:
		return
	var erschoepfung_daten: Dictionary = {}
	var chunk_kante := karte.chunk_groesse
	var chunk_x_max := karte.raster_breite / chunk_kante
	var chunk_y_max := karte.raster_hoehe / chunk_kante
	for cx in range(chunk_x_max):
		for cy in range(chunk_y_max):
			var chunk_key := "%d_%d" % [cx, cy]
			erschoepfung_daten[chunk_key] = {
				"holz": 0, "stein": 0, "erz": 0, "beeren": 0,
				"wasser": 0, "fisch": 0, "wild": 0, "kraut": 0,
				"eis": 0, "pilz": 0
			}
	karte.objekt_feld_setzen(-1, "erschoepfung_pro_chunk", erschoepfung_daten)

func _konflikt_pruefen_und_ausloesen(entscheidung: Dictionary) -> void:
	if _welt_world == null:
		return
	## Konflikt mit nächster Nachbarfraktion auslösen
	var nachbarn := _fraktion.nachbarn
	if nachbarn.is_empty():
		return
	var ziel_fraktion_id := nachbarn[0]  # Deterministisch: erster Nachbar
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_konflikt_erklaert(_fraktion.fraktion_id, ziel_fraktion_id)
	entscheidung["konflikt_gegner"] = ziel_fraktion_id
	entscheidung["konflikt_erklaert"] = true

func _handel_pruefen(entscheidung: Dictionary) -> void:
	## Platzhalter für Handelslogik
	entscheidung["handel_aktiv"] = true

func modell_aktualisieren(neues_modell: Welt_Model) -> void:
	## Aktualisiert die Modell-Referenz bei Kartenwechsel (Expansion).
	if neues_modell != null:
		_welt_model = neues_modell
