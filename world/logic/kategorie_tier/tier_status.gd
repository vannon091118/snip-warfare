extends RefCounted
class_name Tier_Status
## Zustandsmaschine eines Tieres: Ruhe, Aufgeschreckt, Wegfliegen, Verfolgen, Tot.
## Reagiert ausschließlich auf den globalen Tick und auf Trigger-Ereignisse;
## Darstellung macht der Tier_Darsteller, Daten kommen aus den Tier-Klassen.

enum Zustand {
	RUHE,
	AUFGESCHRECKT,
	WEGFLIEGEN,
	VERFOLGEN,
	TOT,
}

signal zustand_geaendert(neuer_zustand: Zustand)

var tier_id: String
var verhalten: Tier_Registry
var zustand: Zustand = Zustand.RUHE
var tick_in_zustand: int = 0
var flucht_richtung := Vector2.RIGHT
var ziel_position := Vector2.ZERO
var steigt: bool = false
var hp: int = 1
var fleisch: int = 1
var _faktor: float = 1.0
var _modifikator_id: String = "normal"
var _logik_id: String = ""
var _welt_position: Vector2 = Vector2.ZERO

func _init(tier: String, verhaltens_daten: Tier_Registry) -> void:
	tier_id = tier
	verhalten = verhaltens_daten
	hp = verhalten.hp(tier)
	fleisch = verhalten.fleisch(tier)
	var daten := verhalten.tier_daten(tier)
	if daten != null:
		_faktor = daten.faktor
		_modifikator_id = daten.modifikator_id
		_logik_id = daten.logik_id

func ist_vogel() -> bool:
	var daten := verhalten.tier_daten(tier_id)
	if daten == null:
		return false
	return daten.ausloeser == "wegfliegen" or daten.logik_id.begins_with("vogel")

func trigger_radius() -> float:
	return verhalten.wert(tier_id, "trigger_radius", 400.0)

func effektiver_faktor() -> float:
	return clampf(_faktor, 0.1, 10.0)

func logik_id() -> String:
	return _logik_id

func modifikator_id() -> String:
	return _modifikator_id

func speed_aktuell() -> float:
	var basis := 0.0
	match zustand:
		Zustand.AUFGESCHRECKT:
			basis = verhalten.wert(tier_id, "flucht_geschwindigkeit", 400.0)
		Zustand.WEGFLIEGEN:
			basis = verhalten.wert(tier_id, "flug_geschwindigkeit", 280.0)
		Zustand.VERFOLGEN:
			basis = verhalten.wert(tier_id, "gehe_geschwindigkeit", 150.0)
	if basis == 0.0:
		return 0.0
	return basis * effektiver_faktor()

func schrecken(richtung: Vector2, ziel: Vector2) -> void:
	if zustand == Zustand.WEGFLIEGEN or zustand == Zustand.VERFOLGEN:
		return
	flucht_richtung = richtung.normalized()
	ziel_position = ziel
	_zu_zustand_wechseln(Zustand.AUFGESCHRECKT)

func ist_tot() -> bool:
	return zustand == Zustand.TOT

func welt_position_setzen(pos: Vector2) -> void:
	_welt_position = pos

func schaden_nehmen(schaden: int) -> int:
	if zustand == Zustand.TOT:
		return 0
	var verbraucht := mini(schaden, hp)
	hp -= verbraucht
	var b := Kern_SignalBus.bus()
	if b != null:
		b.schaden_erhalten.emit(_welt_position, verbraucht, "physisch")
	if hp <= 0:
		_zu_zustand_wechseln(Zustand.TOT)
	return verbraucht

func _zu_zustand_wechseln(neuer_zustand: Zustand) -> void:
	if zustand == neuer_zustand:
		return
	var alter_zustand := zustand
	zustand = neuer_zustand
	tick_in_zustand = 0
	steigt = false
	zustand_geaendert.emit(neuer_zustand)
	if neuer_zustand == Zustand.TOT and alter_zustand != Zustand.TOT:
		var b2 := Kern_SignalBus.bus()
		if b2 != null:
			b2.gestorben.emit(_welt_position, tier_id, false)

func ticks_fuer_faktor() -> int:
	return Kern_Weltuhr.ticks_aus_faktor(effektiver_faktor())
	# Hinweis: Nur Weltuhr rechnet zentral; diese Methode delegiert ausschliesslich.

func tick(delta: float, eigene_position: Vector2, spieler_position: Vector2) -> Vector2:
	_welt_position = eigene_position
	tick_in_zustand += 1
	var bewegung := Vector2.ZERO
	match zustand:
		Zustand.RUHE:
			if spieler_position.distance_to(eigene_position) <= trigger_radius():
				var daten := verhalten.tier_daten(tier_id)
				var ausloeser := "" if daten == null else daten.ausloeser
				match ausloeser:
					"verfolgen":
						ziel_position = spieler_position
						_zu_zustand_wechseln(Zustand.VERFOLGEN)
					_:
						flucht_richtung = (eigene_position - spieler_position).normalized()
						ziel_position = spieler_position
						_zu_zustand_wechseln(Zustand.WEGFLIEGEN)
		Zustand.TOT:
			bewegung = Vector2.ZERO
		Zustand.AUFGESCHRECKT:
			bewegung = flucht_richtung * speed_aktuell() * delta
			if tick_in_zustand > 8:
				_zu_zustand_wechseln(Zustand.WEGFLIEGEN)
		Zustand.WEGFLIEGEN:
			if ist_vogel():
				var steig_anteil := int(verhalten.wert(tier_id, "steig_anteil_ticks", 40))
				steigt = tick_in_zustand <= steig_anteil
			bewegung = flucht_richtung * speed_aktuell() * delta
		Zustand.VERFOLGEN:
			ziel_position = spieler_position
			var abstand := verhalten.wert(tier_id, "aufhalte_abstand", 120.0)
			var differenz := spieler_position - eigene_position
			if differenz.length() > abstand:
				bewegung = differenz.normalized() * speed_aktuell() * delta
	return bewegung