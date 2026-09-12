extends RefCounted
class_name Tier_VitalStatus
## Trefferpunkte eines Tieres als reine Rechnung: Schaden aufnehmen, Treffer am
## Signalbus melden und melden, ob der Schlag tödlich war. Den Zustandswechsel
## löst der Besitzer aus, nicht diese Klasse.


static func schaden_nehmen(hp: int, schaden: int, welt_position: Vector2) -> Dictionary:
	## Nimmt Schaden von den Trefferpunkten und meldet das Ergebnis als Daten.
	if hp <= 0:
		return {"hp": hp, "verbraucht": 0, "gestorben": false}
	var verbraucht := mini(schaden, hp)
	var rest := hp - verbraucht
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_schaden(welt_position, verbraucht, "physisch")
	return {"hp": rest, "verbraucht": verbraucht, "gestorben": rest <= 0}
