extends Kern_Mutation
class_name Einheit_InventarMutationAbgabe
## Mutation: bucht eine Abgabe (Einlagern) aus dem Inventar aus.

func _init(_konfiguration: Dictionary = {}) -> void:
	super("InventarAbgabe", Quelle.RESSOURCE,
		"Entnimmt Ressourcen aus dem Einheit-Inventar.")

func anwendbar(zustand: Dictionary) -> bool:
	return zustand.has("inventar_abgabe") and zustand.has("bestaende")

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var buchung: Dictionary = ergebnis["inventar_abgabe"]
	var ressource := str(buchung.get("ressource", ""))
	var menge := int(buchung.get("menge", 0))
	var bestaende: Dictionary = ergebnis["bestaende"]
	var aktuell := int(bestaende.get(ressource, 0))
	if aktuell < menge:
		return zustand
	bestaende[ressource] = aktuell - menge
	if bestaende[ressource] <= 0:
		bestaende.erase(ressource)
	ergebnis["letzte_buchung"] = {"ressource": ressource, "menge": menge, "art": "abgabe"}
	return ergebnis
