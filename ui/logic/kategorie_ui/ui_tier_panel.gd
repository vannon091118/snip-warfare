extends RefCounted
class_name Ui_TierPanel
## Uebersetzer der Tiere: Liest nur ueber den geschlossenen Schnittpunkt
## Tier_Manager.tier_bestand(). Niemals _tiere direkt. Ein Fenster ruft nur
## diesen Uebersetzer.
## Schnittregel: Neue Tierdaten kommen nur ueber den Manager-Snapshot.

## Anzeigegrenze des Debug-Fensters: Ein Bestand von hundert Tieren darf die
## halbe Karte nicht mit Text zustellen. Die Grenze gehoert zur Darstellung
## und wohnt deshalb hier, nicht im Manager.
const ANZEIGE_MAX := 12

## Kategorie daten: letzter ausgelesener Bestand (nur fuer Tests lesbar).
var letzter_bestand: Array[Dictionary] = []

## Kategorie logik: Tierbestand in beschreibbare Zeilen uebersetzen.

func zeilen_fuer(tiere: Tier_Manager) -> Array[String]:
	if tiere == null:
		return ["> Keine Tierquelle verbunden."]
	var bestand := tiere.tier_bestand()
	letzter_bestand = bestand
	if bestand.is_empty():
		return ["> Keine Tiere in der Welt."]
	var zeilen: Array[String] = ["> Tiere: %d" % bestand.size()]
	var gezeigt := mini(bestand.size(), ANZEIGE_MAX)
	for lauf in gezeigt:
		var eintrag: Dictionary = bestand[lauf]
		var tier_id: String = str(eintrag.get("tier_id", "?"))
		var pos: Variant = eintrag.get("position")
		var id: int = int(eintrag.get("id", -1))
		zeilen.append("> #%d %s @ %s" % [id, tier_id, str(pos)])
	if bestand.size() > gezeigt:
		zeilen.append("> … und %d weitere" % (bestand.size() - gezeigt))
	return zeilen
