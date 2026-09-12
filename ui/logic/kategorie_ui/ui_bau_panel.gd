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

func eintraege_ermitteln(_definitionen: Gebaeude_DefinitionRegistry, _fortschritt: Welt_FortschrittsMaschine, _steuerung: Kern_SteuerungRegistry = null) -> Array[Dictionary]:
	var ergebnis: Array[Dictionary] = []
	# Statt Gebäude lesen wir Möbel aus möbel.json
	var moebel_pfad := "res://game/data/möbel.json"
	var datei := FileAccess.open(moebel_pfad, FileAccess.READ)
	if datei == null:
		push_warning("Möbel-JSON nicht gefunden: %s" % moebel_pfad)
		letzte_eintraege = ergebnis
		return ergebnis
	var text := datei.get_as_text()
	datei.close()
	var daten: Variant = JSON.parse_string(text)
	if typeof(daten) != TYPE_ARRAY:
		push_warning("Möbel-JSON hat ungueltiges Format")
		letzte_eintraege = ergebnis
		return ergebnis
	for eintrag in daten as Array:
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		var eid := str(eintrag.get("id", ""))
		var name := str(eintrag.get("name", eid))
		var tags: Array = eintrag.get("tags", []) as Array
		var icon_pfad := str(eintrag.get("asset-path", ""))
		# Für Möbel gibt es keine Baukosten oder Bauzeit im Sinne des Panels;
		# wir zeigen einfache Infos.
		var kosten_str := "Kostenlos"  # oder könnte aus tags bestehen
		var tooltip_str := "%s\nTags: %s" % [name, ", ".join(PackedStringArray(tags))]
		ergebnis.append({
			"id": eid,
			"name": name,
			"icon_pfad": icon_pfad,
			"kosten_text": kosten_str,
			"gesperrt": false,
			"stufe": 0,
			"tooltip": tooltip_str,
		})
	letzte_eintraege = ergebnis
	return ergebnis
