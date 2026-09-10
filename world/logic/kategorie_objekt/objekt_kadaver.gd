extends Objekt_Basis
class_name Objekt_Kadaver
## Datenklasse des Kadaver-Weltobjekts: Ernteziel des Jägers am
## toten Tier. Sie liest ihre Werte selbst aus dem Element-Katalog
## und trägt sonst keine Logik. Alle allgemeinen Felder (id, Name,
## Textur, Logik, Modifikator) besitzt bereits die Objekt_Basis;
## dieser Klasse bleiben keine eigenen Spiegel-Felder, denn zwei
## Wahrheiten über denselben Wert sind eine zu viel.

func aus_katalog_eintrag(eintrag: Dictionary) -> void:
	# Komplett in der Basis: Der Kadaver besitzt keine eigenen Felder
	# über den Katalog hinaus. Der Super-Aufruf trägt die gesamte Wahrheit.
	super.aus_katalog_eintrag(eintrag)
