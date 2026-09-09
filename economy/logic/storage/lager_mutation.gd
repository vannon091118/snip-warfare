extends Kern_Mutation
class_name Lager_MutationEinlagern
## Mutation LagerEinlagern: schreibt eine Ernte in ein konkretes lokales Lager.
## Quelle RESSOURCE, abgeleitet aus dem Zustand, streng nach oben konsumiert.

var _ressource: String = ""
var _menge: int = 0
var _lager_index: int = -1

func _init(ressource: String = "", menge: int = 0, lager_index: int = -1) -> void:
	super("LagerEinlagern", Quelle.RESSOURCE, "Lagert Ressourcen im lokalen Lager ein.")
	_ressource = ressource
	_menge = menge
	_lager_index = lager_index

func anwendbar(zustand: Dictionary) -> bool:
	if not zustand.has("lager") or typeof(zustand["lager"]) != TYPE_ARRAY:
		return false
	if _lager_index < 0 or _lager_index >= zustand["lager"].size():
		return false
	if _menge <= 0:
		return false
	return true

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var lager_liste: Array = ergebnis["lager"]
	var lager: Dictionary = lager_liste[_lager_index]
	var bestaende: Dictionary = lager.get("bestaende", {})
	bestaende[_ressource] = int(bestaende.get(_ressource, 0)) + _menge
	lager["bestaende"] = bestaende
	ergebnis["letzte_lager_buchung"] = {"ressource": _ressource, "menge": _menge, "lager_index": _lager_index}
	return ergebnis
