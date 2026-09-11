extends RefCounted
class_name Ui_BauPanel
## Übersetzer für das Bau-Panel: Liest Gebäude-Definitionen aus der
## Gebaeude_DefinitionRegistry und gleicht ihren Freischaltungszustand mit der
## Welt_FortschrittsMaschine ab. Das Bau-Panel zeigt Gebäude mit Name,
## Baukosten, Icon und Sperrstatus an.
## Die Sperre je Gebäude ist ein Attribut der Definition (gesperrt_ab_stufe
## in world/data/gebaeude.json); dieser Übersetzer erfindet keine Stufen und
## führt keine eigene Tabelle. Keine Szene, keine Direkteingriffe: reine
## Datenaufbereitung für das UI.

## Kategorie daten: Liste der aufbereiteten Bau-Einträge für Tests lesbar.
var letzte_eintraege: Array[Dictionary] = []

## Kategorie logik: Aufbereitung der Gebäude in UI-Einträge.

func eintraege_ermitteln(definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine, _steuerung: Kern_SteuerungRegistry = null) -> Array[Dictionary]:
	var ergebnis: Array[Dictionary] = []
	if definitionen == null:
		letzte_eintraege = ergebnis
		return ergebnis
	var alle := definitionen.alle_definitionen()
	for def: Gebaeude_Definition in alle:
		# Die Stufe kommt ausschließlich aus der Definition; der Parameter
		# _steuerung bleibt als Vertrag für bestehende Aufrufer erhalten.
		var stufe := def.gesperrt_ab_stufe
		var gesperrt := false
		if fortschritt != null:
			gesperrt = not fortschritt.stufe_frei(stufe)
		var kosten_teile: Array[String] = []
		for ressource: String in def.baukosten:
			var menge := int(def.baukosten[ressource])
			if menge > 0:
				kosten_teile.append("%d %s" % [menge, ressource.capitalize()])
		var kosten_str := ", ".join(kosten_teile) if not kosten_teile.is_empty() else "Kostenlos"
		var tooltip_str := "%s\nKosten: %s\nBauzeit: %d Ticks" % [def.angezeigter_name, kosten_str, def.bauzeit_ticks]
		if gesperrt:
			tooltip_str = "🔒 Gesperrt (Benötigt Stufe %d)\n%s" % [stufe, tooltip_str]
		ergebnis.append({
			"id": def.id,
			"name": def.angezeigter_name,
			"icon_pfad": def.icon_pfad,
			"kosten_text": kosten_str,
			"gesperrt": gesperrt,
			"stufe": stufe,
			"tooltip": tooltip_str,
		})
	letzte_eintraege = ergebnis
	return ergebnis
