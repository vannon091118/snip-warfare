extends RefCounted
class_name Kern_Timeline
## Zustands-Timeline: Der Ursprungs-Snapshot plus alle Mutationen ueber die
## Zeit als Delta-Eintraege. Jeder Zustand ist damit jederzeit rekonstruierbar
## und die Frage warum ist das so bleibt intern wie fuer den Spieler
## beantwortbar. Diese Klasse besitzt keine Zeit, keinen Zufall und keine
## Simulationslogik; sie protokolliert nur, was andere Zustaendigkeiten melden.
##
## Rekonstruktion: Ursprungs-Snapshot plus alle Eintraege bis zu einem Tick
## ergibt den exakten Zustand zu diesem Zeitpunkt, unabhaengig davon, wie
## viele Mutationen dazwischen lagen. Kein Dump, nur Deltas.

signal eintrag_neu(eintrag: Kern_TimelineEintrag)

## Kategorie daten: Ursprung und die Eintraege in fester Reihenfolge.
var ursprungs_snapshot: Dictionary = {}
var eintraege: Array[Kern_TimelineEintrag] = []

## Kategorie logik: Ursprung festlegen, Eintraege anhaengen, rekonstruieren.

func ursprung_festlegen(snapshot: Dictionary) -> void:
	# Der Ursprung ist die Wahrheit vor allen Mutationen; wird er neu gesetzt,
	# beginnt die Timeline sauber bei null.
	ursprungs_snapshot = snapshot.duplicate(true)
	eintraege.clear()

func eintrag_anhaengen(tick: int, ziel_id: String, quelle: String, beschreibung: String,
		alter_zustand: Dictionary, neuer_zustand: Dictionary,
		modifikator_id: String = "", faktor: float = 1.0) -> Kern_TimelineEintrag:
	var eintrag := Kern_TimelineEintrag.new()
	eintrag.einrichten(tick, ziel_id, quelle, beschreibung, alter_zustand, neuer_zustand,
		modifikator_id, faktor)
	eintraege.append(eintrag)
	eintrag_neu.emit(eintrag)
	return eintrag

func zustand_zu_tick(tick: int) -> Dictionary:
	# Rekonstruktion des Zustands zu einem beliebigen Zeitpunkt: Der Ursprung
	# wird genommen und alle Eintraege bis einschliesslich tick werden als
	# Delta angewendet. Die Reihenfolge der Eintraege ist die Zeitachse.
	var zustand := ursprungs_snapshot.duplicate(true)
	for eintrag: Kern_TimelineEintrag in eintraege:
		if eintrag.tick > tick:
			break
		for schluessel: String in eintrag.nachher.keys():
			zustand[schluessel] = eintrag.nachher[schluessel]
	return zustand

func warum(ziel_id: String) -> Array[Kern_TimelineEintrag]:
	# Die Begruendungskette eines Ziels: alle Eintraege, die dieses Ziel
	# beruehrt haben, in zeitlicher Reihenfolge. Damit ist die Frage warum
	# ist das so jederzeit beantwortbar.
	var kette: Array[Kern_TimelineEintrag] = []
	for eintrag: Kern_TimelineEintrag in eintraege:
		if eintrag.ziel_id == ziel_id:
			kette.append(eintrag)
	return kette

func einfluss_modifikatoren() -> Dictionary:
	# Aggregiert, welche Modifikatoren wie oft und mit welchem Faktor gewirkt
	# haben: modifikator_id -> Anzahl der Eintraege. Damit wird der Einfluss
	# aller im Spiel verfuegbaren Modifikatoren sichtbar und vergleichbar.
	var einfluss := {}
	for eintrag: Kern_TimelineEintrag in eintraege:
		if eintrag.modifikator_id == "":
			continue
		var wert: Dictionary = einfluss.get(eintrag.modifikator_id, {"anzahl": 0, "faktoren": []})
		wert["anzahl"] = int(wert["anzahl"]) + 1
		wert["faktoren"].append(eintrag.faktor)
		einfluss[eintrag.modifikator_id] = wert
	return einfluss

func letzte_eintraege(anzahl: int) -> Array[Kern_TimelineEintrag]:
	# Die juengsten Eintraege fuer Beobachter (HUD, Debug), ohne den Rest
	# der Timeline anzufassen.
	var start := maxi(0, eintraege.size() - anzahl)
	return eintraege.slice(start)