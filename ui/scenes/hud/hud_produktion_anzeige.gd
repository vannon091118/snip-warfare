extends Label
## HUD-Spitze: Produktions-Anzeige. Reiner Observer über den Gebäude-Manager:
## Sie zeigt nur die gelieferten Statuszeilen (Bauphase, Produktionsphase,
## Wartegründe) und berechnet selbst nichts.
## Kette: Gebaeude_Manager.status_zeilen -> produktion_anzeigen -> Label-Text.

## Kategorie daten: die zuletzt angezeigten Zeilen.
var letzte_zeilen: Array[String] = []

## Kategorie logik: Anzeigen der Statuszeilen.

func status_setzen(zeilen: Array[String]) -> void:
	letzte_zeilen = zeilen
	if zeilen.is_empty():
		text = "Produktion: keine Gebaeude"
	else:
		text = "Produktion: %s" % " | ".join(zeilen)