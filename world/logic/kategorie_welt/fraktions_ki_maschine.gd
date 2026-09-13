extends RefCounted
class_name Welt_FraktionsKiMaschine
## Fraktions-KI: Sie läuft alle 120 Weltuhr-Ticks je Fraktion, liest die drei
## Schwellenwerte aus fraktions_ki_config.json und leitet daraus Aggression,
## Expansion, Konflikt und Handel ab. Das Entscheidungs-Protokoll trägt das
## Welt_FraktionsProtokoll, die Erschöpfungs-Saat der neuen Karte die
## Welt_FraktionsErschoepfung; hier bleibt die Entscheidung selbst.

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

func einrichten(fraktion: Welt_Fraktion, welt_model: Welt_Model, welt_world: Welt_World,
		map_fabrik: Welt_MapFabrik, lager_manager: Lager_Manager,
		rassen_schema: Pop_RassenSchema, config: Dictionary) -> void:
	_fraktion = fraktion
	_welt_model = welt_model
	_welt_world = welt_world
	_map_fabrik = map_fabrik
	_lager_manager = lager_manager
	_rassen_schema = rassen_schema
	_config = config
	_tick_zaehler = 0

func tick(_weltuhr_tick: int, _delta: float = 0.0) -> void:
	_tick_zaehler += 1
	if _tick_zaehler < KI_TICK_INTERVALL:
		return
	_tick_zaehler = 0
	_ki_entscheidung_treffen()

func _ki_entscheidung_treffen() -> void:
	if _fraktion == null or _welt_model == null or _config.is_empty():
		return
	var bestand := maxi(1, _gesamt_lagerbestand_berechnen())
	var bedarf := _ressourcen_bedarf()
	var expansion_schwelle := float(_config.get("expansion", 0.6))  # RUECKFALL
	var handel_schwelle := float(_config.get("handel", 0.4))  # RUECKFALL
	var konflikt_schwelle := float(_config.get("konflikt", 0.7))  # RUECKFALL
	var aggression := float(_config.get("aggressions_basis", 1.0)) * (bedarf / float(bestand))
	var entscheidung := Welt_FraktionsProtokoll.erfassen(_welt_model, _fraktion.fraktion_id,
		aggression, bedarf, bestand, expansion_schwelle, handel_schwelle, konflikt_schwelle)
	if aggression > expansion_schwelle:
		expansion_ausfuehren(entscheidung)
	if aggression > konflikt_schwelle:
		_konflikt_pruefen_und_ausloesen(entscheidung)
	if aggression > handel_schwelle:
		_handel_pruefen(entscheidung)

func _ressourcen_bedarf() -> float:
	# Der Nahrungsfaktor der Rasse steht als Proxy für den Ressourcenbedarf.
	if _rassen_schema == null:
		return 1.0
	return float(_rassen_schema.faktor_nahrung)

func _gesamt_lagerbestand_berechnen() -> int:
	if _lager_manager == null:
		return 0
	var summe := 0
	for menge in _lager_manager.gesamt_bestand_alle().values():
		summe += int(menge)
	return summe

func expansion_ausfuehren(entscheidung: Dictionary) -> void:
	# Neue Karte für diese Fraktion, Erschöpfung der neuen Chunks bei null.
	if _map_fabrik == null or _welt_world == null:
		return
	var map_id := "fraktion_%s_karte_%d" % [_fraktion.fraktion_id, _welt_world.map_zahl()]
	var biom_id := "gemaaessigt"
	if not _fraktion.bevorzugte_biome.is_empty():
		biom_id = _fraktion.bevorzugte_biome[0]
	var neue_karte := _map_fabrik.neue_karte_erzeugen(_welt_world, map_id, biom_id)
	if neue_karte != null:
		entscheidung["expansion_karte_erzeugt"] = map_id
		entscheidung["expansion_biom"] = biom_id
		Welt_FraktionsErschoepfung.saeen(neue_karte)

func _konflikt_pruefen_und_ausloesen(entscheidung: Dictionary) -> void:
	if _welt_world == null:
		return
	# Deterministisch: der erste Nachbar ist der Konfliktgegner.
	var nachbarn := _fraktion.nachbarn
	if nachbarn.is_empty():
		return
	var ziel_fraktion_id := nachbarn[0]
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_konflikt_erklaert(_fraktion.fraktion_id, ziel_fraktion_id)
	entscheidung["konflikt_gegner"] = ziel_fraktion_id
	entscheidung["konflikt_erklaert"] = true

func _handel_pruefen(entscheidung: Dictionary) -> void:
	# Platzhalter für die spätere Handelslogik.
	entscheidung["handel_aktiv"] = true

func modell_aktualisieren(neues_modell: Welt_Model) -> void:
	# Aktualisiert die Modell-Referenz bei Kartenwechsel (Expansion).
	if neues_modell != null:
		_welt_model = neues_modell
