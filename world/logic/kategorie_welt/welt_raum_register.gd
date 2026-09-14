extends RefCounted
class_name Welt_RaumRegister
## Einzige Tick-Stelle der Raumerkennung auf dem Weltzustand.
## Sie läuft an der Weltuhr (24 Hz), erkennt geschlossene Räume aus
## Welt_Model und meldet neue Räume als echte Welt-Ereignisse über den
## Kern_SignalBus. Sie schreibt die Raum-Menge und die letzte gültige
## Raum-ID ins Modell, damit Persistenz und Progressionsmaschine dieselbe
## Wahrheit lesen. Keine Bau-, keine Lagerrechnung: nur Erkennen und Melden.
##
## Verantwortlichkeit: Raumerkennung und Raumzustand.

const MODELL_SCHLUESSEL_RAEUME := "welt_raeume"
const MODELL_SCHLUESSEL_LETZTER_GUELTIGER := "welt_letzter_gueltiger_raum"

var _model: Welt_Model = null
var _erkenner := Welt_RaumErkenner.new()
var _letzter_bestand: Dictionary = {}
var _tick_schritt: int = 0

func einrichten(model: Welt_Model) -> void:
	_model = model
	_letzter_bestand.clear()

func model_setzen(model: Welt_Model) -> void:
	_model = model
	_letzter_bestand.clear()

func erfolgter_raum() -> Welt_Raum:
	if _model == null:
		return null
	var verfuegbar := verfuegbare_raeume()
	for raum in verfuegbar:
		if raum.innen_flaeche >= 16 and raum.breite >= 4 and raum.hoehe >= 4 and raum.hat_tuer and raum.geschlossen:
			return raum
	return null

func verfuegbare_raeume() -> Array[Welt_Raum]:
	return _erkenner.raeume_erkennen(_model)

func tick() -> void:
	if _model == null:
		return
	_tick_schritt += 1
	# Alle 12 Ticks (0,5 s) reicht für Wände; jeder Tick würde die 32x24-
	# Kachelkarte sinnlos rechenen lassen.
	if _tick_schritt % 12 != 0:
		return
	var raeume := _erkenner.raeume_erkennen(_model)
	var gueltige := 0
	for raum in raeume:
		if raum.innen_flaeche >= 16 and raum.breite >= 4 and raum.hoehe >= 4 and raum.hat_tuer and raum.geschlossen:
			gueltige += 1
			if not _letzter_bestand.has(raum.id):
				_raum_melden(raum)
	_model.objekt_feld_setzen(0, MODELL_SCHLUESSEL_RAEUME, str(raeume.size()))
	_model.objekt_feld_setzen(0, MODELL_SCHLUESSEL_LETZTER_GUELTIGER, gueltige)
	var neuer_bestand: Dictionary = {}
	for raum in raeume:
		neuer_bestand[raum.id] = true
	_letzter_bestand = neuer_bestand
	# Raum-Register selbst schreibt nur die transienten Zähler; die echten
	# Räume werden am Bus gemeldet und von der Progressionsmaschine persistiert.
	# Welt_Model.nach_woerterbuch kopiert alle Zusatzfelder automatisch.

func _raum_melden(raum: Welt_Raum) -> void:
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_raum_entstanden(raum.id, raum.innen_flaeche, raum.hat_tuer, raum.geschlossen)
