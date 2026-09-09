extends Tier_Basis
class_name Tier_Vogelgruppe
## Datenklasse der Vogelgruppe. Liest ihre Werte selbst aus tier_verhalten.json.

var vogelgruppe_id: String = "vogelgruppe"
var vogelgruppe_name: String = "Vogelgruppe"
var vogelgruppe_kategorie: StringName = &"Tiere"
var vogelgruppe_sheet_pfad: String = ""
var vogelgruppe_frame_breite: int = 48
var vogelgruppe_frame_hoehe: int = 64
var vogelgruppe_fleisch: int = 3
var vogelgruppe_hp: int = 3
var vogelgruppe_trigger_radius: float = 480.0
var vogelgruppe_flug_geschwindigkeit: float = 300.0
var vogelgruppe_steig_anteil_ticks: int = 50
var vogelgruppe_fade_dauer_ticks: int = 110
var vogelgruppe_ausloeser: String = "wegfliegen"
var vogelgruppe_logik_id: String = ""
var vogelgruppe_modifikator_id: String = "normal"
var vogelgruppe_faktor: float = 1.0

func aus_verhalten_eintrag(eintrag: Dictionary) -> void:
	super.aus_verhalten_eintrag(eintrag)
	vogelgruppe_id = tier_id
	vogelgruppe_name = tier_name
	vogelgruppe_kategorie = tier_kategorie
	vogelgruppe_sheet_pfad = sheet_pfad
	vogelgruppe_frame_breite = frame_breite
	vogelgruppe_frame_hoehe = frame_hoehe
	vogelgruppe_fleisch = fleisch
	vogelgruppe_hp = hp
	vogelgruppe_trigger_radius = trigger_radius
	vogelgruppe_flug_geschwindigkeit = flug_geschwindigkeit
	vogelgruppe_steig_anteil_ticks = steig_anteil_ticks
	vogelgruppe_fade_dauer_ticks = fade_dauer_ticks
	vogelgruppe_ausloeser = ausloeser
	vogelgruppe_logik_id = logik_id
	vogelgruppe_modifikator_id = modifikator_id
	vogelgruppe_faktor = faktor
