extends Label
## HUD-Spitze: Status-Anzeige. Reiner Observer für Rückmeldungen an den
## Spieler (Zu weit entfernt, Massenwahl, Biom-Zustand). Sie berechnet
## nichts selbst; wer eine Meldung hat, ruft meldung_setzen auf.
## Kette: jede Quelle -> meldung_setzen(text) -> Label-Text.

## Kategorie daten: die zuletzt gesetzte Meldung und die letzte Timeline.
var letzte_meldung: String = ""
var letzte_timeline: String = ""

## Kategorie logik: Anzeigen von Meldungen.

func meldung_setzen(neu: String) -> void:
	letzte_meldung = neu
	this_text_setzen(neu)

func timeline_anzeigen(begruendung: String) -> void:
	# Reine Beobachtung der Zustands-Timeline: Die Begruendung der letzten
	# Buchung wird unter der Meldung angezeigt, ohne sie zu ueberschreiben.
	letzte_timeline = begruendung
	var kombiniert := letzte_meldung
	if begruendung != "":
		kombiniert = (kombiniert + " | " if kombiniert != "" else "") + "Timeline: " + begruendung
	this_text_setzen(kombiniert)

func biom_anzeigen(biom_id: String, biom_faktor: float) -> void:
	meldung_setzen("Biom: %s Faktor %s" % [biom_id, str(biom_faktor)])

func this_text_setzen(neu: String) -> void:
	text = neu
