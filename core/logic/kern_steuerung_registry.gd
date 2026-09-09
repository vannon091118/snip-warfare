extends Welt_RegistryBasis
class_name Kern_SteuerungRegistry
## Registry der Steuerung. Liest game/data/steuerung.json als einzige Quelle;
## alles andere fragt nur noch diese Registry. WASD, Linksklick, Drag und
## Rechtsklick-Kontextmenue sind damit menschlich editierbar und sofort im
## Spiel uebersetzt. Ein faktor je Aktion wird ueber den Uebersetzer in ticks
## der globalen Weltuhr gewandelt.

const STEUERUNG_PFAD := "res://game/data/steuerung.json"

## Kategorie daten: die einzige Steuerungskonfiguration des Projekts.
var steuerung: Kern_SteuerungBasis = null

## Kategorie logik: Laden und Zugriff.

func _init() -> void:
	super(STEUERUNG_PFAD)

func schema_name() -> String:
	return "Kern_SteuerungRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Steuerung-Daten haben ein ungueltiges Format: %s" % STEUERUNG_PFAD)
		return false
	var wort := gelesen as Dictionary
	steuerung = Kern_SteuerungBasis.new()
	steuerung.aus_eintrag(wort)
	registrieren("steuerung", steuerung)
	return true

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["steuerung"] = "Kern_SteuerungBasis"
	return arten
