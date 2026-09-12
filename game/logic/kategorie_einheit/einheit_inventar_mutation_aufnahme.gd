extends Kern_Mutation
class_name Einheit_InventarMutationAufnahme
## Mutation: bucht eine Aufnahme (Ernte/Sammeln) in das Inventar.
## Die Menge wird direkt übernommen, keine Varianz (Varianz gehört zur Ernte-Maschine).

func _init(_konfiguration: Dictionary = {}) -> void:
	super("InventarAufnahme", Quelle.RESSOURCE,
		"Bucht Ressourcen in das Einheit-Inventar ein.")

func anwendbar(zustand: Dictionary) -> bool:
	return zustand.has("inventar_aufnahme") and zustand.has("bestaende")

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var buchung: Dictionary = ergebnis["inventar_aufnahme"]
	var ressource := str(buchung.get("ressource", ""))
	var menge := int(buchung.get("menge", 0))
	var bestaende: Dictionary = ergebnis["bestaende"]
	bestaende[ressource] = int(bestaende.get(ressource, 0)) + menge
	ergebnis["letzte_buchung"] = {"ressource": ressource, "menge": menge, "art": "aufnahme"}
	return ergebnis
