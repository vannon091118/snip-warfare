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

## Kategorie logik: Eingabe-Aktionen (InputMap) aus der geladenen Konfiguration.

## Erzeugt die Kamera-Richtungs-Aktionen der Engine aus kamera.tasten und
## kamera.alternativ_tasten. Genau eine Stelle im Projekt schreibt in die
## InputMap, und sie liest ausschließlich die hier geladene Konfiguration.
## Beide Listen landen auf denselben vier Aktionen: WASD und Pfeile wirken
## daneben, statt die eingebauten ui_-Aktionen zu verbiegen. Doppelte
## Aufrufe sind harmlos, bestehende Ereignisse bleiben stehen. Rückgabe
## ist die Zahl der geprüften Tasten-Einträge.
func inputmap_registrieren() -> int:
	if steuerung == null:
		return 0
	var geprueft := 0
	geprueft += steuerung._aktion_auffuellen(steuerung.kamera_tasten, Kern_SteuerungBasis.KAMERA_RICHTUNGS_AKTIONEN)
	geprueft += steuerung._aktion_auffuellen(Kern_SteuerungBasis.tastenliste_aufloesen(steuerung.kamera_alternativ), Kern_SteuerungBasis.KAMERA_RICHTUNGS_AKTIONEN)
	return geprueft
