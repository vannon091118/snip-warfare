extends RefCounted
class_name Tier_Basis
## Datenklasse eines Tieres. Enthält ausschließlich Daten: Sprite-Sheet,
## Frame-Maße, Ertrag (Harvest) und Lebenspunkte. Die Werte liest jede
## Tier-Klasse selbst aus tier_verhalten.json; die Zustandsmaschine
## Tier_Status liest nur diese Felder und berechnet daraus das Verhalten.

var tier_id: String = ""
var tier_name: String = ""
var tier_kategorie: StringName = &"Tiere"
var sheet_pfad: String = ""
var frame_breite: int = 48
var frame_hoehe: int = 72
var fleisch: int = 1
var hp: int = 1
var trigger_radius: float = 400.0
var flucht_geschwindigkeit: float = 400.0
var flug_geschwindigkeit: float = 280.0
var gehe_geschwindigkeit: float = 150.0
var aufhalte_abstand: float = 120.0
var steig_anteil_ticks: int = 40
var fade_dauer_ticks: int = 90
var ausloeser: String = ""
var logik_id: String = ""
var modifikator_id: String = "normal"
var faktor: float = 1.0

func aus_verhalten_eintrag(eintrag: Dictionary) -> void:
	# Reines Einlesen der Daten aus dem JSON-Eintrag; nichts wird berechnet.
	tier_id = str(eintrag.get("id", ""))
	tier_name = str(eintrag.get("name", tier_id))
	tier_kategorie = StringName(str(eintrag.get("kategorie", "Tiere")))
	sheet_pfad = str(eintrag.get("sheet_pfad", ""))
	frame_breite = int(eintrag.get("frame_breite", 48))
	frame_hoehe = int(eintrag.get("frame_hoehe", 72))
	fleisch = int(eintrag.get("fleisch", 1))
	hp = int(eintrag.get("hp", fleisch))
	trigger_radius = float(eintrag.get("trigger_radius", 400.0))
	flucht_geschwindigkeit = float(eintrag.get("flucht_geschwindigkeit", 400.0))
	flug_geschwindigkeit = float(eintrag.get("flug_geschwindigkeit", 280.0))
	gehe_geschwindigkeit = float(eintrag.get("gehe_geschwindigkeit", 150.0))
	aufhalte_abstand = float(eintrag.get("aufhalte_abstand", 120.0))
	steig_anteil_ticks = int(eintrag.get("steig_anteil_ticks", 40))
	fade_dauer_ticks = int(eintrag.get("fade_dauer_ticks", 90))
	ausloeser = str(eintrag.get("ausloeser", ""))
	logik_id = str(eintrag.get("logik_id", ""))
	modifikator_id = str(eintrag.get("modifikator_id", "normal"))
	faktor = float(eintrag.get("faktor", 1.0))

func ticks_fuer_faktor() -> int:
	# 1.0 bedeutet zehn Sekunden; die Weltuhr übersetzt in Ticks.
	return maxi(int(round(clampf(faktor, 0.1, 10.0) * 10.0 * Kern_Weltuhr.TICK_RATE_HZ)), 1)

func effektive_logik() -> String:
	return logik_id

func effektiver_modifikator() -> String:
	return modifikator_id
