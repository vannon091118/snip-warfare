class_name Orchestrator_Status
## Kategorie logik: State Machine für Orchestrator Zustände
enum Zustand { KONFIGURIERT, AKTIV, PAUSIERT }

var zustand: Zustand = Zustand.KONFIGURIERT
var konfiguration: Orchestrator_Konfiguration

## Signals
signal zustand_geaendert(neuer_zustand: Zustand)
signal bedarf_pruefen(konfig: Orchestrator_Konfiguration)

## Kategorie daten: Zustandsverwaltung
func _zu_zustand_wechseln(neuer_zustand: Zustand) -> void:
    if zustand == neuer_zustand:
        return
    zustand = neuer_zustand
    match zustand:
        Zustand.AKTIV:
            # Tick-Connection bei Aktivierung wird vom Manager gehandhabt
            pass
        Zustand.PAUSIERT:
            # Tick abmelden wird vom Manager gehandhabt
            pass
        Zustand.KONFIGURIERT:
            pass
    zustand_geaendert.emit(zustand)

func tick() -> void:
    match zustand:
        Zustand.AKTIV:
            _bedarf_pruefen_und_vergeben()
        Zustand.PAUSIERT:
            pass
        Zustand.KONFIGURIERT:
            pass

func aktivieren() -> void:
    _zu_zustand_wechseln(Zustand.AKTIV)

func pausieren() -> void:
    _zu_zustand_wechseln(Zustand.PAUSIERT)

func konfigurieren(neue_konfig: Orchestrator_Konfiguration) -> void:
    konfiguration = neue_konfig
    _zu_zustand_wechseln(Zustand.KONFIGURIERT)

func _bedarf_pruefen_und_vergeben() -> void:
    if konfiguration:
        bedarf_pruefen.emit(konfiguration)