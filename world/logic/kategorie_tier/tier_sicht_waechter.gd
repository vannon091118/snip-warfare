extends RefCounted
class_name Tier_SichtWaechter
## Blick-Wächter der Tier-Domäne: Er entscheidet, welche Tiere gerade einen
## Darsteller tragen. Im Kamera-Blick erwachen sie budgetiert, außerhalb
## schlafen sie als reiner Logik-Eintrag ohne Node. Ohne gesetzten Bereich
## (Editor, Prüfläufe) gilt alles als sichtbar. Die Positionen und Ticks
## bleiben beim Tier_Manager; der Wächter führt nur das Wach-Sein.

## Deckel für Aufweckungen je Takt, damit ein Ruck nie den ganzen Takt frisst.
const MAX_AUFWECKUNGEN_PRO_TICK := 32
## Deckel für Aufweckungen je Bild: Die Weltuhr kann mehrere Ticks in einem
## Rahmen nachholen, und FPS ist ein Bild-Phänomen. Ohne diesen Deckel
## würden fünf nachgeholte Ticks das Fünffache in dem einen Bild wecken,
## das der Spieler gerade sieht — genau das Bild, das nicht kippen darf.
const MAX_AUFWECKUNGEN_PRO_BILD := 48

var _sammler := Welt_SichtbereichSammler.new()
var _letzter_rahmen: int = -1
var _aufweckungen_je_rahmen: int = 0

func bereich_setzen(rechteck: Rect2) -> void:
	## Die Szene reicht das Kamera-Rechteck herein; der Abgleich läuft
	## budgetiert im Tick, nicht je Ruf.
	_sammler.bereich_setzen(rechteck)

func deaktivieren() -> void:
	## Ohne Blick (Editor, Prüflauf, Speicher-Rückweg) gilt alles als sichtbar.
	_sammler.deaktivieren()

func enthaelt(punkt: Vector2) -> bool:
	## Ohne aktiven Blick ist jeder Platzierungsort sichtbar.
	if not _sammler.ist_aktiv():
		return true
	return _sammler.enthaelt(punkt)

func alles_aufwecken(tiere: Array[Dictionary], darsteller_erzeugen: Callable) -> void:
	## Editor- und Prüfrückweg: Jedes schlafende Tier bekommt sofort seinen
	## Darsteller, damit kein Suchender ins Leere greift.
	for tier: Dictionary in tiere:
		if tier.get("darsteller") == null:
			tier["darsteller"] = darsteller_erzeugen.call(str(tier["tier_id"]), tier["status"], tier["position"])

func wachen_und_schlafen(tiere: Array[Dictionary], darsteller_erzeugen: Callable) -> Array[int]:
	## Ein Abgleich je Takt: Schlafende im Blick erwachen (budgetiert), wache
	## außerhalb schlafen ein. Vögel mit fertigem Abflug und Tiere in der
	## Ernte-Ausblendung enden logisch und liefern ihre Indizes zum Austragen.
	var entfernte: Array[int] = []
	var aufgeweckt := 0
	# Bild-Wechsel: Der Deckel zählt neu, weil ein neues Bild neue Rechenzeit
	# bringt. Mehrere Ticks im selben Bild teilen sich dasselbe Budget.
	var rahmen := Engine.get_process_frames()
	if rahmen != _letzter_rahmen:
		_letzter_rahmen = rahmen
		_aufweckungen_je_rahmen = 0
	for index in tiere.size():
		var tier: Dictionary = tiere[index]
		var status: Tier_Status = tier["status"]
		var darsteller_knoten: Variant = tier.get("darsteller")
		if darsteller_knoten != null and not is_instance_valid(darsteller_knoten):
			# Toter Verweis: Der Darsteller hat sich selbst entfernt.
			entfernte.append(index)
			continue
		var darsteller := darsteller_knoten as Tier_Darsteller
		if darsteller == null:
			# Schlafend: Der Eintrag lebt als Logik ohne Node weiter.
			if _vogel_abflug_fertig(status):
				entfernte.append(index)
			elif aufgeweckt < MAX_AUFWECKUNGEN_PRO_TICK and _aufweckungen_je_rahmen < MAX_AUFWECKUNGEN_PRO_BILD and enthaelt(tier["position"]):
				tier["darsteller"] = darsteller_erzeugen.call(str(tier["tier_id"]), status, tier["position"])
				aufgeweckt += 1
				_aufweckungen_je_rahmen += 1
			continue
		# Wach: Wandert das Tier aus dem Blick, schläft es ein. Der Knoten
		# verlässt den Baum vollständig, nur der Logik-Eintrag bleibt stehen.
		if _sammler.ist_aktiv() and not _sammler.enthaelt(tier["position"]):
			if _vogel_abflug_fertig(status):
				entfernte.append(index)
				continue
			if darsteller._verschwindet:
				# Ernte-Ausblendung läuft auf dem Knoten; Eintrag austragen.
				entfernte.append(index)
				continue
			darsteller.queue_free()
			tier["darsteller"] = null
	return entfernte

func _vogel_abflug_fertig(status: Tier_Status) -> bool:
	## Der logische Abflug eines Vogels: Ohne Darsteller endet er im Eintrag,
	## damit schlafende Vögel nicht als Geister ewig weiterfliegen.
	if status.zustand != Tier_Status.Zustand.WEGFLIEGEN or not status.ist_vogel():
		return false
	var tier_daten := status.verhalten.tier_daten(status.tier_id)
	var steig_anteil := 40 if tier_daten == null else tier_daten.steig_anteil_ticks
	var fade_dauer := 90 if tier_daten == null else tier_daten.fade_dauer_ticks
	return status.tick_in_zustand > steig_anteil + fade_dauer
