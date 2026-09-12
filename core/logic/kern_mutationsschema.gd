extends RefCounted
class_name Kern_Mutationsschema
## Haelt Startzustaende und Mutationsmatrix, fuehrt deterministisch aus und archiviert.
const START_ZUSTANDS_KEY := "start_zustand"
## Kategorie daten: Schema-Name, Startzustaende, Matrix und Archiv.
var schema_name: String = ""
var start_zustaende: Dictionary = {}
var mutations_matrix: Array[Kern_Mutation] = []
var zufall: Kern_Zufall = Kern_Zufall.new()
var zustands_archiv: Array[Dictionary] = []
var angewandte_mutations_namen: Array[String] = []
## Kategorie logik: Startzustaende definieren, Matrix aufbauen und ausfuehren.
func _init(neuer_name: String) -> void:
	schema_name = neuer_name

func start_zustand_definieren(schluessel: String, wert: Variant) -> void:
	start_zustaende[schluessel] = wert
	if not zustands_archiv.is_empty():
		push_warning("Schema '%s': Startzustand nach Ausführungsbeginn geändert" % schema_name)

func mutation_anhaengen(mutation: Kern_Mutation) -> void:
	mutations_matrix.append(mutation)

func ausfuehren(start_zustand: Dictionary) -> Dictionary:
	var zustand := start_zustand.duplicate(true)
	zustand[START_ZUSTANDS_KEY] = start_zustaende.duplicate(true)
	zustands_archiv.clear()
	angewandte_mutations_namen.clear()
	_archiv_anhaengen(zustand, "STARTZUSTAND")
	for mutation: Kern_Mutation in mutations_matrix:
		if not mutation.anwendbar(zustand):
			_archiv_anhaengen(zustand, "%s (uebersprungen)" % mutation.mutations_name)
			continue
		var ergebnis := mutation.anwenden(zustand, zufall)
		_archiv_anhaengen(ergebnis, mutation.mutations_name)
		angewandte_mutations_namen.append(mutation.mutations_name)
		zustand = ergebnis
	return zustand

func _archiv_anhaengen(zustand: Dictionary, schritt_name: String) -> void:
	var eintrag := zustand.duplicate(true)
	eintrag["schritt"] = schritt_name
	eintrag["schritt_nummer"] = zustands_archiv.size() + 1
	eintrag["zufallsstaende"] = zufall.zustaende_als_wort()
	zustands_archiv.append(eintrag)

func schema_daten() -> Dictionary:
	return {
		"schema_name": schema_name,
		"start_zustaende": start_zustaende.duplicate(true),
		"mutations_namen": _mutations_namen_lesen(),
		"archiv_groesse": zustands_archiv.size(),
	}

func _mutations_namen_lesen() -> Array[String]:
	var namen: Array[String] = []
	for mutation: Kern_Mutation in mutations_matrix:
		namen.append(mutation.mutations_name)
	return namen
