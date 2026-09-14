extends RefCounted
class_name Welt_FortschrittPersistenz
## Persistenz der Einstiegs-Progression: Sie liest und schreibt genau die
## zwei Fortschritts-Felder (Stufen-Zeiger, Abschluss-Buch) am Welt_Model.
## Die Maschine ruft sie auf; sie kennt selbst keine Stufen-Logik.

const FELD_STUFE := "fortschritt_stufe"
const FELD_ABGESCHLOSSEN := "fortschritt_abgeschlossen"

var stufe_index: int = 0
var abgeschlossen: Dictionary = {}

func speichern(model: Welt_Model, stufe: int, buch: Dictionary) -> void:
	if model == null:
		return
	model.objekt_feld_setzen(0, FELD_STUFE, stufe)
	model.objekt_feld_setzen(0, FELD_ABGESCHLOSSEN, buch.duplicate(true))

func laden(model: Welt_Model) -> void:
	if model == null:
		return
	stufe_index = int(model.objekt_feld(0, FELD_STUFE, 0))
	var buch: Variant = model.objekt_feld(0, FELD_ABGESCHLOSSEN, null)
	if typeof(buch) == TYPE_DICTIONARY:
		abgeschlossen = (buch as Dictionary).duplicate(true)
