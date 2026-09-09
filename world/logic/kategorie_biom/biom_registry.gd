extends Welt_RegistryBasis
class_name Welt_BiomRegistry
## Registry der Biome. RT-Pyramide: Ein Biom ist ein Konfigurationsblatt
## das nur ueber Mutationen wirkt. Logiken werden wiederverwendet,
## nie geteilt oder doppelt berechnet. Jedes Biom zeigt auf generische
## Logik und Modifikator und bleibt damit kombinierbar.

const BIOM_PFAD := "res://world/data/biome.json"

## Kategorie daten: getypte Liste aller Biome.
var biome: Array[Welt_BiomBasis] = []
var _biome_nach_id: Dictionary = {}

## Kategorie logik: Laden und Zugriff.

func _init() -> void:
	super(BIOM_PFAD)

func schema_name() -> String:
	return "Welt_BiomRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	var liste: Array = []
	if typeof(gelesen) == TYPE_DICTIONARY and (gelesen as Dictionary).has("biome"):
		liste = (gelesen as Dictionary)["biome"]
	elif typeof(gelesen) == TYPE_ARRAY:
		liste = gelesen
	else:
		push_warning("Biom Daten haben ein ungueltiges Format: %s" % BIOM_PFAD)
		return false
	biome.clear()
	_biome_nach_id.clear()
	eintraege.clear()
	eintraege_nach_id.clear()
	for eintrag in liste:
		if typeof(eintrag) != TYPE_DICTIONARY or not (eintrag as Dictionary).has("id"):
			continue
		var wort := eintrag as Dictionary
		var biom_id := str(wort["id"])
		var biom := Welt_BiomBasis.new()
		biom.aus_eintrag(wort)
		biome.append(biom)
		_biome_nach_id[biom_id] = biom
		registrieren(biom_id, biom)
	return true

func biom_fuer(biom_id: String) -> Welt_BiomBasis:
	if _biome_nach_id.has(biom_id):
		return _biome_nach_id[biom_id]
	return null

func hat_biom(biom_id: String) -> bool:
	return _biome_nach_id.has(biom_id)

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["biome"] = "Array[Welt_BiomBasis]"
	return arten
