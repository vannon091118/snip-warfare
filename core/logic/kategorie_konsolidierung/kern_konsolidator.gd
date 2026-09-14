extends Kern_Mutation
class_name Kern_Konsolidator
## Der Konsolidator: Er liest alle Sektoren und schreibt nur in konsolidiert.
## Seine Transformationen sind eigene Kern_Mutation-Unterklassen in diesem
## Ordner; sie aendern niemals den Ursprungs-Sektor.

var _transformationen: Array[Kern_Mutation] = []

## Kategorie daten: Die Transformations-Liste als einziger Zustand des Konsolidators.
## Kategorie logik: Durchreiche und Zusammenfuehrung der Sektoren.

func _init() -> void:
	super("kern_konsolidator", Quelle.ENTSCHEIDUNG, "Liest alle Sektoren, schreibt nur konsolidiert.")

func transformation_anhaengen(transformation: Kern_Mutation) -> void:
	_transformationen.append(transformation)

func anwendbar(_zustand: Dictionary) -> bool:
	return true

func durchreichen(brett: Kern_Blackboard) -> void:
	# Die Durchreiche: Jede Transformation liest selbst, was sie braucht,
	# und liefert ein Woerterbuch neuer konsolidierter Felder.
	var view := Kern_BlackboardView.new(brett, Kern_Blackboard.KONSOLIDIERT, Kern_BlackboardView.Phase.KONSOLIDIEREN)
	for transformation in _transformationen:
		var feld := transformation.anwenden({}, Kern_Zufall.new())
		for schluessel in feld:
			view.konsolidiert_schreiben(schluessel, feld[schluessel])

func anwenden(zustand: Dictionary, zufall: Kern_Zufall) -> Dictionary:
	# Der Zustand ist das Brett als Woerterbuch: Sektorname auf Sektorinhalt.
	var ergebnis: Dictionary = zustand.get(Kern_Blackboard.KONSOLIDIERT, {}).duplicate(true)
	for transformation in _transformationen:
		ergebnis.merge(transformation.anwenden(zustand, zufall))
	return ergebnis
