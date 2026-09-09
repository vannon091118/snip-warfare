extends Tier_Basis
class_name Tier_Hase
## Datenklasse des Hasen. Liest ihre Werte selbst aus tier_verhalten.json.

var hase_id: String = "hase"
var hase_name: String = "Hase"
var hase_kategorie: StringName = &"Tiere"
var hase_sheet_pfad: String = ""
var hase_frame_breite: int = 32
var hase_frame_hoehe: int = 72
var hase_fleisch: int = 5
var hase_hp: int = 5
var hase_trigger_radius: float = 420.0
var hase_flucht_geschwindigkeit: float = 420.0
var hase_flucht_mindest_distanz: float = 1400.0
var hase_ausloeser: String = "wegrennen"
var hase_logik_id: String = ""
var hase_modifikator_id: String = "normal"
var hase_faktor: float = 1.0

func aus_verhalten_eintrag(eintrag: Dictionary) -> void:
	super.aus_verhalten_eintrag(eintrag)
	hase_id = tier_id
	hase_name = tier_name
	hase_kategorie = tier_kategorie
	hase_sheet_pfad = sheet_pfad
	hase_frame_breite = frame_breite
	hase_frame_hoehe = frame_hoehe
	hase_fleisch = fleisch
	hase_hp = hp
	hase_trigger_radius = trigger_radius
	hase_flucht_geschwindigkeit = flucht_geschwindigkeit
	hase_flucht_mindest_distanz = 1400.0
	hase_ausloeser = ausloeser
	hase_logik_id = logik_id
	hase_modifikator_id = modifikator_id
	hase_faktor = faktor
