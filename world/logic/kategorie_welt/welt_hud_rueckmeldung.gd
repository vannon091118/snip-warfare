extends RefCounted
class_name Welt_HudRueckmeldung
## HUD-Rückmelde-Spitze: Bündelt die reinen Anzeige-Handler zwischen den
## Maschinen und dem HUD. Eine Meldung kommt an, das HUD zeigt sie; hier
## wird nichts nachgerechnet und nichts koordiniert. Die Szene verbindet
## ihre Signale einmalig auf diese Spitze statt zehn Handler zu halten.

## Kategorie daten: HUD- und Fortschritts-Referenz als Anzeige-Ziele.
var _hud: VBoxContainer = null
var _fortschritt: Welt_FortschrittsMaschine = null

## Kategorie logik: Meldung empfangen, HUD zeigen.

func einrichten(hud: VBoxContainer, fortschritt: Welt_FortschrittsMaschine) -> void:
	_hud = hud
	_fortschritt = fortschritt

func produktion_anzeigen(zeilen: Array[String]) -> void:
	# Reiner Weitergabe-Schritt: Die Zeilen kommen vom Gebaeude_Manager, das
	# HUD zeigt sie; niemand rechnet etwas nach.
	if _hud != null:
		(_hud as Variant).produktion_anzeigen(zeilen)

func gebaeude_meldung_anzeigen(meldung_text: String) -> void:
	if _hud != null:
		_hud.meldung_setzen(meldung_text)

func ziel_erreicht_anzeigen(stufe: Dictionary) -> void:
	if _hud == null:
		return
	_hud.meldung_setzen("Ziel erreicht: %s" % str(stufe.get("id", "")))
	if _fortschritt != null:
		_hud.meldung_setzen(_fortschritt.ziel_zeile())

func timeline_anzeigen(delta_text: String) -> void:
	# Reine Beobachtung: Die Timeline meldet, das HUD zeigt die Begruendung,
	# und der Bus trägt sie an die übrigen Zuhörer weiter.
	if _hud != null:
		_hud.timeline_anzeigen(delta_text)
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_timeline_eintrag(delta_text)

func biom_anzeigen(biom_id: String, biom_faktor: float) -> void:
	if _hud != null:
		(_hud as Variant).biom_anzeigen(biom_id, biom_faktor)
