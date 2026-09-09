extends RefCounted
class_name Ui_MenueZustaende
## Zustände des Hauptmenüs: Start, Laden, Map-Editor mit Weltauswahl.

enum Zustand {
	HAUPTMENUE,
	WELT_AUSWAHL_LADEN,
	WELT_AUSWAHL_EDITOR,
	NEUE_WELT_FRAGE,
}

func ist_gueltiger_uebergang(von: Zustand, nach: Zustand) -> bool:
	match von:
		Zustand.HAUPTMENUE:
			return nach in [Zustand.WELT_AUSWAHL_LADEN, Zustand.WELT_AUSWAHL_EDITOR]
		Zustand.WELT_AUSWAHL_LADEN:
			return nach in [Zustand.HAUPTMENUE]
		Zustand.WELT_AUSWAHL_EDITOR:
			return nach in [Zustand.HAUPTMENUE, Zustand.NEUE_WELT_FRAGE]
		Zustand.NEUE_WELT_FRAGE:
			return nach in [Zustand.WELT_AUSWAHL_EDITOR, Zustand.HAUPTMENUE]
	return false
