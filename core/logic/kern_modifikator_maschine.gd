extends RefCounted
class_name Kern_ModifikatorMaschine
## Zentrale Modifikator-Rechenmaschine. Jede State-Maschine (Bau, Produktion,
## Bewegung, Vital) hält ihre eigene Instanz mit einem Bereich aus den
## globalen Settings (core/data/modifikator_settings.json). Die Maschine
## übersetzt den Modus des Bereichs über die bestehende
## Kern_ModifikatorRegistry (kern_modifikatoren.json) in einen Faktor und
## klemmt ihn auf die Bereichsgrenzen. Keine State-Maschine rechnet selbst:
## Zeit = Basis-Ticks geteilt durch Faktor, Geschwindigkeit = Basis mal Faktor.
##
## Keine redundanten Rechenschritte: Der Bereichsfaktor wird einmal berechnet
## und gecacht. Erst wenn ein Menü geöffnet wird, meldet der Signalbus das,
## und die Maschine prüft alle Faktoren neu. Die Trait-Formel für aktive
## Modifikatoren (multiplikative Faktoren plus additive Attributwerte) ist
## eine einzige zentrale Funktion, die auch die Vital-Maschine nutzt.

signal aktualisiert()

const SETTINGS_PFAD := "res://core/data/modifikator_settings.json"

## Kategorie daten: Bereich, Settings und gecachter Faktor.
var bereich: String = ""
var _settings: Dictionary = {}
var _bereich_settings: Dictionary = {}
var _faktor: float = 1.0
var _faktor_gueltig: bool = false
var _rechen_schritte: int = 0

## Kategorie logik: Laden, Faktor ableiten und Zeiten übersetzen.

static func _registry() -> Kern_ModifikatorRegistry:
	# Die Maschine nutzt die geteilte Registry-Instanz der Registry-Klasse
	# selbst. Es existiert genau eine Ladung der Modifikator-Daten im Projekt;
	# der frühere zweite Cache hier ist als Doppelpfad entfernt.
	return Kern_ModifikatorRegistry.geteilte()

func _init() -> void:
	_settings = _laden()
	var bus := Kern_SignalBus.bus()
	if bus != null and bus.has_signal("menue_geoeffnet") and not bus.menue_geoeffnet.is_connected(_auf_menue_geoeffnet):
		bus.menue_geoeffnet.connect(_auf_menue_geoeffnet)

func _laden() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PFAD):
		push_warning("Modifikator-Settings fehlen: %s" % SETTINGS_PFAD)
		return {}
	var datei := FileAccess.open(SETTINGS_PFAD, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) != TYPE_DICTIONARY:
		push_warning("Modifikator-Settings ungültiges JSON: %s" % SETTINGS_PFAD)
		return {}
	return daten

func bereich_setzen(neuer_bereich: String) -> void:
	bereich = neuer_bereich
	var alle: Dictionary = _settings.get("bereiche", {})
	_bereich_settings = alle.get(neuer_bereich, {})
	_faktor_gueltig = false

func modus_setzen(modus_id: String) -> void:
	# Laufzeit-Umstellung des Modus (zum Beispiel über ein Optionsmenü);
	# der Faktor wird erst beim nächsten aktualisieren neu gerechnet.
	_bereich_settings["modus"] = modus_id
	_faktor_gueltig = false

func basis_wert(schluessel: String, fallback: float) -> float:
	return float(_bereich_settings.get(schluessel, fallback))

func aktualisieren() -> void:
	# Menü-Gegenprüfung: Faktor aus Modus und globaler Einstellung neu ziehen.
	_rechen_schritte += 1
	var modus_id := str(_bereich_settings.get("modus", "normal"))
	var modus_faktor := 1.0
	var registry := _registry()
	var modus := registry.modifikator_fuer(modus_id)
	if modus != null:
		modus_faktor = modus.faktor
	var global_faktor := float(_settings.get("global", {}).get("faktor", 1.0))
	_faktor = modus_faktor * global_faktor
	_faktor = clampf(_faktor, float(_bereich_settings.get("faktor_min", 0.1)), float(_bereich_settings.get("faktor_max", 10.0)))
	_faktor_gueltig = true
	aktualisiert.emit()

func faktor() -> float:
	# Gecachter Bereichsfaktor: keine Neuberechnung pro Abfrage.
	if not _faktor_gueltig:
		aktualisieren()
	return _faktor

func zeit_berechnen(basis_ticks: int) -> int:
	# Zentrale Zeitformel: Faktor über 1 bedeutet schneller, also kürzer.
	if basis_ticks <= 0:
		return 0
	return maxi(int(round(float(basis_ticks) / faktor())), 1)

func geschwindigkeit_berechnen(basis_geschwindigkeit: float) -> float:
	# Zentrale Geschwindigkeitsformel: Faktor über 1 bedeutet schneller.
	return maxf(basis_geschwindigkeit * faktor(), 0.1)

## Zentrale Trait-Formel: aktive Modifikatoren multiplizieren ihren Faktor
## und addieren ihre Attributwerte auf den Basiswert. Einzige Stelle im
## Projekt für diese Rechnung; die Vital-Maschine delegiert hierher.
static func wert_berechnen(basis: float, mods: Array[Kern_ModifikatorBasis], min_wert: float = 0.1) -> float:
	var wert := basis
	for mod in mods:
		wert *= mod.faktor
		for attribut: String in mod.attribute_modifikation:
			if attribut == "geschwindigkeit" or attribut == "tragekraft":
				wert += float(mod.attribute_modifikation[attribut])
	return maxf(wert, min_wert)

func rechen_schritte() -> int:
	return _rechen_schritte

func _auf_menue_geoeffnet() -> void:
	aktualisieren()