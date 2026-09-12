extends Job_Basis
class_name Job_BaustelleBeliefern
## Job fuer Siedler, die Baustellen mit den erforderlichen Baumaterialien beliefern.
## Koordiniert den Transportablauf vom Lager zur Baustelle.

var transport: Einheit_TransportMaschine = null

func _init() -> void:
	transport = Einheit_TransportMaschine.new()

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func _passt_zu_objekt_fallback(_element_id: String) -> bool:
	return true
