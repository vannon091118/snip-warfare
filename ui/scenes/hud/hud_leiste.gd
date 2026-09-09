extends VBoxContainer
## HUD-Spitze: Leiste. Sie komponiert nur die drei kleinen Observer-Spitzen
## Ressourcen, Job und Status und verbindet sie mit ihren Quellen. Sie hat
## selbst keine Logik und keinen Zustand außer den drei Kindern.
## Kette: Einheit_Ressourcen -> RessourcenLeiste; Karte -> JobAnzeige/StatusAnzeige.

@onready var _ressourcen: HBoxContainer = %RessourcenLeiste
@onready var _job: Label = %JobAnzeige
@onready var _status: Label = %StatusAnzeige
@onready var _produktion: Label = %ProduktionAnzeige

## Kategorie daten: keine eigenen Arrays; die Kinder tragen den Zustand.

## Kategorie logik: Verdrahtung der Observer.

func einrichten(ressourcen: Einheit_Ressourcen) -> void:
	(_ressourcen as Variant).einrichten(ressourcen)

func job_anzeigen(job_name: String) -> void:
	(_job as Variant).job_anzeigen(job_name)

func meldung_setzen(text: String) -> void:
	(_status as Variant).meldung_setzen(text)

func biom_anzeigen(biom_id: String, biom_faktor: float) -> void:
	(_status as Variant).biom_anzeigen(biom_id, biom_faktor)

func produktion_anzeigen(zeilen: Array[String]) -> void:
	(_produktion as Variant).status_setzen(zeilen)
