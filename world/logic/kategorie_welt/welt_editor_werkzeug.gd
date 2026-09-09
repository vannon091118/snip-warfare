extends RefCounted
class_name Welt_EditorWerkzeug
## Zustandsmaschine des Karten-Editors: welche Werkzeug-Aktion aktiv ist.
## Der Kreativmodus ist das Modus-Fenster des Editors; hier entstehen Testkarten.

enum Werkzeug {
	PLATZIEREN,
	ENTFERNEN,
	GREIFEN,
}

enum Fenster {
	KREATIV,
}

var modus_fenster: Fenster = Fenster.KREATIV
var aktives_werkzeug: Werkzeug = Werkzeug.PLATZIEREN
var gewaehltes_element: String = "baum"
var gezogenes_objekt: int = -1

func waehle_werkzeug(werkzeug: Werkzeug) -> bool:
	if werkzeug == aktives_werkzeug:
		return false
	aktives_werkzeug = werkzeug
	if werkzeug != Werkzeug.GREIFEN:
		gezogenes_objekt_loesen()
	return true

func waehle_element(element_id: String) -> void:
	gewaehltes_element = element_id
	if aktives_werkzeug == Werkzeug.ENTFERNEN or aktives_werkzeug == Werkzeug.GREIFEN:
		aktives_werkzeug = Werkzeug.PLATZIEREN
	gezogenes_objekt_loesen()

func objekt_greifen(objekt_index: int) -> bool:
	if aktives_werkzeug == Werkzeug.ENTFERNEN:
		return false
	gezogenes_objekt = objekt_index
	aktives_werkzeug = Werkzeug.GREIFEN
	return true

func objekt_ablegen() -> void:
	gezogenes_objekt_loesen()

func gezogenes_objekt_loesen() -> void:
	gezogenes_objekt = -1
	if aktives_werkzeug == Werkzeug.GREIFEN:
		aktives_werkzeug = Werkzeug.PLATZIEREN

func zieht_gerade() -> bool:
	return gezogenes_objekt != -1
