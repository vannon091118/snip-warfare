extends Objekt_Basis
class_name Objekt_TischStahl
## Ein Stahl-Tisch-Möbelobjekt. Erbt von Objekt_Basis und liest seine
## Werte aus dem Katalog-Eintrag. Der Renderer malt das SVG und der
## Kontextmenü-Handler nutzt die ziel_tags für Aktionen wie "Abbauen".

func _ready() -> void:
	# Initialisierung, falls nötig; reine Daten kommen aus dem Katalog.
	pass