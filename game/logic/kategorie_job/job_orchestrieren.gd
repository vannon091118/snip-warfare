extends Job_Basis
class_name Job_Orchestrieren
## Der Job, den eine Orchestrator_EinheitDerWelt permanent ausführt.
## Er ist ein "reserved" Job: Er blockiert die Einheit nicht im herkömmlichen
## Sinne, sondern steuert die Orchestrator-Zone aktiv. Der Job läuft ununterbrochen
## und wird von der Orchestrator_Manager-Logik neu zugewiesen, wenn Prioritäten
## geändert werden oder Einheiten verfügbar werden.

## Kategorie logik: Orchestrierungs-Ablauf.

func einrichten(neue_job_id: String, neue_konfiguration: Dictionary) -> void:
	super.einrichten(neue_job_id, neue_konfiguration)
	# Dieser Job hat keine festen Harvest-Parameter; seine Dauer wird von der
	# Orchestrator_Manager-Logik bestimmt. Er nutzt die Standard-Animation
	# "hacken" als Platzhalter, wird aber sofort neu gesetzt wenn die Manager-
	# Logik aktiv wird.
	fortlaufende_ticks = 0

func schritt_vorruecken() -> bool:
	# Der Job läuft ununterbrochen: Zählt immer hoch und gibt true,
	# damit der Status die Schleife neu startet, aber die eigentliche
	# Orchestrierungs-Logik steht in der Manager-klasse.
	fortlaufende_ticks += 1
	# Gebe immer true zurück, damit der Status-Schleifen-Neustart läuft.
	# Die tatsächliche Arbeit wird von Orchestrator_Manager._auf_tick() erledigt.
	return true

func harvest_zeit_ticks() -> int:
	# Dieser Job hat keine feste Harvest-Zeit; er läuft so lange wie die
	# Manager-Logik es vorgibt. Gib einen minimalen Wert zurück, damit
	der Tick-Zyklus nicht blockiert.
	return 1

func kann_ausgefuehrt_werden_von(vital: Einheit_VitalStatus) -> bool:
	# Jede Einheit kann den Orchestrator-Job ausführen, solange sie aktiv ist.
	# Die eigentliche Prüfung ob freie Einheiten verfügbar sind, obliegt
	# dem Manager.
	return vital != null