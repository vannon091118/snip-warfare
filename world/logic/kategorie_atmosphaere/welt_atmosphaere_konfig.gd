extends RefCounted
class_name Welt_AtmosphaereKonfig
## Einzige Ladestelle des Atmosphaeren-Pools world/data/atmosphaere.json.
## Die Klasse liest nur Daten und reicht sie an die Darstellungs-Spitzen
## weiter; sie berechnet nichts und besitzt keine Zeit.

## Kategorie daten: der geladene Pool als Woerterbuch.
var _pool: Dictionary = {}

## Kategorie logik: Laden und lesende Zugriffe auf den Datenpool.

const KONFIG_PFAD := "res://world/data/atmosphaere.json"

func laden() -> void:
	var datei := FileAccess.open(KONFIG_PFAD, FileAccess.READ)
	if datei == null:
		push_warning("Atmosphaeren-Pool fehlt: %s" % KONFIG_PFAD)
		return
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) == TYPE_DICTIONARY:
		_pool = gelesen

func _abschnitt(abschnitt_name: String) -> Dictionary:
	var wert: Variant = _pool.get(abschnitt_name, {})
	return wert as Dictionary if typeof(wert) == TYPE_DICTIONARY else {}

func wind_wert(schluessel: String, rueckfall: float) -> float:
	return float(_abschnitt("wind").get(schluessel, rueckfall))

func partikel_wert(schluessel: String, rueckfall: float) -> float:
	return float(_abschnitt("partikel").get(schluessel, rueckfall))

func sonne_wert(schluessel: String, rueckfall: float) -> float:
	return float(_abschnitt("sonne").get(schluessel, rueckfall))

func papier_wert(schluessel: String, rueckfall: float) -> float:
	return float(_abschnitt("papier").get(schluessel, rueckfall))

func tageslicht_wert(schluessel: String, rueckfall: float) -> float:
	return float(_abschnitt("tageslicht").get(schluessel, rueckfall))

func sonne_farbe(schluessel: String, rueckfall: Color) -> Color:
	var roh: Variant = _abschnitt("sonne").get(schluessel, "")
	var farbe := Color.from_string(str(roh), rueckfall)
	return farbe

func blatt_anzahl() -> int:
	return maxi(int(wind_wert("blatt_anzahl", 26.0)), 1)

func windlinien_anzahl() -> int:
	return maxi(int(wind_wert("windlinien_anzahl", 6.0)), 1)

func pollen_anzahl() -> int:
	return maxi(int(partikel_wert("pollen_anzahl", 30.0)), 1)
