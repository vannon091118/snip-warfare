extends Tier_Basis
class_name Tier_Baer
## Datenklasse des Bären. Liest ihre Werte selbst aus tier_verhalten.json.
## Kombinationsprinzip: Ein Tier verweist über logik_id auf generische Logik
## und über modifikator_id auf den Faktor (1.0 = 10 Sekunden Takt).

var baer_id: String = "baer"
var baer_name: String = "Bär"
var baer_kategorie: StringName = &"Tiere"
var baer_sheet_pfad: String = ""
var baer_frame_breite: int = 48
var baer_frame_hoehe: int = 72
var baer_fleisch: int = 30
var baer_hp: int = 30
var baer_trigger_radius: float = 700.0
var baer_gehe_geschwindigkeit: float = 160.0
var baer_aufhalte_abstand: float = 120.0
var baer_ausloeser: String = "verfolgen"
var baer_logik_id: String = ""
var baer_modifikator_id: String = "normal"
var baer_faktor: float = 1.0

func aus_verhalten_eintrag(eintrag: Dictionary) -> void:
	super.aus_verhalten_eintrag(eintrag)
	baer_id = tier_id
	baer_name = tier_name
	baer_kategorie = tier_kategorie
	baer_sheet_pfad = sheet_pfad
	baer_frame_breite = frame_breite
	baer_frame_hoehe = frame_hoehe
	baer_fleisch = fleisch
	baer_hp = hp
	baer_trigger_radius = trigger_radius
	baer_gehe_geschwindigkeit = gehe_geschwindigkeit
	baer_aufhalte_abstand = aufhalte_abstand
	baer_ausloeser = ausloeser
	baer_logik_id = logik_id
	baer_modifikator_id = modifikator_id
	baer_faktor = faktor
