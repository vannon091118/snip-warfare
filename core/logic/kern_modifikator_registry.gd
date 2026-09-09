extends Welt_RegistryBasis
class_name Kern_ModifikatorRegistry
## Registry der Modifikatoren. Jeder Modifikator trägt einen Faktor.
## Faktor 1.0 entspricht 10 Sekunden; die Weltuhr übersetzt den Faktor
## zentral in Ticks. Objekte und Tiere wählen nur ihren Modifikator
## über die Registry, ohne eine neue Verhaltensklasse zu brauchen.

const MODIFIKATOR_PFAD := "res://core/data/kern_modifikatoren.json"

## Kategorie daten: getypte Liste aller Modifikatoren.

var modifikatoren: Array[Kern_ModifikatorBasis] = []
var _modifikatoren_nach_id: Dictionary = {}

## Kategorie logik: Laden und Zugriff.

func _init() -> void:
	super(MODIFIKATOR_PFAD)

func schema_name() -> String:
	return "Kern_ModifikatorRegistry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Modifikator-Daten haben ein ungültiges Format: %s" % MODIFIKATOR_PFAD)
		return false
	modifikatoren.clear()
	_modifikatoren_nach_id.clear()
	for eintrag_id: String in (gelesen as Dictionary).keys():
		var eintrag: Dictionary = gelesen[eintrag_id]
		var modifikator := Kern_ModifikatorBasis.new()
		modifikator.aus_eintrag(eintrag_id, eintrag)
		modifikatoren.append(modifikator)
		_modifikatoren_nach_id[eintrag_id] = modifikator
		registrieren(eintrag_id, modifikator)
	return true

func modifikator_fuer(modifikator_id: String) -> Kern_ModifikatorBasis:
	if _modifikatoren_nach_id.has(modifikator_id):
		return _modifikatoren_nach_id[modifikator_id]
	return null

func hat_modifikator(modifikator_id: String) -> bool:
	return _modifikatoren_nach_id.has(modifikator_id)

## Liefert die Ticks für die gegebene Faktor-Angabe.
## 1.0 bedeutet zehn Sekunden; die Ticks ergeben sich aus der Weltuhr.
func ticks_fuer_faktor(faktor: float) -> int:
	var geklemmt := clampf(faktor, 0.1, 10.0)
	return maxi(int(round(geklemmt * 10.0 * Kern_Weltuhr.TICK_RATE_HZ)), 1)

## Liefert die Ticks für einen benannten Modifikator aus der Registry.
func ticks_fuer_modifikator(modifikator_id: String) -> int:
	var modifikator := modifikator_fuer(modifikator_id)
	if modifikator == null:
		return ticks_fuer_faktor(1.0)
	return ticks_fuer_faktor(modifikator.faktor)

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["modifikatoren"] = "Array[Kern_ModifikatorBasis]"
	return arten
