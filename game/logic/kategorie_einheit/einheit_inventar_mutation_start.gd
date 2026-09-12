extends Kern_Mutation
class_name Einheit_InventarMutationStart
## Mutation: nimmt die Startbestände (leeres Inventar) aus der Konfiguration.

func _init() -> void:
	super("StartBestaendeUebernehmen", Quelle.STARTZUSTAND,
		"Initialisiert das Inventar mit leeren Beständen.")

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