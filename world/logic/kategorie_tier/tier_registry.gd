extends Welt_RegistryBasis
class_name Tier_Registry
const VERHALTEN_PFAD := "res://world/data/tier_verhalten.json"
## Kategorie daten: Tierarten je id.
var tier_arten: Array[Tier_Basis] = []
var _arten_nach_id: Dictionary = {}
## Kategorie logik: Laden und Zuordnung.

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
	## Die Zuordnung selbst kennt die eigene Fabrik, nicht die Registry.
	return Tier_KlassenFabrik.klasse_fuer(tier_id)

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
	## Das Feldwissen traegt die eigene Abfrage-Klasse.
	return Tier_FeldAbfrage.wert(tier_daten(tier_id), schluessel, standard)

func hat_schluessel(tier_id: String, schluessel: String) -> bool:
	## Die Abfrage-Klasse weiss, wann ein Feld wirklich gesetzt ist.
	return Tier_FeldAbfrage.hat_schluessel(tier_daten(tier_id), schluessel)

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
