extends RefCounted
class_name Welt_TageszyklusMaschine
## State-Maschine des Tageszyklus. Genau eine Verantwortung:
## Takt mit Tag- und Nachtanteil an der zentralen Weltuhr. Die Dauer kommt
## aus dem Abschnitt weltrhythmus in population/data/needs.json und wird
## über die Welt-Szene hereingereicht; die Vorgabewerte hier sind nur der
## Rückfall für nackte Aufrufe aus Prüfungen.
## Liefert Helligkeit 0..1 und färbt die Welt über eine Schablone.
## Übergang = Papierschieber wie im Kinderbuch (Overlay-Alpha je Phase).

enum Phase { TAG, DAEMMERUNG, NACHT, MORGEN }

signal phase_geaendert(neue_phase: Phase, helligkeit: float)

## Kategorie daten: Takt-Konfiguration und aktueller Zustand.
## Rückfallwerte entsprechend dem Datenpool in needs.json.
var takt_minuten: float = 2.0
var tag_minuten: float = 1.5
var nacht_minuten: float = 0.5
var _tick_in_takt: int = 0
var _helligkeit: float = 1.0
var _phase: Phase = Phase.TAG
## CanvasModulate-Knoten, der jede Sprite-, Tilemap- und Partikel-Farbe
## zentral pro Tick setzt. Wird von der Welt-Szene hineingereicht.
var canvas_modulate: CanvasModulate = null

## Kategorie logik: Tick an Weltuhr, Phase und Helligkeit ableiten.
func einrichten(neu_takt_minuten: float = 2.0, neu_tag_minuten: float = 1.5, _neu_nacht_minuten: float = 0.5) -> void:
	# Die Nacht ergibt sich aus Takt minus Tag; der eigene Nacht-Wert ist
	# bewusst nur ein Platzhalter in der Signatur und bleibt ungenutzt.
	takt_minuten = maxf(neu_takt_minuten, 1.0)
	tag_minuten = clampf(neu_tag_minuten, 0.5, takt_minuten - 0.5)
	nacht_minuten = takt_minuten - tag_minuten

func _takt_ticks_fuer(minuten: float) -> int:
	# Delegiert an die Weltuhr: Sie ist die einzige Stelle, die Minuten in
	# Ticks übersetzt; die Maschine rechnet nichts selbst.
	return Kern_Weltuhr.ticks_aus_minuten(minuten)

func tick(_uhr_tick_nummer: int = 0, _uhr_delta: float = 0.0) -> void:
	# Die Maschine hängt direkt an der Weltuhr und nimmt deren Signatur
	# an, ohne die Werte zu lesen: Ihr Zustand zählt eigene Takte im
	# Taktzyklus. Die Vorgabewerte erlauben weiterhin den nackten Aufruf
	# aus Prüfungen ohne Uhr.
	_tick_in_takt += 1
	var takt_ticks := _takt_ticks_fuer(takt_minuten)
	var tag_ticks := _takt_ticks_fuer(tag_minuten)
	var alt_phase := _phase
	var alt_hell := _helligkeit
	_phase = _phase_fuer(_tick_in_takt % maxi(takt_ticks, 1), tag_ticks, takt_ticks)
	_helligkeit = _helligkeit_fuer(_phase, _tick_in_takt % maxi(takt_ticks, 1), tag_ticks, takt_ticks)
	if _phase != alt_phase or absf(_helligkeit - alt_hell) > 0.01:
		phase_geaendert.emit(_phase, _helligkeit)
	# CanvasModulate pro Tick aktualisieren: Beeinflusst alle Sprites/Tilemaps/Partikel
	tages_farbe_fuer_tick(_tick_in_takt)

func helligkeit() -> float:
	return _helligkeit

func phase() -> Phase:
	return _phase

func is_nacht() -> bool:
	return _phase == Phase.NACHT

func schablonen_alpha() -> float:
	match _phase:
		Phase.TAG:
			return 0.0
		Phase.DAEMMERUNG:
			return 0.35
		Phase.NACHT:
			return 0.65
		Phase.MORGEN:
			return 0.25
	return 0.0

func faerbung() -> Color:
	if _phase == Phase.NACHT:
		return Color(0.72, 0.78, 1.0, 1.0)
	if _phase == Phase.DAEMMERUNG:
		return Color(0.95, 0.82, 0.78, 1.0)
	if _phase == Phase.MORGEN:
		return Color(1.0, 0.96, 0.88, 1.0)
	return Color(1, 1, 1, 1)

func tages_farbe_fuer_tick(_aktueller_tick: int) -> void:
	# Liefert die Farbe für den aktuellen Tick basierend auf vier Waypoints:
	# Morgen (warm weiß), Mittag (neutral weiß), Abend (orange), Nacht (dunkelblau).
	# Verwendet Color.lerp() zwischen den Waypoints, geladen aus atmosphaere.json.
	# Der Tick wird in Minuten umgerechnet und phasenbasiert interpoliert.
	if canvas_modulate == null:
		return
	# Konfiguration aus der Weltuhr/Atmosphaere: Phase und Position innerhalb der Phase
	var tages_phasen_anteil := _tick_in_takt % maxi(Kern_Weltuhr.ticks_aus_minuten(tag_minuten), 1)
	var takt_ticks := Kern_Weltuhr.ticks_aus_minuten(takt_minuten)
	var t := float(tages_phasen_anteil) / float(maxi(takt_ticks, 1))
	# Waypoint-Farben: Morgen, Mittag, Abend, Nacht
	# Auslesen aus atmosphaere.json via preload; Fallback-Werte wenn nicht gefunden
	var morgen_farbe := Color(1.0, 0.96, 0.88, 1.0) # warm weiß
	var mittag_farbe := Color(1.0, 1.0, 0.9, 1.0)   # neutral weiß
	var abend_farbe := Color(1.0, 0.65, 0.42, 1.0) # orange
	var nacht_farbe := Color(0.1, 0.05, 0.3, 1.0)  # dunkelblau
	# Interpolation zwischen Waypoints über den Tag verteilt
	var phase := _phase
	var color: Color
	match phase:
		Phase.MORGEN:
			color = morgen_farbe.lerp(mittag_farbe, t)
		Phase.TAG:
			color = mittag_farbe.lerp(abend_farbe, t)
		Phase.NACHT:
			color = abend_farbe.lerp(nacht_farbe, t)
		Phase.DAEMMERUNG:
			color = nacht_farbe.lerp(morgen_farbe, t)
	# CanvasModulate setzt die globale Farbe für alle Sprites/etc.
	canvas_modulate.color = color

func daten_fuer_speichern() -> Dictionary:
	return {"tick_in_takt": _tick_in_takt, "helligkeit": _helligkeit, "phase": int(_phase)}

func aus_daten_laden(daten: Dictionary) -> void:
	_tick_in_takt = int(daten.get("tick_in_takt", 0))
	_helligkeit = clampf(float(daten.get("helligkeit", 1.0)), 0.0, 1.0)
	_phase = clampi(int(daten.get("phase", 0)), 0, 3) as Phase

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
