extends Node
class_name Soz_Manager
## Fassade der Sozial-Domäne. Sie lauscht auf die Taten am Kern-SignalBus,
## tickt an der Weltuhr und bietet schmale Lese-Schnittstellen für Mood,
## Blase und Beziehungs-Fragen. Sie besitzt keine eigene Zeit und schreibt
## in keine fremde Domäne.

## Kategorie daten: Die eigenen Maschinen der Domäne.
var _datenpool := Soz_Datenpool.new()
var _traits := Soz_TraitLedger.new()
var _zeugen := Soz_ZeugenMaschine.new()
var _geruechte := Soz_GeruechtMaschine.new()
var _beziehungen := Soz_BeziehungsEngine.new()

## Kategorie logik: Ids aller bekannten Einheiten für Takt und Wanderung.
var _bekannte: Array[int] = []

const REGELN_PFAD := "res://population/logic/sozial/data/sozial_regeln.json"

func _ready() -> void:
	_datenpool.laden(REGELN_PFAD)
	_traits.einrichten(_datenpool.gruppe("traits"))
	_zeugen.einrichten(_datenpool)
	_geruechte.einrichten(_datenpool)
	_beziehungen.einrichten(_datenpool)
	_bus_verbinden()

func _bus_verbinden() -> void:
	# Nullsicher: In Headless-Testläufen ohne Autoloads bleibt die Fassade still.
	var bus := Kern_SignalBus.bus()
	if bus == null:
		return
	bus.gestorben.connect(_auf_gestorben)

func _exit_tree() -> void:
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.gestorben.is_connected(_auf_gestorben):
		bus.gestorben.disconnect(_auf_gestorben)

## Kategorie logik: Anmeldung neuer Einheiten; vergibt Traits und öffnet Konten.

func einheit_anmelden(einheit_id: int, position: Vector2, trait_namen: Array = []) -> void:
	if not _bekannte.has(einheit_id):
		_bekannte.append(einheit_id)
	_zeugen.registrieren(einheit_id)
	_zeugen.position_fuer = func(id: int) -> Vector2: return _positionen.get(id, Vector2.ZERO)
	_traits.traits_setzen(einheit_id, trait_namen)
	_positionen[einheit_id] = position

## Kategorie daten: Positions-Gedächtnis der Fassade (vom Verdrahter gefüllt).
var _positionen: Dictionary = {}

func position_melden(einheit_id: int, position: Vector2) -> void:
	_positionen[einheit_id] = position

func auf_tick(_nummer: int, _delta: float) -> void:
	_geruechte.position_fuer = func(id: int) -> Vector2: return _positionen.get(id, Vector2.ZERO)
	_geruechte.gerede_takt(float(_nummer), _bekannte)
	_beziehungen.ethik_von = func(id: int) -> float: return _zeugen.ethik_von(id)
	_beziehungen.glaube_von = func(a: int, z: int) -> Soz_ImageGlaube: return _zeugen.glaube_von(a, z)
	_beziehungen.trait_wirkung = func(id: int) -> float: return float(_traits.wirkung(id).get("beziehung", 0.0))
	_beziehungen.tick(_bekannte)

## Kategorie logik: Taten kommen als Todes-Fälle vom Bus; die Zeugen buchen.

func _auf_gestorben(tod_position: Vector2, _typ: String, war_einheit: bool) -> void:
	if not war_einheit:
		return
	var taeter := _naechster_bei(tod_position)
	if taeter < 0:
		return
	_zeugen.tat_buchen(taeter, -1, "kannibalismus")
	_geruechte.urheur_buchen(taeter, -1, "grauen", 1.0)

func _naechster_bei(position: Vector2) -> int:
	var bester := -1
	var beste := INF
	for id: int in _bekannte:
		var abstand: Vector2 = _positionen.get(id, Vector2.ZERO) - position
		if abstand.length() < beste:
			beste = abstand.length()
			bester = id
	return bester

## Kategorie logik: Schmale Lese-Schnittstelle für Mood, Blase und HUD.

func ethik_von(einheit_id: int) -> float:
	return _zeugen.ethik_von(einheit_id)

func image_von(beobachter: int, ziel: int) -> Soz_ImageGlaube:
	return _zeugen.glaube_von(beobachter, ziel)

func beziehung_von(beobachter: int, ziel: int) -> float:
	return _beziehungen.wert_von(beobachter, ziel)

func beziehungs_stufe(beobachter: int, ziel: int) -> String:
	return _beziehungen.stufe_von(beobachter, ziel)

func geruechte_von(einheit_id: int) -> Array:
	return _geruechte.geruechte_von(einheit_id)

func test_datenpool_groesse() -> int:
	# Nur für den Beweislauf: Zeigt, ob der Datenpool wirklich geladen hat.
	return _datenpool.gruppe("traits").size()
