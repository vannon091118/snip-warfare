extends Label
## HUD-Spitze: Job-Anzeige. Reiner Observer über die aktive Einheit.
## Sie zeigt nur, welchen USER_JOB die gewählte Einheit trägt; sie vergibt
## nichts und bricht nichts ab.
## Kette: Welt -> job_anzeigen(job_name) -> Label-Text.

## Kategorie daten: der zuletzt angezeigte Text als Zustand der Anzeige.
var letzter_text: String = ""

## Kategorie logik: Anzeigen des Job-Namens.

func _ready() -> void:
	job_anzeigen("")

func job_anzeigen(job_name: String) -> void:
	if job_name == "":
		letzter_text = "Job: keiner (Linksklick Objekt, Drag Masse, Rechtsklick Menue)"
	else:
		letzter_text = "Job: %s" % job_name
	text = letzter_text
