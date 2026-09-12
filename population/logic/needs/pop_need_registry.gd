extends RefCounted
class_name Pop_NeedRegistry
## Liest population/data/needs.json und erzeugt je Eintrag die Pop_Need-Klasse.
const QUELLE := "res://population/data/needs.json"
const RHYTHMUS_SCHLUESSEL := "weltrhythmus"
const RHYTHMUS_RUECKFALL := {"takt_minuten": 2.0, "tag_minuten": 1.5, "nacht_minuten": 0.5, "verbrauch_je_takt": 0.8}
## Kategorie daten: Typen je need_id und Rhythmus.
var _typen_nach_id: Dictionary = {}
var _typen: Array[Pop_NeedBasis] = []
var _rhythmus: Dictionary = {}
## Kategorie logik: Laden und zentrale Zuordnung.
func _init() -> void:
	laden()

func laden() -> void:
	_typen_nach_id.clear()
	_typen.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Needs-Konfiguration nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Needs-Konfiguration ungültiges Format: %s" % QUELLE)
		return
	for need_id: String in (gelesen as Dictionary).keys():
		if need_id == RHYTHMUS_SCHLUESSEL:
			var rhythmus: Variant = (gelesen as Dictionary)[need_id]
			if typeof(rhythmus) == TYPE_DICTIONARY:
				_rhythmus = (rhythmus as Dictionary).duplicate(true)
			continue
		var eintrag: Dictionary = (gelesen as Dictionary)[need_id]
		eintrag["id"] = need_id
		if not eintrag.has("icon_pfad") or str(eintrag.get("icon_pfad", "")).is_empty():
			push_warning("Need '%s': kein icon_pfad hinterlegt" % need_id)
		var typ := _need_klasse_fuer(need_id, eintrag)
		typ.aus_konfig_eintrag(eintrag)
		_typen.append(typ)
		_typen_nach_id[need_id] = typ

func _need_klasse_fuer(need_id: String, eintrag: Dictionary) -> Pop_NeedBasis:
	var skript_pfad := str(eintrag.get("script", ""))
	if skript_pfad != "":
		if not ResourceLoader.exists(skript_pfad):
			push_warning("Need-Skript fehlt: %s" % skript_pfad)
			return Pop_NeedBasis.new()
		var skript: GDScript = load(skript_pfad)
		if skript != null:
			var objekt: Variant = skript.new()
			if objekt is Pop_NeedBasis:
				return objekt as Pop_NeedBasis
			push_warning("Need-Skript ist kein Pop_NeedBasis: %s" % skript_pfad)
	match need_id:
		"nahrung":
			return Pop_NeedNahrung.new()
		"waerme":
			return Pop_NeedWaerme.new()
	return Pop_NeedBasis.new()
func takt_minuten() -> float:
	return clampf(float(_rhythmus.get("takt_minuten", RHYTHMUS_RUECKFALL["takt_minuten"])), 0.5, Kern_Weltuhr.MINUTEN_MAX)

func tag_minuten() -> float:
	return clampf(float(_rhythmus.get("tag_minuten", RHYTHMUS_RUECKFALL["tag_minuten"])), 0.1, Kern_Weltuhr.MINUTEN_MAX)

func nacht_minuten() -> float:
	return clampf(float(_rhythmus.get("nacht_minuten", RHYTHMUS_RUECKFALL["nacht_minuten"])), 0.1, Kern_Weltuhr.MINUTEN_MAX)

func verbrauch_je_takt() -> float:
	return clampf(float(_rhythmus.get("verbrauch_je_takt", RHYTHMUS_RUECKFALL["verbrauch_je_takt"])), 0.1, 5.0)

func hat_typ(need_id: String) -> bool:
	return _typen_nach_id.has(need_id)

func typ_fuer(need_id: String) -> Pop_NeedBasis:
	return _typen_nach_id.get(need_id, null)

func alle_typen() -> Array[Pop_NeedBasis]:
	return _typen.duplicate()
