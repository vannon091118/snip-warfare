extends Kern_Mutation
class_name Welt_BiomMutation
## Mutationsmaschine der Biome. Ein Biom wirkt ausschließlich als Zustand
## Mutation: Sie liest den aktuellen Weltzustand und schreibt einen neuen
## Zustand mit angepassten Faktoren. Keine zweite Berechnung an anderem Ort,
## keine geteilte Logik die zwei Dinge gleichzeitig fährt. Wiederverwendung
## heißt hier: Biom nutzt vorhandene Logiken und Modifikatoren, rechnet aber
## nur hier und nirgendwo sonst.

var biom: Welt_BiomBasis = null
var _faktor: float = 1.0

func _init(biom_basis: Welt_BiomBasis) -> void:
	biom = biom_basis
	_faktor = clampf(biom.faktor if biom != null else 1.0, 0.1, 10.0)
	super(biom.biom_id if biom != null else "BiomUnbekannt", Quelle.RESSOURCE,
		biom.beschreibung if biom != null else "Biom Mutation ohne Daten")

func anwendbar(zustand: Dictionary) -> bool:
	return biom != null and zustand.has("biom_id")

func anwenden(zustand: Dictionary, _zufall: Kern_Zufall) -> Dictionary:
	var ergebnis := zustand.duplicate(true)
	var aktiv_id := str(ergebnis.get("biom_id", biom.biom_id))
	if aktiv_id != biom.biom_id:
		return ergebnis
	# Biom Faktor wirkt als Zustand: Zielsysteme lesen nur diesen Wert.
	ergebnis["biom_faktor"] = _faktor
	ergebnis["biom_logik_id"] = biom.logik_id
	ergebnis["biom_modifikator_id"] = biom.modifikator_id
	# Sichtbares Signal: Auch die Weltfarbe kommt aus der Mutation, kein Schattenweg.
	ergebnis["biom_farbe"] = biom.farbe
	return ergebnis
