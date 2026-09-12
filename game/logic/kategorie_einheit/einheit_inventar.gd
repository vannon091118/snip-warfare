extends RefCounted
class_name Einheit_Inventar
## Physisches Inventar einer Einheit: Ressourcen liegen bei der Einheit,
## bis sie in ein Lager gebracht werden. Jede Änderung ist eine Mutation
## (Aufnahme/Abgabe), die über das Schema läuft und in der Timeline
## mit der Einheit-ID als Quelle protokolliert wird.

signal bestand_geaendert(ressource: String, neuer_bestand: int)
signal inventar_voll()
signal inventar_leer()

const KONFIG_PFAD := "res://game/data/ressourcen.json"
const MUTATIONEN_PFAD := "res://game/data/mutationen_inventar.json"

## Kategorie daten: Schema, Timeline und physischer Bestand.
var _schema := Einheit_InventarSchema.new()
var _timeline: Kern_Timeline = null
var _einheit_id: String = ""
var _kapazitaet: int = 50
var _ressourcen_objekte: Array[Ressource_Basis] = []
var _objekte_nach_id: Dictionary = {}
var _aktueller_zustand: Dictionary = {}

## Kategorie logik: Aufnahme und Abgabe laufen ausschließlich über die
## Mutationen im Schema, nie direkt auf den Beständen.
func _init() -> void:
	_lade_ressourcen()
	_startzustand_fahren()

