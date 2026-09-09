extends Kern_Mutation
class_name Lager_MutationEntnehmen
## Mutation LagerEntnehmen: entnimmt Ressourcen aus einem lokalen Lager.

var _ressource_e: String = ""
var _menge_e: int = 0
var _lager_index_e: int = -1

func _init(ressource: String = "", menge: int = 0, lager_index: int = -1) -> void:
	super("LagerEntnehmen", Quelle.RESSOURCE, "Entnimmt Ressourcen aus einem lokalen Lager.")
	_ressource_e = ressource
	_menge_e = menge
	_lager_index_e = lager_index

func anwendbar(zustand: Dictionary) -> bool:
	if not zustand.has("lager") or typeof(zustand["lager"]) != TYPE_ARRAY:
		return false
	if _lager_index_e < 0 or _lager_index_e >= zustand["lager"].size():
		return false
	var lager: Dictionary = zustand["lager"][_lager_index_e]
	var bestaende: Dictionary = lager.get("bestaende", {})
	return int(bestaende.get(_ressource_e, 0)) >= _menge_e and _menge_e > 0

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var lager: Dictionary = ergebnis["lager"][_lager_index_e]
	var bestaende: Dictionary = lager.get("bestaende", {})
	bestaende[_ressource_e] = int(bestaende.get(_ressource_e, 0)) - _menge_e
	lager["bestaende"] = bestaende
	ergebnis["letzte_entnahme"] = {"ressource": _ressource_e, "menge": _menge_e, "lager_index": _lager_index_e}
	return ergebnis
