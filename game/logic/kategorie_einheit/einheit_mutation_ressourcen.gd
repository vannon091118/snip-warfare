extends Kern_Mutation
class_name Einheit_MutationStartBestaende
## Mutation: nimmt die Startbestände aus der zentralen Konfiguration.
## Muster-Vorlage für Quelle STARTZUSTAND: liest den Zustand, schreibt das
## Ergebnis als Zustand, ruft nichts anderes auf.

func _init() -> void:
	super("StartBestaendeUebernehmen", Quelle.STARTZUSTAND,
		"Übernimmt die Startbestände aus der zentralen Konfiguration.")

func anwendbar(zustand: Dictionary) -> bool:
	return not zustand.has("bestaende")

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var start_variant: Variant = ergebnis.get(Kern_Mutationsschema.START_ZUSTANDS_KEY, {})
	var start: Dictionary = start_variant as Dictionary if typeof(start_variant) == TYPE_DICTIONARY else {}
	var bestaende_variant: Variant = start.get("bestaende", {})
	var bestaende: Dictionary = (bestaende_variant as Dictionary) if typeof(bestaende_variant) == TYPE_DICTIONARY else {}
	ergebnis["bestaende"] = bestaende.duplicate(true)
	return ergebnis
