extends RefCounted
class_name Tier_Status
## Ruhe, Aufgeschreckt, Wegfliegen, Verfolgen, Tot.

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
## Kategorie daten: lebender Zustand der Instanz.
var _welt_position: Vector2 = Vector2.ZERO
## Kategorie logik: Zustand, Uebergaenge und Tick liegen bei der Verhaltens-Maschine.
var verhaltens_maschine := Tier_VerhaltenMaschine.new()

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
	verhaltens_maschine.einrichten(self)

func ist_vogel() -> bool:
	## Die Sichtung weiss, woran man einen Vogel erkennt.
	return Tier_Sichtung.ist_vogel(verhalten, tier_id)

func trigger_radius() -> float:
	## Die Sichtweite kommt aus den Tierdaten, der Standard aus der Sichtung.
	return verhalten.wert(tier_id, "trigger_radius", Tier_Sichtung.STANDARD_TRIGGER)

func effektiver_faktor() -> float:
	return clampf(_faktor, 0.1, 10.0)

func logik_id() -> String:
	return _logik_id

func modifikator_id() -> String:
	return _modifikator_id

func speed_aktuell() -> float:
	## Das Tempo haengt am Zustand und gehoert deshalb zur Verhaltens-Maschine.
	return verhaltens_maschine.tempo()

func schrecken(richtung: Vector2, ziel: Vector2) -> void:
	## Ein Schreck ist ein Verhaltensfall, kein Datenfall.
	verhaltens_maschine.schrecken(richtung, ziel)

func zustand_name() -> String:
	## Der Zustand als Name, damit die Verhaltens-Maschine das Enum nicht kennt.
	return Tier_ZustandsNamen.name_fuer(int(zustand))

func wechsle_zu(zustands_name: String) -> void:
	## Der Gegenweg: Ein Name wird wieder ein Zustand.
	zustand_wechseln(Tier_ZustandsNamen.wert_fuer(zustands_name) as Zustand)

func ist_tot() -> bool:
	return zustand == Zustand.TOT

func welt_position_setzen(pos: Vector2) -> void:
	_welt_position = pos

func schaden_nehmen(schaden: int) -> int:
	## Die Rechnung fuehrt die Vitalklasse; den Todesfall entscheidet der Status.
	var ergebnis := Tier_VitalStatus.schaden_nehmen(hp, schaden, _welt_position)
	hp = ergebnis["hp"]
	if ergebnis["gestorben"]:
		zustand_wechseln(Zustand.TOT)
	return ergebnis["verbraucht"]

func zustand_wechseln(neuer_zustand: Zustand) -> void:
	## Der einzige Weg in einen neuen Zustand: Er setzt Zaehler und Signal.
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
			b2._emit_gestorben(_welt_position, tier_id, false)

func ticks_fuer_faktor() -> int:
	return Kern_Weltuhr.ticks_aus_faktor(effektiver_faktor())

func tick(delta: float, eigene_position: Vector2, spieler_position: Vector2) -> Vector2:
	## Der Status reicht den Takt an seine Verhaltens-Maschine weiter.
	return verhaltens_maschine.tick(delta, eigene_position, spieler_position)
