extends RefCounted
class_name Welt_BiomBasis
## Datenklasse eines Bioms. Ein Biom ist kein eigenes System, sondern nur
## eine konfigurierbare Kombination aus Logik Verweis, Modifikator und Faktor.
## Die eigentliche Wirkung geschieht in einer dedizierten Mutationsmaschine,
## nie durch duplizierte Logik in zwei Orten.

## Kategorie daten: Biom Konfiguration aus world/data/biome.json.
var biom_id: String = ""
var biom_name: String = ""
var beschreibung: String = ""
var logik_id: String = ""
var modifikator_id: String = "normal"
var faktor: float = 1.0
var mutationen: Array[Dictionary] = []
## Barriere: Dieses Biom ist auf der Makrokarte unpassierbar (Gebirge, Ozean).
## Die Routing-Regel liegt im Netzwerk-Planer, hier steht nur die Eigenschaft
## der Landschaft.
var barriere: bool = false
var farbe: String = "#FFFFFF"
var schluessel_daten: Dictionary = {}

## Kategorie logik: Einlesen und Tick Ableitung.
func aus_eintrag(eintrag: Dictionary) -> void:
	biom_id = str(eintrag.get("id", ""))
	biom_name = str(eintrag.get("name", biom_id))
	beschreibung = str(eintrag.get("beschreibung", ""))
	logik_id = str(eintrag.get("logik_id", ""))
	modifikator_id = str(eintrag.get("modifikator_id", "normal"))
	faktor = float(eintrag.get("faktor", 1.0))
	farbe = str(eintrag.get("farbe", "#FFFFFF"))
	barriere = bool(eintrag.get("barriere", false))
	mutationen.clear()
	for mut in eintrag.get("mutationen", []):
		if typeof(mut) == TYPE_DICTIONARY:
			mutationen.append((mut as Dictionary).duplicate(true))
	schluessel_daten = eintrag.duplicate(true)

func ticks_fuer_faktor() -> int:
	return Kern_Weltuhr.ticks_aus_faktor(faktor)
