extends RefCounted
class_name Einheit_Bewegung
## Bewegungs-Maschine einer Einheit: Sie trägt Gehziel, Wegpunkte, Tempo und
## Reichweite und liefert je Tick genau eine Richtung. Die Position selbst
## gehört der Einheit; diese Maschine setzt sie niemals.

var _geh_ziel := Vector2.ZERO
var _weg_ziele := PackedVector2Array()
var _weg_index := 0
var _tempo := 0.0
var _reichweite := 0.0
var _rasse_faktor := 1.0
var _modifikatoren := Kern_ModifikatorMaschine.new()

func _init() -> void:
	# Der Bereich Bewegung kommt aus den globalen Settings; bei einer
	# Menü-Gegenprüfung werden Tempo und Reichweite übernommen, ohne pro Tick
	# neu zu rechnen.
	_modifikatoren.bereich_setzen("bewegung")
	_modifikatoren.aktualisieren()
	_modifikatoren.aktualisiert.connect(bewegungswerte_uebernehmen)
	bewegungswerte_uebernehmen()

func ziel() -> Vector2:
	return _geh_ziel

func ziel_setzen(neues_ziel: Vector2) -> void:
	# Jeder Zielwechsel verwirft die alte Route: Ohne Wegpunkte läuft die
	# Einheit geradeaus, es bleibt nie ein Altweg stehen.
	_geh_ziel = neues_ziel
	wegpunkte_loeschen()

func wegpunkte_uebernehmen(punkte: PackedVector2Array) -> void:
	_weg_ziele = punkte
	_weg_index = 0

func wegpunkte_loeschen() -> void:
	_weg_ziele = PackedVector2Array()
	_weg_index = 0

func reichweite() -> float:
	return _reichweite

func rasse_faktor() -> float:
	return _rasse_faktor

func tempo() -> float:
	return _tempo

func am_ziel(ist_position: Vector2) -> bool:
	var abstand := ist_position.distance_to(_geh_ziel)
	return abstand <= _reichweite or abstand <= 0.001

func rasse_faktor_setzen(faktor: float) -> void:
	# Rassen-Multiplikator aus dem Schema des Need-Baums; er wirkt ab dem
	# nächsten Tick, ohne die Modifikator-Maschine neu zu rechnen.
	_rasse_faktor = maxf(faktor, 0.1)

func bewegungswerte_uebernehmen() -> void:
	# Zentrale Basis mal Modifikator-Faktor mal Rassen-Multiplikator.
	_tempo = _modifikatoren.geschwindigkeit_berechnen(
		_modifikatoren.basis_wert("basis_geschwindigkeit", 70.0)) * _rasse_faktor
	_reichweite = _modifikatoren.basis_wert("basis_reichweite", 24.0)

func wegpunkte_ablaufen(ist_position: Vector2) -> void:
	# Erreichte Wegpunkte fallen weg, bis der nächste außerhalb der
	# Reichweite liegt; ohne Wegpunkte bleibt der Index auf null.
	while _weg_index < _weg_ziele.size():
		if (_weg_ziele[_weg_index] - ist_position).length() > _reichweite:
			break
		_weg_index += 1

func richtung(ist_position: Vector2) -> Vector2:
	# Der nächste Wegpunkt führt, sonst das Endziel; ohne Planung geradeaus.
	var richtung := _geh_ziel - ist_position
	if _weg_index < _weg_ziele.size():
		richtung = _weg_ziele[_weg_index] - ist_position
		if richtung.length() <= 0.001:
			_weg_index += 1
			richtung = _geh_ziel - ist_position
	return richtung.normalized()
