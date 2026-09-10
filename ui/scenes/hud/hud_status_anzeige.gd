extends Label
## HUD-Spitze: Status-Anzeige. Reiner Observer für Rückmeldungen an den
## Spieler (Zu weit entfernt, Massenwahl, Biom-Zustand). Sie berechnet
## nichts selbst; wer eine Meldung hat, ruft meldung_setzen auf.
## Kette: jede Quelle -> meldung_setzen(text) -> Label-Text.

## Kategorie daten: die zuletzt gesetzte Meldung und die letzte Timeline.
## Die Begründungsliste dient dem Warum-Fenster: Die letzten zehn Buchungen,
## ältester Eintrag zuerst, als Beantwortung der Frage warum ist das so.
const WARUM_MAX := 10
var letzte_meldung: String = ""
var letzte_timeline: String = ""
var _begruendungen: Array[String] = []
var _warum_knopf: Button = null
var _warum_fenster: AcceptDialog = null
var _warum_text: Label = null

## Kategorie logik: Anzeigen von Meldungen.

func warum_verdrahten(knopf: Button, fenster: AcceptDialog, text_label: Label) -> void:
	# Verdrahtung des Warum-Fensters: Die Szene übergibt ihre drei Spitzen,
	# die Anzeige besitzt sie fortan. Ein Klick öffnet, ein Schließen leert
	# nichts, die Liste bleibt als Stand der letzten zehn Begründungen stehen.
	_warum_knopf = knopf
	_warum_fenster = fenster
	_warum_text = text_label
	if _warum_knopf != null:
		_warum_knopf.pressed.connect(_auf_warum)
	if _warum_fenster != null:
		_warum_fenster.confirmed.connect(_auf_warum_geschlossen)

func _auf_warum() -> void:
	# Die Antwort auf warum: die letzten zehn Begründungen, ältester zuerst,
	# menschenlesbar wie die Timeline selbst, keine Rekonstruktion im UI.
	if _warum_fenster == null or _warum_text == null:
		return
	if _begruendungen.is_empty():
		_warum_text.text = "Noch keine Buchungen in dieser Sitzung."
	else:
		_warum_text.text = "\n".join(_begruendungen)
	_warum_fenster.popup_centered()

func _auf_warum_geschlossen() -> void:
	if _warum_knopf != null:
		_warum_knopf.release_focus()

## Kategorie logik: Anzeigen von Meldungen.

func meldung_setzen(neu: String) -> void:
	letzte_meldung = neu
	this_text_setzen(neu)

func timeline_anzeigen(begruendung: String) -> void:
	# Reine Beobachtung der Zustands-Timeline: Die Begruendung der letzten
	# Buchung wird unter der Meldung angezeigt, ohne sie zu ueberschreiben.
	# Sie wandert zugleich in die Begründungsliste des Warum-Fensters.
	letzte_timeline = begruendung
	if begruendung != "":
		_begruendungen.append(begruendung)
		while _begruendungen.size() > WARUM_MAX:
			_begruendungen.pop_front()
	var kombiniert := letzte_meldung
	if begruendung != "":
		kombiniert = (kombiniert + " | " if kombiniert != "" else "") + "Timeline: " + begruendung
	this_text_setzen(kombiniert)

func biom_anzeigen(biom_id: String, biom_faktor: float) -> void:
	meldung_setzen("Biom: %s Faktor %s" % [biom_id, str(biom_faktor)])

func this_text_setzen(neu: String) -> void:
	text = neu
