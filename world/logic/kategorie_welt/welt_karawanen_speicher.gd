extends RefCounted
class_name Welt_KarawanenSpeicher
## Speicher der Karawanen: Er formt den Bestand in ein Wörterbuch und wieder
## zurück, damit der Handel einen Spielstand übersteht. Reine Umformung ohne
## Tick und ohne Netzwerk; die Karawanen selbst kennen ihre eigene Form.

static func sichern(karawanen: Array[Welt_Karawane], naechste_nummer: int) -> Dictionary:
	var daten: Array[Dictionary] = []
	for karawane: Welt_Karawane in karawanen:
		if karawane != null:
			daten.append(karawane.nach_woerterbuch())
	return {
		"karawanen": daten,
		"naechste_nummer": naechste_nummer
	}

static func laden(daten: Dictionary, bestand: Array[Welt_Karawane], bestands_nummer: int) -> int:
	## Die geladenen Karawanen wandern in den übergebenen Bestand, weil ein
	## Array in Godot eine geteilte Referenz ist; zurück kommt die nächste
	## freie Nummer, damit keine Kennung doppelt entsteht.
	var k_daten: Variant = daten.get("karawanen", [])
	if typeof(k_daten) == TYPE_ARRAY:
		for eintrag: Variant in k_daten:
			if typeof(eintrag) != TYPE_DICTIONARY:
				continue
			var karawane := Welt_Karawane.new()
			if karawane.aus_woerterbuch(eintrag as Dictionary):
				bestand.append(karawane)
	return int(daten.get("naechste_nummer", bestands_nummer))
