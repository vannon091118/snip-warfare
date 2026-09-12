extends RefCounted
class_name Ui_BauPanel
## Übersetzer für das Bau-Panel: Liest Möbel-Angebote aus der zentralen
## Moebel-Registry (Kategorie "Möbel" im element_katalog). Das Bau-Panel
## zeigt Möbel mit Name, Kachel-Fuß und Icon an. Keine Szene, keine
## Direkteingriffe: reine Datenaufbereitung für das UI.

## Kategorie daten: Liste der aufbereiteten Bau-Einträge für Tests lesbar.
var letzte_eintraege: Array[Dictionary] = []

## Kategorie logik: Aufbereitung der Möbel in UI-Einträge.

func eintraege_ermitteln(_definitionen: Gebaeude_DefinitionRegistry, _fortschritt: Welt_FortschrittsMaschine, _steuerung: Kern_SteuerungRegistry = null, p_registry: Welt_Registry = null) -> Array[Dictionary]:
	var ergebnis: Array[Dictionary] = []
	var registry: Welt_Registry = p_registry
	if registry == null:
		push_warning("Bau-Panel hat keine Moebel-Registry; Angebot bleibt leer")
		letzte_eintraege = ergebnis
		return ergebnis
	var moebel_registry := registry.moebel()
	for moebel_objekt: Objekt_Basis in moebel_registry.moebel_sicht():
		var tags := moebel_objekt.ziel_tags
		var fuss := moebel_registry.kachel_fuss(moebel_objekt.id)
		var kosten_str := "%dx%d Kacheln" % [fuss.x, fuss.y]
		var tooltip_str := "%s\nTags: %s" % [moebel_objekt.angezeigter_name, ", ".join(PackedStringArray(tags))]
		ergebnis.append({
			"id": moebel_objekt.id,
			"name": moebel_objekt.angezeigter_name,
			"icon_pfad": moebel_objekt.textur_pfad,
			"kosten_text": kosten_str,
			"gesperrt": false,
			"stufe": 0,
			"tooltip": tooltip_str,
		})
	letzte_eintraege = ergebnis
	return ergebnis
