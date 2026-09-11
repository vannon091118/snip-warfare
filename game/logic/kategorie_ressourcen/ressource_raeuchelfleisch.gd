extends Ressource_Basis
class_name Ressource_Raeuchelfleisch
## Datenklasse der Ressource Räucherfleisch. Sie besitzt keine eigenen
## Felder, denn die Katalog-Wahrheit trägt bereits die Ressource_Basis;
## bis zu diesem Slice fiel die Buchung still auf die Basis zurück, obwohl
## Asset und Icon existierten. Jetzt trägt der Pool-Eintrag das script-Feld.

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	# Eine Wahrheit: super trägt id, Name, Icon und Farbe, hier bleibt
	# nichts Eigenes. Vorgabewerte nur, falls der Katalog-Eintrag fehlt.
	super.aus_konfig_eintrag(eintrag)
	if not eintrag.has("id"):
		ressourcen_id = "raeuchelfleisch"
	if not eintrag.has("name"):
		ressourcen_name = "Räucherfleisch"
	if not eintrag.has("icon_pfad"):
		icon_pfad = "res://world/assets/ui/ressource_raeuchelfleisch.svg"
	if not eintrag.has("farbe"):
		farbe = Color("#A64B2A")
