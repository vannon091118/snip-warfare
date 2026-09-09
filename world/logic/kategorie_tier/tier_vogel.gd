extends Tier_Basis
class_name Tier_Vogel
## Datenklasse des Vogels. Liest ihre Werte selbst aus tier_verhalten.json.

var vogel_id: String = "vogel"
var vogel_name: String = "Vogel"
var vogel_kategorie: StringName = &"Tiere"
var vogel_sheet_pfad: String = ""
var vogel_frame_breite: int = 32
var vogel_frame_hoehe: int = 64
var vogel_fleisch: int = 1
var vogel_hp: int = 1
var vogel_trigger_radius: float = 380.0
var vogel_flug_geschwindigkeit: float = 260.0
var vogel_steig_anteil_ticks: int = 40
var vogel_fade_dauer_ticks: int = 90
var vogel_ausloeser: String = "wegfliegen"
var vogel_logik_id: String = ""
var vogel_modifikator_id: String = "normal"
var vogel_faktor: float = 1.0

func aus_verhalten_eintrag(eintrag: Dictionary) -> void:
	super.aus_verhalten_eintrag(eintrag)
	vogel_id = tier_id
	vogel_name = tier_name
	vogel_kategorie = tier_kategorie
	vogel_sheet_pfad = sheet_pfad
	vogel_frame_breite = frame_breite
	vogel_frame_hoehe = frame_hoehe
	vogel_fleisch = fleisch
	vogel_hp = hp
	vogel_trigger_radius = trigger_radius
	vogel_flug_geschwindigkeit = flug_geschwindigkeit
	vogel_steig_anteil_ticks = steig_anteil_ticks
	vogel_fade_dauer_ticks = fade_dauer_ticks
	vogel_ausloeser = ausloeser
	vogel_logik_id = logik_id
	vogel_modifikator_id = modifikator_id
	vogel_faktor = faktor