func _lade_ressourcen() -> void:
	if not FileAccess.file_exists(KONFIG_PFAD):
		push_warning("Ressourcen-Konfiguration nicht gefunden: %s" % KONFIG_PFAD)
		return
	var datei := FileAccess.open(KONFIG_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Ressourcen-Konfiguration hat ein ungültiges Format: %s" % KONFIG_PFAD)
		return
	for ressourcen_id: String in gelesen.keys():
		var eintrag: Dictionary = gelesen[ressourcen_id]
		eintrag["id"] = ressourcen_id
		var objekt := _ressourcen_klasse_fuer(ressourcen_id, eintrag)
		objekt.aus_konfig_eintrag(eintrag)
		_ressourcen_objekte.append(objekt)
		_objekte_nach_id[ressourcen_id] = objekt

func _ressourcen_klasse_fuer(ressourcen_id: String, eintrag: Dictionary = {}) -> Ressource_Basis:
	var skript_pfad := str(eintrag.get("script", ""))
	if skript_pfad != "":
		if not ResourceLoader.exists(skript_pfad):
			push_warning("Ressourcen-Skript fehlt: %s (Eintrag %s)" % [skript_pfad, ressourcen_id])
			return _zentrale_klasse_fuer(ressourcen_id)
		var skript: GDScript = load(skript_pfad)
		if skript != null:
			var instanz: Variant = skript.new()
			if instanz is Ressource_Basis:
				return instanz as Ressource_Basis
			push_warning("Ressourcen-Skript ist kein Ressource_Basis: %s" % skript_pfad)
	return _zentrale_klasse_fuer(ressourcen_id)

func _zentrale_klasse_fuer(ressourcen_id: String) -> Ressource_Basis:
	match ressourcen_id:
		"holz": return Ressource_Holz.new()
		"stein": return Ressource_Stein.new()
		"fleisch": return Ressource_Fleisch.new()
		"werkzeug": return Ressource_Werkzeug.new()
		"raeuchelfleisch": return Ressource_Raeuchelfleisch.new()
		"beeren": return Ressource_Beeren.new()
	return Ressource_Basis.new()

func _startzustand_fahren() -> void:
	_aktueller_zustand = _schema.ausfuehren({})

func _bestaende_lesen() -> Dictionary:
	return _aktueller_zustand.get("bestaende", {})

func _gesamt_bestand() -> int:
	var summe := 0
	for _ress: String in _bestaende_lesen():
		summe += int(_bestaende_lesen()[_ress])
	return summe

func einheit_id_setzen(id: String) -> void:
	_einheit_id = id

func kapazitaet_setzen(kap: int) -> void:
	_kapazitaet = maxi(kap, 1)

func timeline_setzen(timeline: Kern_Timeline) -> void:
	_timeline = timeline
	if _timeline != null:
		var ursprung := _bestaende_lesen().duplicate(true)
		_timeline.ursprung_festlegen(ursprung)

func icon_pfad(ressource: String) -> String:
	if not _objekte_nach_id.has(ressource):
		return ""
	return _objekte_nach_id[ressource].icon_pfad

func ressource_name(ressource: String) -> String:
	if not _objekte_nach_id.has(ressource):
		return ressource
	return _objekte_nach_id[ressource].ressourcen_name

func bestand(ressource: String) -> int:
	return int(_bestaende_lesen().get(ressource, 0))

func gesamt_bestand() -> int:
	return _gesamt_bestand()

func ist_voll() -> bool:
	return _gesamt_bestand() >= _kapazitaet

func ist_leer() -> bool:
	return _gesamt_bestand() == 0

func freie_kapazitaet() -> int:
	return _kapazitaet - _gesamt_bestand()

func kann_aufnehmen(_ressource: String, menge: int) -> bool:
	return menge > 0 and _gesamt_bestand() + menge <= _kapazitaet

func aufnahme(ressource: String, menge: int) -> bool:
	# Nimmt Ressource in das Inventar auf (Ernte, Sammeln).
	# Läuft über Mutation "InventarAufnahme" im Schema.
	if not kann_aufnehmen(ressource, menge):
		return false
	var alte_summe := _gesamt_bestand()
	var start := {"inventar_aufnahme": {"ressource": ressource, "menge": menge}}
	var ergebnis_zustand := start
	ergebnis_zustand["bestaende"] = _bestaende_lesen().duplicate(true)
	var zustand := _schema.ausfuehren(ergebnis_zustand)
	_zustand_uebernehmen(zustand)
	var neue_summe := _gesamt_bestand()
	if alte_summe != neue_summe:
		bestand_geaendert.emit(ressource, bestand(ressource))
		if neue_summe >= _kapazitaet:
			inventar_voll.emit()
	_timeline_buchung("aufnahme", "%s aufgenommen" % ressource, ressource, alte_summe, neue_summe)
	return true

func kann_abgeben(ressource: String, menge: int) -> bool:
	return menge > 0 and bestand(ressource) >= menge

func abgabe(ressource: String, menge: int) -> bool:
	# Gibt Ressource aus dem Inventar ab (Einlagern in Lager).
	# Läuft über Mutation "InventarAbgabe" im Schema.
	if not kann_abgeben(ressource, menge):
		return false
	var alte_summe := _gesamt_bestand()
	var start := {"inventar_abgabe": {"ressource": ressource, "menge": menge}}
	var ergebnis_zustand := start
	ergebnis_zustand["bestaende"] = _bestaende_lesen().duplicate(true)
	var zustand := _schema.ausfuehren(ergebnis_zustand)
	_zustand_uebernehmen(zustand)
	var neue_summe := _gesamt_bestand()
	if alte_summe != neue_summe:
		bestand_geaendert.emit(ressource, bestand(ressource))
		if neue_summe == 0:
			inventar_leer.emit()
	_timeline_buchung("abgabe", "%s abgegeben" % ressource, ressource, alte_summe, neue_summe)
	return true

func alles_abgeben() -> Dictionary:
	# Gibt den gesamten Inventarinhalt als Dictionary zurück und leert das Inventar.
	var ergebnis := _bestaende_lesen().duplicate(true)
	if ergebnis.is_empty():
		return {}
	for ressource: String in ergebnis.keys():
		abgabe(ressource, ergebnis[ressource])
	return ergebnis

func _timeline_buchung(_quelle_aktion: String, beschreibung: String, ressource: String, alte_menge: int, neue_menge: int) -> void:
	if _timeline == null:
		return
	var tick := 0
	var baum := Engine.get_main_loop() as SceneTree
	if baum != null:
		var weltuhr := baum.root.get_node_or_null("/root/Weltuhr")
		if weltuhr != null and weltuhr.has_method("tick_nummer"):
			tick = int(weltuhr.tick_nummer())
	var quelle := _einheit_id if _einheit_id != "" else "inventar"
	_timeline.eintrag_anhaengen(tick, "inventar", quelle, beschreibung,
		{ressource: alte_menge}, {ressource: neue_menge})

func _zustand_uebernehmen(zustand: Dictionary) -> void:
	var alte_bestaende := _bestaende_lesen()
	_aktueller_zustand = zustand
	var neue_bestaende := _bestaende_lesen()
	for ressource: String in neue_bestaende.keys():
		var neuer_bestand := int(neue_bestaende[ressource])
		if int(alte_bestaende.get(ressource, 0)) != neuer_bestand:
			bestand_geaendert.emit(ressource, neuer_bestand)

func schema_zustand() -> Dictionary:
	return _aktueller_zustand.duplicate(true)
