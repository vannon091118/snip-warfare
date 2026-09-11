extends RefCounted
class_name Pop_NeedRegistry
## Registry aller Bedürfnisse. Liest population/data/needs.json
## und erzeugt je Eintrag die passende Pop_Need-Klasse.
## Plugin-Grenze: Ein neues Bedürfnis braucht kein Berühren dieser Klasse,
## es registriert sich über das Feld script in needs.json; die zentrale
## Zuordnung dient nur noch als Übergangs-Fallback für Einträge ohne
## script-Feld.

const QUELLE := "res://population/data/needs.json"

## Eigener Abschnitt derselben Datei: Der Spielrhythmus ist keine
## Bedürfnisart, sondern die gemeinsame Zeitkonfiguration von Tageszyklus
## und Nahrungsverteilung. Er wird hier gelesen und über die Getter
## herausgegeben; kein anderer Code liest diese Werte aus der Datei.
const RHYTHMUS_SCHLUESSEL := "weltrhythmus"
## Rückfallwerte nur für den Fall einer fehlenden oder defekten Datei;
## im Normalfall kommen alle Werte aus needs.json.
const RHYTHMUS_RUECKFALL := {
	"takt_minuten": 2.0,
	"tag_minuten": 1.5,
	"nacht_minuten": 0.5,
	"verbrauch_je_takt": 0.8,
}

## Kategorie daten: Typen je need_id und der gelesene Spielrhythmus.
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
	# Plugin-Zuordnung: Das script-Feld bestimmt die Klasse; nur Einträge
	# ohne script-Feld fallen auf die zentrale Zuordnung zurück.
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
	# Übergangs-Fallback: zentrale Zuordnung für Einträge ohne script-Feld.
	match need_id:
		"nahrung":
			return Pop_NeedNahrung.new()
		"waerme":
			return Pop_NeedWaerme.new()
	return Pop_NeedBasis.new()

## Spielrhythmus: Diese vier Getter sind der einzige Zugang zu den Werten
## aus needs.json. Fehlt der Abschnitt, gelten die dokumentierten
## Rückfallwerte, die exakt den bisherigen Code-Zahlen entsprechen.
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
