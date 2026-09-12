extends RefCounted
class_name Tier_VerhaltenMaschine
## Verhalten eines Tieres: Es waehlt aus Zustand und Umgebung den naechsten
## Schritt, kennt die Uebergaenge (Ruhe zu Verfolgen oder Wegfliegen, Aufgeschreckt
## zu Wegfliegen) und liefert die Bewegung. Den Zustand selbst haelt der
## Tier_Status; die Maschine spricht ihn ueber Namen an und bleibt damit frei
## von seinem Enum.

# Die Namen kommen aus der einen Quelle; hier sind es nur kurze Griffe.
const RUHE := Tier_ZustandsNamen.RUHE
const AUFGESCHRECKT := Tier_ZustandsNamen.AUFGESCHRECKT
const WEGFLIEGEN := Tier_ZustandsNamen.WEGFLIEGEN
const VERFOLGEN := Tier_ZustandsNamen.VERFOLGEN
const TOT := Tier_ZustandsNamen.TOT


var status: Tier_Status = null


func einrichten(tier_status: Tier_Status) -> void:
	## Bindet die Maschine an den Status, den sie fuehren soll.
	status = tier_status


func tempo() -> float:
	## Das Tempo des aktuellen Zustands, skaliert mit dem Modifikatorfaktor.
	if status == null:
		return 0.0
	var art := tempo_art()
	if art == "":
		return 0.0
	return Tier_TempoBerechnung.aktuell(status.verhalten, status.tier_id, art, status.effektiver_faktor())


func tempo_art() -> String:
	## Welches Datenfeld das Tempo traegt, entscheidet der Zustand.
	if status == null:
		return ""
	match status.zustand_name():
		AUFGESCHRECKT:
			return Tier_TempoBerechnung.FLUCHT_ART
		WEGFLIEGEN:
			return Tier_TempoBerechnung.FLUG_ART
		VERFOLGEN:
			return Tier_TempoBerechnung.GEH_ART
	return ""


func schrecken(richtung: Vector2, ziel: Vector2) -> void:
	## Ein Schreck weckt nur, was noch nicht flieht und nicht jagt.
	if status == null:
		return
	if status.zustand_name() == WEGFLIEGEN or status.zustand_name() == VERFOLGEN:
		return
	status.flucht_richtung = richtung.normalized()
	status.ziel_position = ziel
	status.wechsle_zu(AUFGESCHRECKT)


func tick(delta: float, eigene_position: Vector2, spieler_position: Vector2) -> Vector2:
	## Ein Takt im Leben des Tieres: Zustand lesen, handeln, Weg zurueckgeben.
	if status == null:
		return Vector2.ZERO
	status.welt_position_setzen(eigene_position)
	status.tick_in_zustand += 1
	match status.zustand_name():
		RUHE:
			return _tick_ruhe(eigene_position, spieler_position)
		TOT:
			return Vector2.ZERO
		AUFGESCHRECKT:
			return _tick_aufgeschreckt(delta)
		WEGFLIEGEN:
			return _tick_wegfliegen(delta)
		VERFOLGEN:
			return _tick_verfolgen(delta, eigene_position, spieler_position)
	return Vector2.ZERO


func _tick_ruhe(eigene_position: Vector2, spieler_position: Vector2) -> Vector2:
	## In Ruhe entscheidet der Ausloeser, ob gejagt oder geflohnen wird.
	if not Tier_Sichtung.nah_genug(status.verhalten, status.tier_id, eigene_position, spieler_position):
		return Vector2.ZERO
	status.ziel_position = spieler_position
	if Tier_Sichtung.verfolgt(status.verhalten, status.tier_id):
		status.wechsle_zu(VERFOLGEN)
		return Vector2.ZERO
	status.flucht_richtung = (eigene_position - spieler_position).normalized()
	status.wechsle_zu(WEGFLIEGEN)
	return Vector2.ZERO


func _tick_aufgeschreckt(delta: float) -> Vector2:
	## Nach kurzem Schreck geht es ins Wegfliegen ueber.
	var bewegung := status.flucht_richtung * tempo() * delta
	if status.tick_in_zustand > Tier_Sichtung.SCHRECK_TICKS:
		status.wechsle_zu(WEGFLIEGEN)
	return bewegung


func _tick_wegfliegen(delta: float) -> Vector2:
	## Voegel steigen zuerst, alle anderen laufen gleich weg.
	status.steigt = Tier_Sichtung.steigt_jetzt(status.verhalten, status.tier_id, status.tick_in_zustand)
	return status.flucht_richtung * tempo() * delta


func _tick_verfolgen(delta: float, eigene_position: Vector2, spieler_position: Vector2) -> Vector2:
	## Beim Verfolgen wird nur nachgerueckt, solange der Abstand zu gross ist.
	status.ziel_position = spieler_position
	var abstand := Tier_Sichtung.aufhalte_abstand(status.verhalten, status.tier_id)
	var differenz := spieler_position - eigene_position
	if differenz.length() > abstand:
		return differenz.normalized() * tempo() * delta
	return Vector2.ZERO
