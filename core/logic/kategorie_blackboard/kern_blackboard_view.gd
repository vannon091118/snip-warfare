extends RefCounted
class_name Kern_BlackboardView
## Die View: Ein Phasen-Gatter vor dem Brett. Die View kennt ihren Sektor
## fest, beim Erzeugen gesetzt; sie kann syntaktisch nicht in einen fremden
## Sektor greifen. Eine Lesephase kann nicht schreiben, eine Schreibphase
## darf nur in den eigenen Sektor. Verstoß stirbt laut, nicht still.

var _brett: Kern_Blackboard
var _eigener_sektor: String
var _phase: Phase

enum Phase {
	LESEN,
	SCHREIBEN,
	KONSOLIDIEREN,
}

func _init(brett: Kern_Blackboard, sektor: String, neue_phase: Phase) -> void:
	_brett = brett
	_eigener_sektor = sektor
	_phase = neue_phase

func lesen(schluessel: String) -> Variant:
	var sektor_inhalt := _brett.lese_sektor(_eigener_sektor)
	return sektor_inhalt.get(schluessel)

func lesen_konsolidiert(schluessel: String) -> Variant:
	# Der konsolidierte Sektor ist das gemeinsame Fenster aller Engines.
	var konsolidiert := _brett.lese_sektor(Kern_Blackboard.KONSOLIDIERT)
	return konsolidiert.get(schluessel)

func schreiben(schluessel: String, wert: Variant) -> void:
	assert(_phase == Phase.SCHREIBEN, "Schreiben ausserhalb der Schreib-Phase: %s" % _eigener_sektor)
	var sektor_inhalt := _brett.lese_sektor(_eigener_sektor)
	sektor_inhalt[schluessel] = wert
	_brett.schreibe_sektor(_eigener_sektor, sektor_inhalt)

func konsolidiert_schreiben(schluessel: String, wert: Variant) -> void:
	# Nur der Konsolidator haelt eine Konsolidieren-Phase; er schreibt genau hier.
	assert(_phase == Phase.KONSOLIDIEREN, "Konsolidiert schreiben ausserhalb der Konsolidierungs-Phase")
	var konsolidiert := _brett.lese_sektor(Kern_Blackboard.KONSOLIDIERT)
	konsolidiert[schluessel] = wert
	_brett.schreibe_sektor(Kern_Blackboard.KONSOLIDIERT, konsolidiert)
