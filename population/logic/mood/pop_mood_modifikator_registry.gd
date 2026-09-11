extends Welt_RegistryBasis
class_name Pop_MoodModifikatorRegistry
## Registry der Mood-Modifikatoren. Quelle population/data/mood_modifikatoren.json.
## Jede Variante ist eine eigene Klasse, Erweiterung nur über Pool + Registry.

const QUELLE := "res://population/data/mood_modifikatoren.json"

## Kategorie daten: getypte Liste aller Modifikatoren.
var modifikatoren: Array[Pop_MoodModifikator] = []
var _nach_id: Dictionary = {}

## Kategorie logik: Laden und zentrale Zuordnung.
func _init() -> void:
	super(QUELLE)

func schema_name() -> String:
	return "Pop_MoodModifikatorRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Mood-Modifikatoren haben ungültiges Format: %s" % QUELLE)
		return false
	modifikatoren.clear()
	_nach_id.clear()
	eintraege.clear()
	eintraege_nach_id.clear()
	for eintrag_id: String in (gelesen as Dictionary).keys():
		if eintrag_id.begins_with("_"):
			continue
		var eintrag: Dictionary = (gelesen as Dictionary)[eintrag_id]
		var mod := Pop_MoodModifikator.new()
		mod.aus_eintrag(eintrag_id, eintrag)
		modifikatoren.append(mod)
		_nach_id[eintrag_id] = mod
		registrieren(eintrag_id, mod)
	return true

func mod_fuer(mod_id: String) -> Pop_MoodModifikator:
	return _nach_id.get(mod_id, null)

func hat_mod(mod_id: String) -> bool:
	return _nach_id.has(mod_id)

func mod_fuer_need(need_id: String) -> Pop_MoodModifikator:
	# Erster Modifikator, der diesen Bedarf eskaliert; die Reihenfolge der
	# Einträge im Pool entscheidet, welcher das Ruder übernimmt. Die
	# verzahnten Folgestufen werden weiterhin über mod_fuer aufgelöst.
	for mod in modifikatoren:
		if mod.need_id == need_id:
			return mod
	return null

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["modifikatoren"] = "Array[Pop_MoodModifikator]"
	return arten
