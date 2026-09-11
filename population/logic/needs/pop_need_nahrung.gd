extends Pop_NeedBasis
class_name Pop_NeedNahrung
## Nahrungsbedürfnis: Hunger. Kann mehrere Ressourcen als Nahrungsquellen
## summieren (Fleisch und Beeren). Die primäre Ressource steht in needs.json,
## Zusatzquellen im Feld ressource_zusatz als Liste.
## Keine eigene Zeit, keine eigene Logik außer dem Verfügbarkeits-Check.

## Kategorie daten: Zusätzliche Nahrungsressourcen neben der Primärressource.
var ressource_zusatz: Array[String] = []

## Kategorie logik: Einlesen aus Konfiguration und Abfrage der Bestände.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	super.aus_konfig_eintrag(eintrag)
	ressource_zusatz.clear()
	var zusatz: Variant = eintrag.get("ressource_zusatz", [])
	if typeof(zusatz) == TYPE_ARRAY:
		for wert: Variant in zusatz as Array:
			ressource_zusatz.append(str(wert))

## Summe aller Nahrungsressourcen im Lager: Primärressource plus Zusatzquellen.
## Aufrufer (Pop_MoodMaschine) prüft hat_verfuegbar_override() zuerst.
func verfuegbar_summe(lager: Lager_Manager) -> int:
	if lager == null:
		return 0
	var summe := lager.gesamt_bestand(ressource)
	for zusatz_ressource: String in ressource_zusatz:
		summe += lager.gesamt_bestand(zusatz_ressource)
	return summe

func hat_verfuegbar_override() -> bool:
	return true
