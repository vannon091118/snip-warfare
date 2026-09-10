extends Ressource_Basis
class_name Ressource_Holz
## Datenklasse der Ressource Holz. Sie besitzt keine eigenen Felder,
## denn die Katalog-Wahrheit trägt bereits die Ressource_Basis; die
## ehemaligen wood_*-Spiegel sind gefallen, zwei Wahrheiten über
## denselben Wert waren eine zu viel.

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	# Eine Wahrheit: super trägt id, Name, Icon und Farbe, hier bleibt
	# nichts Eigenes. Vorgabewerte nur, falls der Katalog-Eintrag fehlt.
	super.aus_konfig_eintrag(eintrag)
	if not eintrag.has("id"):
		ressourcen_id = "holz"
	if not eintrag.has("name"):
		ressourcen_name = "Holz"
	if not eintrag.has("icon_pfad"):
		icon_pfad = "res://world/assets/ui/ressource_holz.svg"
	if not eintrag.has("farbe"):
		farbe = Color("#8B5A2B")
