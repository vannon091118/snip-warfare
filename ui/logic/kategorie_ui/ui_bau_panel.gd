extends RefCounted
class_name Ui_BauPanel
## Kategorie daten: UI-Eintragsliste letzte_eintraege als reine Datenhaltung des Baufensters.
## Kategorie logik: Registry-Gating in UI-Einträge übersetzen und filtern.
## Übersetzer des Baufensters: Liest Bauobjekte ausschließlich aus der
## Gebaeude_DefinitionRegistry (world/data/gebaeude.json). Das Baufenster
## zeigt Name, Kosten, Kategorie, Icon und Freischaltung an. Keine Szene,
## keine Direkteingriffe: reine Datenaufbereitung für das UI.
##
## Verantwortlichkeit: Bauobjekte aus Registry + Gating-Maschine in
## UI-Einträge übersetzen. Kategorien und Suche filtert die Baufenster-Szene.
##
## Erweiterung ohne UI-Code: Ein neuer Eintrag in gebaeude.json trägt
## Kategorie, Kosten und gesperrt_ab_stufe; diese Klasse und die Szene
## erfassen ihn automatisch.

var letzte_eintraege: Array[Dictionary] = []

func eintraege_ermitteln(definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine, _steuerung: Kern_SteuerungRegistry = null, _p_registry: Welt_Registry = null) -> Array[Dictionary]:
	var ergebnis: Array[Dictionary] = []
	if definitionen == null:
		ergebnis.sort_custom(_nach_name)
		letzte_eintraege = ergebnis
		return ergebnis
	for definition: Gebaeude_Definition in definitionen.alle_definitionen():
		var gesperrt := false
		if fortschritt != null:
			gesperrt = not fortschritt.stufe_frei(definition.gesperrt_ab_stufe)
		if gesperrt:
			continue
		var kosten_text := _kosten_text_fuer(definition)
		var tooltip_str := _tooltip_fuer(definition, fortschritt)
		ergebnis.append({
			"id": definition.id,
			"name": definition.angezeigter_name,
			"kategorie": definition.kategorie,
			"bautyp": definition.bautyp,
			"icon_pfad": definition.icon_pfad,
			"kosten_text": kosten_text,
			"gesperrt": gesperrt,
			"stufe": definition.gesperrt_ab_stufe,
			"tooltip": tooltip_str,
		})
	ergebnis.sort_custom(_nach_name)
	letzte_eintraege = ergebnis
	return ergebnis

func eintraege_alle(definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine = null) -> Array[Dictionary]:
	## Verwendet, wenn die Szene eingemachte Filter zusätzlich nutzen will.
	return eintraege_ermitteln(definitionen, fortschritt, null, null)

func kategorien(definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine = null) -> Array[String]:
	var verfuegbar: Array[String] = []
	if definitionen == null:
		return verfuegbar
	for definition: Gebaeude_Definition in definitionen.alle_definitionen():
		if fortschritt != null and not fortschritt.stufe_frei(definition.gesperrt_ab_stufe):
			continue
		var kategorie := str(definition.kategorie)
		if kategorie != "" and not verfuegbar.has(kategorie):
			verfuegbar.append(kategorie)
	verfuegbar.sort()
	return verfuegbar

func _kosten_text_fuer(definition: Gebaeude_Definition) -> String:
	if definition.baukosten.is_empty():
		return "kostenlos"
	var teile: Array[String] = []
	for paar in definition.baukosten_paare():
		teile.append("%d %s" % [int(paar.get("menge", 0)), str(paar.get("ressource", ""))])
	return ", ".join(teile)

func _tooltip_fuer(definition: Gebaeude_Definition, _fortschritt: Welt_FortschrittsMaschine) -> String:
	var kosten := _kosten_text_fuer(definition)
	var zeile := "%s (%s)" % [definition.kategorie, kosten]
	if definition.bautyp != "" and definition.bautyp != "gebaeude":
		zeile += "\nBautyp: %s" % definition.bautyp
	if not definition.platzierung.is_empty():
		zeile += "\nPlatzierung: %s" % str(definition.platzierung)
	if not definition.benoetigt_tags.is_empty():
		zeile += "\nTags: %s" % ", ".join(definition.benoetigt_tags)
	return zeile

func _nach_name(a: Dictionary, b: Dictionary) -> bool:
	var ta := str(a.get("kategorie", "")) + str(a.get("name", ""))
	var tb := str(b.get("kategorie", "")) + str(b.get("name", ""))
	return ta < tb
