extends RefCounted
class_name Ui_GrundsatzPanel
## Übersetzer des Grundsatz-Fensters: Liest die Schalter der Kolonie-Moral
## ausschließlich über den geschlossenen Schnittpunkt
## Einheit_Manager.moral_grundsatz_lesen() und moral_grundsatz_setzen().
## Keine Szene, kein Direktgriff ins Moral-Innere: reine Datenaufbereitung
## für das UI. Das Fenster zeigt je Grundsatz Label, Tooltip und Haken;
## ein Klick meldet die Änderung, der Manager verteilt sie weiter.
##
## Verantwortlichkeit: Moral-Grundsätze in UI-Einträge übersetzen und die
## Wahl des Spielers zurückmelden. Erweiterung ohne UI-Code: Ein neuer
## Schalter in moral_regeln.json plus einer Zeile in SCHALTER_TEXTE
## erscheint automatisch im Fenster.

## Kategorie daten: letzter ausgelesener Stand (nur für Tests lesbar).
var letzte_eintraege: Array[Dictionary] = []

## Kategorie logik: Schalter lesen, setzen, als UI-Einträge übersetzen.

func eintraege_ermitteln(manager: Einheit_Manager) -> Array[Dictionary]:
	## Die Schalter-Liste kommt über die statische Brücke der Moral-Domäne;
	## UI und population treffen sich nur an dieser einen Naht.
	var ergebnis: Array[Dictionary] = []
	if manager == null:
		letzte_eintraege = ergebnis
		return ergebnis
	for schalter_id: String in _schalter_ids(manager):
		var text: Dictionary = _schalter_text(manager, schalter_id)
		ergebnis.append({
			"id": schalter_id,
			"label": str(text.get("label", schalter_id)),
			"tooltip": str(text.get("tooltip", "")),
			"erlaubt": manager.moral_grundsatz_lesen(schalter_id),
		})
	letzte_eintraege = ergebnis
	return ergebnis

func grundsatz_setzen(manager: Einheit_Manager, schalter_id: String, erlaubt: bool) -> void:
	manager.moral_grundsatz_setzen(schalter_id, erlaubt)


func _schalter_text(_manager: Einheit_Manager, schalter_id: String) -> Dictionary:
	## Label und Tooltip trägt die Moral-Instanz als Domänen-Daten; die UI
	## kopiert sie nur, ohne eine Instanz zu halten.
	return Pop_MoralInstanz.schalter_text_statisch(schalter_id)
