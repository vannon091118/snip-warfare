extends Kern_Mutationsschema
class_name Einheit_RessourcenSchema
## Muster-Schema der Ressourcen-Domäne: Startzustände und Mutationsmatrix
## kommen aus game/data/mutationen_ressourcen.json, die konkreten Mutationen
## sind eigene Klassen. Neue Ressourcenlogik wird als eigene Mutation
## angehängt, ohne dieses Schema zu verändern.

const MATRIX_PFAD := "res://game/data/mutationen_ressourcen.json"

var matrix_konfiguration: Dictionary = {}

func _init() -> void:
	super("Einheit_Ressourcen")
	_matrix_laden()
	_matrix_aufbauen()

func _matrix_laden() -> void:
	if not FileAccess.file_exists(MATRIX_PFAD):
		push_warning("Mutationsmatrix nicht gefunden: %s" % MATRIX_PFAD)
		return
	var datei := FileAccess.open(MATRIX_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Mutationsmatrix hat ein ungültiges Format: %s" % MATRIX_PFAD)
		return
	matrix_konfiguration = gelesen
	var start: Dictionary = matrix_konfiguration.get("start_zustaende", {})
	for schluessel: String in start.keys():
		start_zustand_definieren(schluessel, start[schluessel])

func _matrix_aufbauen() -> void:
	# Feste Reihenfolge = Determinismus. Die Reihenfolge folgt der Datei.
	var mutationen: Array = matrix_konfiguration.get("mutationen", [])
	for eintrag: Variant in mutationen:
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		mutation_anhaengen(_mutation_fuer(eintrag))

func _mutation_fuer(eintrag: Dictionary) -> Kern_Mutation:
	# Zentrale Anlaufstelle: jede neue Ressourcen-Mutation wird hier registriert.
	match str(eintrag.get("name", "")):
		"StartBestaendeUebernehmen":
			return Einheit_MutationStartBestaende.new()
		"ErnteGutschreiben":
			return Einheit_MutationErnte.new(eintrag)
	return Kern_Mutation.new(str(eintrag.get("name", "Unbenannt")), Kern_Mutation.Quelle.ENTSCHEIDUNG, str(eintrag.get("beschreibung", "")))

## Kategorie daten: Schema-Zustände (Bestände, Erntebuchungen, Zufallsergebnisse).

## Kategorie logik: Ausführung über Kern_Mutationsschema.ausfuehren().
