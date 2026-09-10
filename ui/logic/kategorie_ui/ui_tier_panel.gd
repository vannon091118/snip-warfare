extends RefCounted
class_name Ui_TierPanel
## Uebersetzer der Tiere: Liest nur ueber den geschlossenen Schnittpunkt
## Tier_Manager.tier_bestand(). Niemals _tiere direkt. Ein Fenster ruft nur
## diesen Uebersetzer.
## Schnittregel: Neue Tierdaten kommen nur ueber den Manager-Snapshot.

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
	for eintrag: Dictionary in bestand:
		var tier_id: String = str(eintrag.get("tier_id", "?"))
		var pos: Variant = eintrag.get("position")
		var id: int = int(eintrag.get("id", -1))
		zeilen.append("> #%d %s @ %s" % [id, tier_id, str(pos)])
	return zeilen
