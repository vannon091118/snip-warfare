extends RefCounted
## Tageszyklus: Takt/Tag/Nacht an der Weltuhr, Helligkeit und Canvas-Faerbung.
class_name Welt_TageszyklusMaschine
enum Phase { TAG, DAEMMERUNG, NACHT, MORGEN }
signal phase_geaendert(neue_phase: Phase, helligkeit: float)
## Kategorie daten: Takt-Konfiguration und Zustand.
var takt_minuten: float = 2.0
var tag_minuten: float = 1.5
var nacht_minuten: float = 0.5
var _tick_in_takt: int = 0
var _helligkeit: float = 1.0
var _phase: Phase = Phase.TAG
## Kategorie logik: Tick und Farbgebung.
var canvas_modulate: CanvasModulate = null

func einrichten(neu_takt_minuten: float = 2.0, neu_tag_minuten: float = 1.5, _neu_nacht_minuten: float = 0.5) -> void:
	takt_minuten = maxf(neu_takt_minuten, 1.0)
	tag_minuten = clampf(neu_tag_minuten, 0.5, takt_minuten - 0.5)
	nacht_minuten = takt_minuten - tag_minuten

func _takt_ticks_fuer(minuten: float) -> int:
	return Kern_Weltuhr.ticks_aus_minuten(minuten)

func tick(_uhr_tick_nummer: int = 0, _uhr_delta: float = 0.0) -> void:
	_tick_in_takt += 1
	var takt_ticks := _takt_ticks_fuer(takt_minuten)
	var tag_ticks := _takt_ticks_fuer(tag_minuten)
	var alt_phase := _phase
	var alt_hell := _helligkeit
	_phase = _phase_fuer(_tick_in_takt % maxi(takt_ticks, 1), tag_ticks, takt_ticks)
	_helligkeit = _helligkeit_fuer(_phase, _tick_in_takt % maxi(takt_ticks, 1), tag_ticks, takt_ticks)
	if _phase != alt_phase or absf(_helligkeit - alt_hell) > 0.01:
		phase_geaendert.emit(_phase, _helligkeit)
	tages_farbe_fuer_tick(_tick_in_takt)

func helligkeit() -> float:
	return _helligkeit

func phase() -> Phase:
	return _phase

func is_nacht() -> bool:
	return _phase == Phase.NACHT

func phase_name() -> String:
	## Der Phasenname in der Sprache der Faerbung.
	match _phase:
		Phase.DAEMMERUNG:
			return Welt_TagesZyklusFaerbung.DAEMMERUNG
		Phase.NACHT:
			return Welt_TagesZyklusFaerbung.NACHT
		Phase.MORGEN:
			return Welt_TagesZyklusFaerbung.MORGEN
	return Welt_TagesZyklusFaerbung.TAG

func schablonen_alpha() -> float:
	## Die Deckkraft der Nachtschablone ist Darstellung und liegt bei der Faerbung.
	return Welt_TagesZyklusFaerbung.schablonen_alpha(phase_name())

func faerbung() -> Color:
	## Die Grundtönung je Phase kommt ebenfalls aus der Faerbung.
	return Welt_TagesZyklusFaerbung.faerbung(phase_name())

func tages_farbe_fuer_tick(_aktueller_tick: int) -> void:
	## Der weiche Farbverlauf: Anteil im Tag bestimmen, Farbe malen lassen.
	if canvas_modulate == null:
		return
	var tag_ticks := maxi(Kern_Weltuhr.ticks_aus_minuten(tag_minuten), 1)
	var takt_ticks := maxi(Kern_Weltuhr.ticks_aus_minuten(takt_minuten), 1)
	var fortschritt := float(_tick_in_takt % tag_ticks) / float(takt_ticks)
	canvas_modulate.color = Welt_TagesZyklusFaerbung.tages_farbe(phase_name(), fortschritt)

func daten_fuer_speichern() -> Dictionary:
	## Das Format kennt die eigene Speicher-Klasse, nicht diese Maschine.
	return Welt_TagesZyklusSpeicher.sichern(_tick_in_takt, _helligkeit, int(_phase))

func aus_daten_laden(daten: Dictionary) -> void:
	var gelesen := Welt_TagesZyklusSpeicher.laden(daten)
	_tick_in_takt = gelesen["tick_in_takt"]
	_helligkeit = gelesen["helligkeit"]
	_phase = gelesen["phase"] as Phase

func _phase_fuer(tick_im_takt: int, tag_ticks: int, takt_ticks: int) -> Phase:
	var daemmer := int(takt_ticks * 0.08)
	var morgen := int(takt_ticks * 0.08)
	if tick_im_takt < tag_ticks - daemmer:
		return Phase.TAG
	if tick_im_takt < tag_ticks:
		return Phase.DAEMMERUNG
	if tick_im_takt < takt_ticks - morgen:
		return Phase.NACHT
	return Phase.MORGEN

func _helligkeit_fuer(aktuelle_phase: Phase, tick_im_takt: int, tag_ticks: int, takt_ticks: int) -> float:
	match aktuelle_phase:
		Phase.TAG:
			return 1.0
		Phase.DAEMMERUNG:
			var p := float(tick_im_takt - (tag_ticks - int(takt_ticks * 0.08))) / float(maxi(int(takt_ticks * 0.08), 1))
			return lerpf(1.0, 0.45, clampf(p, 0.0, 1.0))
		Phase.NACHT:
			return 0.45
		Phase.MORGEN:
			var p2 := float(tick_im_takt - (takt_ticks - int(takt_ticks * 0.08))) / float(maxi(int(takt_ticks * 0.08), 1))
			return lerpf(0.45, 1.0, clampf(p2, 0.0, 1.0))
	return 1.0
