extends Kern_Mutationsschema
class_name Einheit_InventarSchema
## Mutationsschema für das physische Inventar einer Einheit.
## Startzustände und Mutationsmatrix kommen aus game/data/mutationen_inventar.json.

const MATRIX_PFAD := "res://game/data/mutationen_inventar.json"

var matrix_konfiguration: Dictionary = {}

func _init() -> void:
	super("Einheit_Inventar")
	_matrix_laden()
	_matrix_aufbauen()

func _matrix_laden() -> void:
	if not FileAccess.file_exists(MATRIX_PFAD):
		push_warning("Inventar-Mutationsmatrix nicht gefunden: %s" % MATRIX_PFAD)
		return
	var datei := FileAccess.open(MATRIX_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Inventar-Mutationsmatrix hat ein ungültiges Format: %s" % MATRIX_PFAD)
		return
	matrix_konfiguration = gelesen
	var start: Dictionary = matrix_konfiguration.get("start_zustaende", {})
	for schluessel: String in start.keys():
		start_zustand_definieren(schluessel, start[schluessel])

func _matrix_aufbauen() -> void:
	var mutationen: Array = matrix_konfiguration.get("mutationen", [])
	for eintrag: Variant in mutationen:
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		mutation_anhaengen(_mutation_fuer(eintrag))

func _mutation_fuer(eintrag: Dictionary) -> Kern_Mutation:
	match str(eintrag.get("name", "")):
		"StartBestaendeUebernehmen":
			return Einheit_InventarMutationStart.new()
		"InventarAufnahme":
			return Einheit_InventarMutationAufnahme.new(eintrag)
		"InventarAbgabe":
			return Einheit_InventarMutationAbgabe.new(eintrag)
	return Kern_Mutation.new(str(eintrag.get("name", "Unbenannt")), Kern_Mutation.Quelle.ENTSCHEIDUNG, str(eintrag.get("beschreibung", "")))
