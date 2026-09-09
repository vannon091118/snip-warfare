extends RefCounted
class_name Kern_Mutationsschema
## Das Schema gibt die Startzustände vor und hält die Mutationsmatrix.
## Jede Domäne baut ein eigenes Schema auf dieser Basis und erweitert die
## Matrix um domänenspezifische Mutationen (Ressourcenlogik, Zufallsereignisse).
## Determinismus-Regeln:
##  1. Ohne Startzustand läuft keine Mutation.
##  2. Jede Mutation liest den Zustand und schreibt ihr Ergebnis als Zustand.
##  3. Zufall passiert nur in Mutationen mit Quelle ZUFALL und wird aus dem
##     Zustand abgeleitet; sein Ergebnis wird als Zustand festgehalten.
##  4. Die Ausführung wird als Zustandsarchiv protokolliert und ist damit
##     beliebig oft wiederholbar und prüfbar (keine False Truth).

const START_ZUSTANDS_KEY := "start_zustand"

## Kategorie daten: Schema-Name, Startzustände, Mutationsmatrix und Archiv.
var schema_name: String = ""
var start_zustaende: Dictionary = {}
var mutations_matrix: Array[Kern_Mutation] = []
var zufall: Kern_Zufall = Kern_Zufall.new()
var zustands_archiv: Array[Dictionary] = []
var angewandte_mutations_namen: Array[String] = []

## Kategorie logik: Startzustände definieren, Matrix aufbauen und ausführen.

func _init(neuer_name: String) -> void:
	schema_name = neuer_name

func start_zustand_definieren(schluessel: String, wert: Variant) -> void:
	# Startzustände werden vor dem ersten Schritt festgelegt; danach gilt:
	# Jede Mutation kann sie lesen, aber nur das Ergebnis schreiben.
	start_zustaende[schluessel] = wert
	if not zustands_archiv.is_empty():
		push_warning("Schema '%s': Startzustand nach Ausführungsbeginn geändert" % schema_name)

func mutation_anhaengen(mutation: Kern_Mutation) -> void:
	# Die Mutationsmatrix wird in fester Reihenfolge aufgebaut; die Reihenfolge
	# ist Teil des Determinismus und darf zur Laufzeit nicht umsortiert werden.
	mutations_matrix.append(mutation)

func ausfuehren(start_zustand: Dictionary) -> Dictionary:
	# Führt die komplette Matrix aus und liefert den Endzustand.
	# Der Ablauf wird als Zustandsarchiv festgehalten.
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
	# Jeder Schritt wird mit seinem vollständigen Zustand protokolliert;
	# dadurch ist jeder Zwischenstand reproduzierbar und prüfbar.
	var eintrag := zustand.duplicate(true)
	eintrag["schritt"] = schritt_name
	eintrag["schritt_nummer"] = zustands_archiv.size() + 1
	eintrag["zufallsstaende"] = zufall.zustaende_als_wort()
	zustands_archiv.append(eintrag)

func schema_daten() -> Dictionary:
	# Reine Daten über das Schema selbst, für Tests und Preflight.
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
