extends Kern_Mutation
class_name Einheit_MutationErnte
## Mutation: bucht die Ernte einer Einheit auf den Bestand.
## Die Varianz (80 bis 120 Prozent) wird aus dem Zustand abgeleitet: Zuerst
## wird der Zufallszustand als Ergebnis in den Zustand geschrieben, dann
## erst die Menge berechnet. Dieselben Zustände liefern dieselbe Menge.

var varianz_aktiv: bool = true
var minimum_anteil: float = 0.8
var maximum_anteil: float = 1.2
var mindest_menge: int = 1

func _init(konfiguration: Dictionary = {}) -> void:
	super("ErnteGutschreiben", Quelle.RESSOURCE,
		"Bucht die Ernte auf den Bestand, Varianz aus dem Zustand abgeleitet.")
	var varianz: Dictionary = konfiguration.get("varianz", {})
	varianz_aktiv = bool(varianz.get("aktiv", true))
	minimum_anteil = float(varianz.get("minimum_anteil", 0.8))
	maximum_anteil = float(varianz.get("maximum_anteil", 1.2))
	mindest_menge = int(varianz.get("mindest_menge", 1))

func anwendbar(zustand: Dictionary) -> bool:
	return zustand.has("erntebuchung") and zustand.has("bestaende")

func anwenden(zustand: Dictionary, zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var buchung: Dictionary = ergebnis["erntebuchung"]
	var ressource := str(buchung.get("ressource", ""))
	var basis_menge := int(buchung.get("menge", 0))
	var final_menge := basis_menge
	if varianz_aktiv and basis_menge > 0:
		# Schritt 1: Zufallsergebnis als Zustand festhalten.
		var wurf := zufall.naechste_zahl()
		ergebnis["letzter_zufallswurf"] = wurf
		# Schritt 2: Menge deterministisch aus dem festgehaltenen Ergebnis berechnen.
		var anteil := minimum_anteil + float(wurf % 10001) / 10000.0 * (maximum_anteil - minimum_anteil)
		final_menge = maxi(int(round(float(basis_menge) * anteil)), mindest_menge)
	var bestaende: Dictionary = ergebnis["bestaende"]
	bestaende[ressource] = int(bestaende.get(ressource, 0)) + final_menge
	ergebnis["letzte_buchung"] = {"ressource": ressource, "menge": final_menge}
	return ergebnis
