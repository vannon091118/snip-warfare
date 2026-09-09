extends Label
## HUD-Spitze: Status-Anzeige. Reiner Observer für Rückmeldungen an den
## Spieler (Zu weit entfernt, Massenwahl, Biom-Zustand). Sie berechnet
## nichts selbst; wer eine Meldung hat, ruft meldung_setzen auf.
## Kette: jede Quelle -> meldung_setzen(text) -> Label-Text.

## Kategorie daten: die zuletzt gesetzte Meldung.
var letzte_meldung: String = ""

## Kategorie logik: Anzeigen von Meldungen.

func meldung_setzen(neu: String) -> void:
	letzte_meldung = neu
	this_text_setzen(neu)

func biom_anzeigen(biom_id: String, biom_faktor: float) -> void:
	meldung_setzen("Biom: %s Faktor %s" % [biom_id, str(biom_faktor)])

func this_text_setzen(neu: String) -> void:
	text = neu
