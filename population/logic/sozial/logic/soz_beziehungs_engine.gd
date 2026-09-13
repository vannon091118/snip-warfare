extends RefCounted
class_name Soz_BeziehungsEngine
## Kategorie logik: Die langfristige Wahrheit zwischen zwei Einheiten.
## Sie mischt Image-Glauben, Ethik-Konto und Trait-Färbung zu einem Wert,
## der je Tick verfällt und damit nur durch wiederholte Taten gehalten wird.

## Kategorie daten: Der Beziehungs-Block aus sozial_regeln.json.
var _regeln: Soz_Datenpool = null
## Kategorie daten: Paar-Schluessel -> Beziehungswert.
var _werte: Dictionary = {}
## Kategorie logik: Lese-Rufe auf Zeugen- und Trait-Ebene, gesetzt vom Manager.
var ethik_von: Callable = Callable()
var glaube_von: Callable = Callable()
var trait_wirkung: Callable = Callable()

func einrichten(regeln: Soz_Datenpool) -> void:
	_regeln = regeln

func wert_von(beobachter: int, ziel: int) -> float:
	return float(_werte.get(_schluessel(beobachter, ziel), 0.0))

func stufe_von(beobachter: int, ziel: int) -> String:
	var wert := wert_von(beobachter, ziel)
	var stufen: Dictionary = _regeln.gruppe("beziehungen").get("stufen", {})
	for name in stufen:
		if wert >= float(stufen[name]):
			return name
	return "neutral"

## Kategorie logik: Je Takt nähert sich der Wert dem Image-Glauben an und
## verfällt danach um den Verfall; Traits schieben den Anker mit.

func tick(alle_ids: Array) -> void:
	var bilder_gewicht := float(_regeln.gruppe("beziehungen").get("bild_gewicht", 0.4))
	var ethik_gewicht := float(_regeln.gruppe("beziehungen").get("ethik_gewicht", 0.2))
	var geruecht_gewicht := float(_regeln.gruppe("beziehungen").get("geruecht_gewicht", 0.4))
	var verfall := float(_regeln.gruppe("beziehungen").get("verfall_je_tick", 0.0008))
	for beobachter: int in alle_ids:
		for ziel: int in alle_ids:
			if beobachter == ziel:
				continue
			var schluessel := _schluessel(beobachter, ziel)
			var aktuell := float(_werte.get(schluessel, 0.0))
			var ziel_wert := _ziel_wert(beobachter, ziel, bilder_gewicht, ethik_gewicht, geruecht_gewicht)
			var gemischt := aktuell * (1.0 - bilder_gewicht) + ziel_wert * bilder_gewicht
			_werte[schluessel] = gemischt - verfall if gemischt > 0.0 else gemischt + verfall * 0.5

func _ziel_wert(beobachter: int, ziel: int, bild_gew: float, ethik_gew: float, geruecht_gew: float) -> float:
	var glaube: Soz_ImageGlaube = glaube_von.call(beobachter, ziel) as Soz_ImageGlaube
	var bild := glaube.wert if glaube != null else 0.0
	var ethik: float = float(ethik_von.call(ziel))
	var trait_farbe: float = float(trait_wirkung.call(beobachter)) if trait_wirkung.is_valid() else 0.0
	return bild * bild_gew + ethik * ethik_gew + (bild * trait_farbe) * geruecht_gew

func _schluessel(a: int, b: int) -> String:
	return "%d_%d" % [a, b]
