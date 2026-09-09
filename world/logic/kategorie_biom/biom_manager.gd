extends RefCounted
class_name Welt_BiomManager
## State Machine des aktiven Bioms. Genau eine Verantwortung: Welches
## Biom ist aktiv und welchen mutierten Zustand liefert es pro Tick.
## Die Mutation wird nie doppelt gefahren, sie läuft nur hier.

## Kategorie daten: aktiver Biom Zustand.
var registry: Welt_BiomRegistry
var aktives_biom_id: String = "gemaaessigt"
var _schema: Kern_Mutationsschema

## Kategorie logik: Wechsel und Zustandsableitung.

func _init(biom_registry: Welt_BiomRegistry = null) -> void:
	registry = biom_registry if biom_registry != null else Welt_BiomRegistry.new()
	_schema = Kern_Mutationsschema.new("Welt_Biom")
	_schema.start_zustand_definieren("bestaende", {})
	_biom_mutationen_anhaengen()

func _biom_mutationen_anhaengen() -> void:
	# Jede Biom Mutation wird einmal angehängt und nur bei Biom Wechsel aktiv.
	for biom: Welt_BiomBasis in registry.biome:
		_schema.mutation_anhaengen(Welt_BiomMutation.new(biom))

func biom_wechseln(biom_id: String) -> bool:
	if not registry.hat_biom(biom_id):
		return false
	aktives_biom_id = biom_id
	return true

func aktuelles_biom() -> Welt_BiomBasis:
	return registry.biom_fuer(aktives_biom_id)

func zustand_fuer_tick(basis_zustand: Dictionary) -> Dictionary:
	var zustand := basis_zustand.duplicate(true)
	zustand["biom_id"] = aktives_biom_id
	return _schema.ausfuehren(zustand)

func effektiver_faktor() -> float:
	var biom := aktuelles_biom()
	return 1.0 if biom == null else clampf(biom.faktor, 0.1, 10.0)

func datenfeld_arten() -> Dictionary:
	return {"aktives_biom_id": "String", "registry": "Welt_BiomRegistry"}
