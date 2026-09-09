extends RefCounted
class_name Kern_Mutation
## Ein einzelner Mutationsschritt des Schemas.
## Eine Mutation ist eigenständig und unabhängig: Sie bekommt den Zustand,
## entscheidet selbst, ob sie anwendbar ist, und liefert ihr Ergebnis als
## Zustand zurück. Sie ändert niemals den Ursprungszustand selbst.
## Erweiterbar: Ressourcenlogik, Tierverhalten oder zufällige Ereignisse sind
## eigene Mutationen, die dieselbe Form einhalten.

enum Quelle {
	STARTZUSTAND,
	ENTSCHEIDUNG,
	ZUFALL,
	RESSOURCE,
	Ereignis,
}

var mutations_name: String = ""
var quelle: Quelle = Quelle.ENTSCHEIDUNG
var beschreibung: String = ""

func _init(neuer_name: String, neue_quelle: Quelle = Quelle.ENTSCHEIDUNG, neue_beschreibung: String = "") -> void:
	mutations_name = neuer_name
	quelle = neue_quelle
	beschreibung = neue_beschreibung

func anwendbar(_zustand: Dictionary) -> bool:
	# Unterklassen prüfen, ob dieser Schritt auf den Zustand anwendbar ist.
	return true

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	# Unterklassen liefern einen neuen Zustand; der Ursprung bleibt unberührt.
	return zustand.duplicate(true)
