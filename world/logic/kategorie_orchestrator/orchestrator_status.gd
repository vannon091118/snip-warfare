extends RefCounted
class_name Orchestrator_Status
## Zustandsmaschine eines Orchestrators: KONFIGURIERT, AKTIV, PAUSIERT.
## Sie reagiert ausschließlich auf den globalen Tick und meldet Bedarf
## nach oben; die Zuweisung von Jobs macht ausschließlich der Manager.

enum Zustand {
	KONFIGURIERT,
	AKTIV,
	PAUSIERT,
}

signal zustand_geaendert(neuer_zustand: Zustand)
signal bedarf_pruefen(konfig: Orchestrator_Konfiguration)

## Kategorie daten: der aktuelle Zustand und die Zone.
var zustand: Zustand = Zustand.KONFIGURIERT
var konfiguration: Orchestrator_Konfiguration = null

## Kategorie logik: Zustandswechsel, Tick und Bedarfsmeldung.

func _zu_zustand_wechseln(neuer_zustand: Zustand) -> void:
	if zustand == neuer_zustand:
		return
	zustand = neuer_zustand
	zustand_geaendert.emit(zustand)

func konfigurieren(neue_konfig: Orchestrator_Konfiguration) -> void:
	konfiguration = neue_konfig
	_zu_zustand_wechseln(Zustand.KONFIGURIERT)

func aktivieren() -> void:
	_zu_zustand_wechseln(Zustand.AKTIV)

func pausieren() -> void:
	_zu_zustand_wechseln(Zustand.PAUSIERT)

func tick() -> void:
	match zustand:
		Zustand.AKTIV:
			_bedarf_melden()
		Zustand.PAUSIERT:
			pass
		Zustand.KONFIGURIERT:
			pass

func _bedarf_melden() -> void:
	if konfiguration != null:
		bedarf_pruefen.emit(konfiguration)
