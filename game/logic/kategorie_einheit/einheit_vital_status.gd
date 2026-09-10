extends RefCounted
class_name Einheit_VitalStatus
## Vitalzustandsmaschine einer Einheit: Lebenspunkte und physische
## Modifikatoren (Verletzungen, Buffs, Debuffs). Sie hat genau eine
## Verantwortung und reagiert nur auf den globalen Tick und Schaden.
## Job-Prüfung und Arbeitsloop bleiben in der Einheit_Status-Maschine;
## diese Maschine meldet ihren Zustand ausschließlich über Signale.

signal modifikator_geandert(modifikator_id: String, hinzugefuegt: bool)
signal hp_veraendert(aktuell: int, maximal: int)
signal gestorben(welt_position: Vector2)

## Kategorie daten: Vitalwerte und getragene Modifikatoren.
var hp: int = 100
var max_hp: int = 100
var _welt_position: Vector2 = Vector2.ZERO
var aktive_modifikatoren: Array[Kern_ModifikatorBasis] = []

## Kategorie logik: Modifikatoren verwalten und Werte ableiten.

func welt_position_setzen(pos: Vector2) -> void:
	_welt_position = pos

func modifikator_hinzufuegen(mod_id: String) -> void:
	if hat_modifikator(mod_id):
		return
	var mod := Kern_ModifikatorRegistry.modifikator_erzeugen(mod_id)
	if mod != null:
		aktive_modifikatoren.append(mod)
		modifikator_geandert.emit(mod_id, true)

func modifikator_entfernen(mod_id: String) -> void:
	var verblieben: Array[Kern_ModifikatorBasis] = []
	for mod in aktive_modifikatoren:
		if mod.modifikator_id != mod_id:
			verblieben.append(mod)
	aktive_modifikatoren = verblieben
	modifikator_geandert.emit(mod_id, false)

func hat_modifikator(mod_id: String) -> bool:
	for mod in aktive_modifikatoren:
		if mod.modifikator_id == mod_id:
			return true
	return false

func blockiert_job(job_id: String) -> String:
	# Liefert den Namen der ersten Verletzung, die diesen Job sperrt; sonst leer.
	for mod in aktive_modifikatoren:
		if mod.blockiert_job(job_id):
			return mod.angezeigter_name
	return ""

func effektive_geschwindigkeit(basis_geschwindigkeit: float) -> float:
	# Trait-Boni laufen über die zentrale Modifikator-Logik; diese Maschine
	# rechnet nichts selbst, sie delegiert nur ihre aktiven Modifikatoren.
	return Kern_ModifikatorMaschine.wert_berechnen(basis_geschwindigkeit, aktive_modifikatoren, 0.1)

func effektive_tragekraft(basis_tragekraft: int) -> int:
	# Dieselbe zentrale Formel wie bei der Geschwindigkeit, nur ganzzahlig.
	return int(Kern_ModifikatorMaschine.wert_berechnen(float(basis_tragekraft), aktive_modifikatoren, 0.0))

func schaden_nehmen(schaden: int, zufall: Kern_Zufall, art: String = "physisch") -> int:
	# Zieht Lebenspunkte ab, meldet Schaden über den Kern-Bus und würfelt
	# physische Folgen ausschließlich über den zentralen Zufallszustand.
	if hp <= 0:
		return 0
	var verbraucht := mini(schaden, hp)
	hp -= verbraucht
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_schaden(_welt_position, verbraucht, art)
	hp_veraendert.emit(hp, max_hp)
	_folgen_würfeln(schaden, art, zufall)
	if hp <= 0:
		sterben()
	return verbraucht

func umgebungsschaden_anwenden(waerme: float, mood_mods: Pop_MoodModifikatorRegistry, zufall: Kern_Zufall) -> void:
	# Progression-Gate: Kälte und Hitze ziehen HP über Mood-Modifikatoren.
	# Die Schwellwerte kommen ausschließlich aus der Registry (mood_modifikatoren.json)
	# und stimmen dadurch mit der Gate-Auswahl der Mood-Maschine überein:
	# Dieselbe Entscheidung, keine zweite Schwellwert-Quelle im Code.
	if mood_mods == null:
		return
	var mod: Pop_MoodModifikator = null
	var kalt := mood_mods.mod_fuer("kaelte")
	var heiss := mood_mods.mod_fuer("hitze")
	if kalt != null and waerme < kalt.schwellwert:
		mod = kalt
	elif heiss != null and waerme > heiss.schwellwert:
		mod = heiss
	if mod == null or mod.hp_abzug_je_tick <= 0:
		return
	schaden_nehmen(mod.hp_abzug_je_tick, zufall, "umgebung")

func heilung_versuchen() -> void:
	# Tick der Weltuhr: heilbare Modifikatoren laufen ab und fallen ab.
	var zu_entfernen: Array[String] = []
	for mod in aktive_modifikatoren:
		if mod.heilbar:
			mod.tick_zaehlen()
			if mod.abgelaufen():
				zu_entfernen.append(mod.modifikator_id)
	for mod_id in zu_entfernen:
		modifikator_entfernen(mod_id)

func sterben() -> void:
	gestorben.emit(_welt_position)

func _folgen_würfeln(schaden: int, art: String, zufall: Kern_Zufall) -> void:
	# Folgen als Zustandsschritt: Jede Würfelreihe wird aus dem zentralen
	# Zufallszustand gezogen und bleibt damit vorhersagbar.
	var wurf := zufall.naechste_zahl() % 100
	if art == "sturz" and wurf < 30:
		modifikator_hinzufuegen("verletzung_bein")
	elif art == "kampf" and wurf < 20:
		modifikator_hinzufuegen("verletzung_arm")
	elif float(schaden) > float(max_hp) / 2.0 and wurf < 40:
		modifikator_hinzufuegen("verblutung")
