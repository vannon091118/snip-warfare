extends RefCounted
class_name Tier_Status
## Zustandsmaschine eines Tieres: Ruhe, Aufgeschreckt, Wegfliegen, Verfolgen.
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
	# Modifikator skaliert Geschwindigkeit: Faktor 1.2 bedeutet 20 Prozent schneller.
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

func schaden_nehmen(schaden: int) -> int:
	# Zieht Lebenspunkte ab und gibt die tatsächlich verbrauchte Menge zurück.
	if zustand == Zustand.TOT:
		return 0
	var verbraucht := mini(schaden, hp)
	hp -= verbraucht
	if hp <= 0:
		_zu_zustand_wechseln(Zustand.TOT)
	return verbraucht

func _zu_zustand_wechseln(neuer_zustand: Zustand) -> void:
	if zustand == neuer_zustand:
		return
	zustand = neuer_zustand
	tick_in_zustand = 0
	steigt = false
	zustand_geaendert.emit(neuer_zustand)

func ticks_fuer_faktor() -> int:
	return Kern_Weltuhr.ticks_aus_faktor(effektiver_faktor())

func tick(delta: float, eigene_position: Vector2, spieler_position: Vector2) -> Vector2:
	# Liefert die Bewegung dieses Ticks; der Aufrufer schreibt die Position.
	# Trigger wird rein aus Registry gelesen: ausloeser bestimmt den Folgezustand.
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
			# Tote Tiere warten auf das Ernten; sie bewegen sich nicht mehr.
			bewegung = Vector2.ZERO
		Zustand.AUFGESCHRECKT:
			# Der Hase hoppelt kurz auf, dann setzt die reguläre Flucht ein.
			bewegung = flucht_richtung * speed_aktuell() * delta
			if tick_in_zustand > 8:
				_zu_zustand_wechseln(Zustand.WEGFLIEGEN)
		Zustand.WEGFLIEGEN:
			# Vögel steigen während der ersten Ticks schräg nach oben und
			# blenden danach aus; der Hase läuft am Boden weiter.
			if ist_vogel():
				var steig_anteil := int(verhalten.wert(tier_id, "steig_anteil_ticks", 40))
				steigt = tick_in_zustand <= steig_anteil
			bewegung = flucht_richtung * speed_aktuell() * delta
		Zustand.VERFOLGEN:
			# Der Bär geht direkt auf die Spielereinheit zu.
			ziel_position = spieler_position
			var abstand := verhalten.wert(tier_id, "aufhalte_abstand", 120.0)
			var differenz := spieler_position - eigene_position
			if differenz.length() > abstand:
				bewegung = differenz.normalized() * speed_aktuell() * delta
	return bewegung
