extends Welt_RegistryBasis
class_name Tier_Registry
## Registry der Tiere: lädt tier_verhalten.json und hält je Tierart eine
## eigene Datenklasse (Tier_Baer, Tier_Hase, Tier_Vogel, Tier_Vogelgruppe).
## State Machines lesen ihre Werte ausschließlich aus diesen Instanzen;
## nichts wird hart codiert. Der Preflight zieht seine Referenzen aus dieser
## Registry.

const VERHALTEN_PFAD := "res://world/data/tier_verhalten.json"

## Kategorie daten: getypte Liste aller Tierarten.
var tier_arten: Array[Tier_Basis] = []

## Kategorie logik: Laden und Zuordnung der exakten Tierklassen.
var _arten_nach_id: Dictionary = {}

func _init() -> void:
	super(VERHALTEN_PFAD)

func schema_name() -> String:
	return "Tier_Registry"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Tier-Verhaltensdaten haben ein ungültiges Format: %s" % VERHALTEN_PFAD)
		return false
	tier_arten.clear()
	_arten_nach_id.clear()
	for tier_id: String in (gelesen as Dictionary).keys():
		var eintrag: Dictionary = gelesen[tier_id]
		eintrag["id"] = tier_id
		if not Kern_AssetPruefer.eintrag_hat_asset(eintrag):
			var platzhalter := Kern_AssetPruefer.sichere_textur_pfad(eintrag, tier_id)
			eintrag["sheet_pfad"] = platzhalter
		if not eintrag.has("textur_pfad"):
			eintrag["textur_pfad"] = eintrag.get("sheet_pfad", "")
		if not Kern_AssetPruefer.textur_pfad_gueltig(str(eintrag.get("sheet_pfad", ""))):
			push_warning("Tier '%s': kein gültiges Asset; Platzhalter wird verwendet" % tier_id)
		var tier := _tier_klasse_fuer(tier_id)
		tier.aus_verhalten_eintrag(eintrag)
		tier_arten.append(tier)
		_arten_nach_id[tier_id] = tier
		registrieren(tier_id, tier)
	return true

func _tier_klasse_fuer(tier_id: String) -> Tier_Basis:
	# Zentrale Zuordnung: jede Tierart erhält ihre eigene Datenklasse.
	# Kombinationsprinzip: Eisbär nutzt dieselbe Logik wie Bär (baer_verfolgen)
	# und einen eigenen Modifikator (aggressiv, Faktor 1.2). Keine neue Maschine.
	match tier_id:
		"baer":
			return Tier_Baer.new()
		"eisbaer":
			return Tier_Eisbaer.new()
		"hase":
			return Tier_Hase.new()
		"vogel":
			return Tier_Vogel.new()
		"vogelgruppe":
			return Tier_Vogelgruppe.new()
	return Tier_Basis.new()

func tier_daten(tier_id: String) -> Tier_Basis:
	if _arten_nach_id.has(tier_id):
		return _arten_nach_id[tier_id]
	return null

func fleisch(tier_id: String) -> int:
	var tier := tier_daten(tier_id)
	return 1 if tier == null else tier.fleisch

func hp(tier_id: String) -> int:
	var tier := tier_daten(tier_id)
	return 1 if tier == null else tier.hp

func wert(tier_id: String, schluessel: String, standard: float) -> float:
	# Feld-Zugriff über die Datenklasse; unbekannte Schlüssel liefern den Standard.
	var tier := tier_daten(tier_id)
	if tier == null:
		return standard
	match schluessel:
		"trigger_radius":
			return tier.trigger_radius
		"flucht_geschwindigkeit":
			return tier.flucht_geschwindigkeit
		"flug_geschwindigkeit":
			return tier.flug_geschwindigkeit
		"gehe_geschwindigkeit":
			return tier.gehe_geschwindigkeit
		"aufhalte_abstand":
			return tier.aufhalte_abstand
		"steig_anteil_ticks":
			return float(tier.steig_anteil_ticks)
		"fade_dauer_ticks":
			return float(tier.fade_dauer_ticks)
	return standard

func hat_schluessel(tier_id: String, schluessel: String) -> bool:
	var tier := tier_daten(tier_id)
	if tier == null:
		return false
	match schluessel:
		"flug_geschwindigkeit":
			return tier.flug_geschwindigkeit > 0.0
		"steig_anteil_ticks":
			return tier.steig_anteil_ticks > 0
	return tier.ausloeser != ""

func textur_pfad(tier_id: String) -> String:
	var tier := tier_daten(tier_id)
	return "" if tier == null else tier.sheet_pfad

func frame_groesse(tier_id: String) -> Vector2i:
	var tier := tier_daten(tier_id)
	return Vector2i(48, 72) if tier == null else Vector2i(tier.frame_breite, tier.frame_hoehe)

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["tier_arten"] = "Array[Tier_Basis]"
	return arten
