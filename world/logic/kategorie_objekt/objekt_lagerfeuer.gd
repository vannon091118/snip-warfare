extends Objekt_Basis
class_name Objekt_Lagerfeuer
## Datenklasse des Lagerfeuers. Wärmequelle mit Radius und Stärke.
## Liegt im Pool, Registry erzeugt sie, keine Sonderbehandlung.
## Die allgemeinen Felder (id, Name, Textur, Größe) besitzt bereits
## die Objekt_Basis; nur die beiden wärmespezifischen Werte aus dem
## Katalog bleiben hier, denn sie gehören allein dem Feuer.

## Kategorie daten: die beiden Feuer-eigenen Wärme-Werte.
var lagerfeuer_waerme_radius_kacheln: int = 5
var lagerfeuer_waerme_staerke: float = 1.0

## Kategorie logik: Katalog-Eintrag übernehmen.

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	# Allgemeine Wahrheit in der Basis, Feuer-Wahrheit hier.
	super.aus_katalog_eintrag(eintrag)
	lagerfeuer_waerme_radius_kacheln = int(eintrag.get("waerme_radius_kacheln", 5))
	lagerfeuer_waerme_staerke = float(eintrag.get("waerme_staerke", 1.0))
