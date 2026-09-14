extends RefCounted
class_name Kern_Blackboard
## Das Brett: Ein Woerterbuch von Sektoeren, jeder Sektor ein Woerterbuch.
## Der Besitzer ist der Engine-Koordinator; niemand sonst haelt diese Klasse.
## Wer liest, bekommt eine Kopie. Wer schreibt, schreibt eine Kopie ein.
## Referenz-Lecks ueber Woerterbuch-Zeiger sind damit strukturell unmoeglich.

const KONSOLIDIERT := "konsolidiert"

var _sektoren: Dictionary = {}

func _init() -> void:
	_sektoren[KONSOLIDIERT] = {}

func lese_sektor(name_des_sektors: String) -> Dictionary:
	# Kopie raus: Der Leser kann aendern, was er will, das Brett bleibt.
	if not _sektoren.has(name_des_sektors):
		return {}
	return (_sektoren[name_des_sektors] as Dictionary).duplicate(true)

func schreibe_sektor(name_des_sektors: String, inhalt: Dictionary) -> void:
	# Kopie rein: Der Schreiber behaelt kein Fenster ins Brett.
	_sektoren[name_des_sektors] = inhalt.duplicate(true)

func sektoernamen() -> Array[String]:
	var namen: Array[String] = []
	for schluessel in _sektoren:
		namen.append(schluessel)
	return namen
