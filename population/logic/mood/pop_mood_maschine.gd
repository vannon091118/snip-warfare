extends Node
class_name Pop_MoodMaschine
## State-Maschine der Stimmung. Genau eine Verantwortung:
## Aus Bedürfnissen und Status-Übergängen wird die Mood je Einheit
## abgeleitet. Haltung: Sprechblase + Emoji, nicht Zahl im HUD.
## Architektur: konsumiert nach oben, akkumuliert, gibt nie zurück.
## Die Maschine hängt als Node-Kind im eigenen Need-Baum (Pop_NeedBaum)
## und trägt ihr Rassen-Schema: Die Need-Raten laufen über den Faktor der
## eigenen Modifikator-Maschine (Bereich need) mal die Multiplikatoren
## des Rassen-Schemas.

signal mood_geaendert(mood: Pop_Mood)

## Kategorie daten: Need-Stand je Einheit und aktuelle Mood.
var _need_registry: Pop_NeedRegistry = null
var _lager: Lager_Manager = null
var _waerme_feld: Welt_WaermeFeld = null
var _tageszyklus: Welt_TageszyklusMaschine = null
var _mood_mods: Pop_MoodModifikatorRegistry = null
var _welt_position: Vector2 = Vector2.ZERO
var _werte: Dictionary = {}
var _mood: Pop_Mood = Pop_Mood.new()
var _rassen_schema: Pop_RassenSchema = null
var _modifikatoren := Kern_ModifikatorMaschine.new()

## Kategorie logik: Tick, Übergänge, abgeleitete Stimmung.

func _init() -> void:
	# Eigene Modifikator-Maschine mit Bereich Need: Der zentrale Faktor
	# skaliert die Need-Raten; die Rassen-Multiplikatoren kommen vom Schema.
	_modifikatoren.bereich_setzen("need")
	_modifikatoren.aktualisieren()

func einrichten(need_registry: Pop_NeedRegistry, lager: Lager_Manager) -> void:
	_need_registry = need_registry
	_lager = lager

func rassen_schema_setzen(schema: Pop_RassenSchema) -> void:
	_rassen_schema = schema

func waerme_und_zyklus_setzen(waerme_feld: Welt_WaermeFeld, tageszyklus: Welt_TageszyklusMaschine, mood_mods: Pop_MoodModifikatorRegistry) -> void:
	_waerme_feld = waerme_feld
	_tageszyklus = tageszyklus
	_mood_mods = mood_mods

func welt_position_setzen(pos: Vector2) -> void:
	_welt_position = pos

func mood() -> Pop_Mood:
	return _mood

func need_wert(need_id: String) -> float:
	return float(_werte.get(need_id, 0.0))

func auf_tick(_nummer: int, _delta: float) -> Vector2:
	if _need_registry == null:
		return Vector2.INF
	for typ: Pop_NeedBasis in _need_registry.alle_typen():
		var vorher := float(_werte.get(typ.need_id, 0.0))
		var verfuegbar := _verfuegbar_fuer(typ)
		if typ.need_id == "waerme" and _waerme_feld != null:
			var hell := 1.0 if _tageszyklus == null else _tageszyklus.helligkeit()
			var waerme := _waerme_feld.waerme_an(_welt_position, hell)
			if waerme < -0.35:
				verfuegbar = -1
			elif waerme > 0.55:
				verfuegbar = 99
			else:
				verfuegbar = schwellwert_fuer(typ)
		var naechster := vorher
		if verfuegbar < schwellwert_fuer(typ):
			naechster = clampf(vorher + dringlichkeit_fuer(typ), 0.0, 1.0)
		else:
			naechster = clampf(vorher - abfall_fuer(typ), 0.0, 1.0)
		_werte[typ.need_id] = naechster
	_ableiten()
	return _hp_folge_und_ziel()

func auf_jobwechsel(von: String, nach: String, _job_id: String) -> void:
	# Job -> Idle -> Transport bekommt jeweils eine denkende Zeile.
	var ereignis := "%s->%s" % [von, nach]
	match ereignis:
		"arbeiten->idle":
			_setze_gedanke("pause", "💭", "Puh, geschafft.")
		"idle->transport":
			_setze_gedanke("transport", "📦", "Pack ich ins Lager.")
		"idle->arbeiten":
			_setze_gedanke("arbeiten", "🔨", "Zurück an die Arbeit.")
		_:
			pass
	_ableiten()

func _verfuegbar_fuer(typ: Pop_NeedBasis) -> int:
	if _lager != null and not typ.ressource.is_empty():
		return _lager.gesamt_bestand(typ.ressource)
	return 0

## Rassen-Schema und zentraler Faktor: Diese Maschine sorgt über ihren
## Modifikator-Faktor mal die Multiplikatoren des Schemas für die Raten.

func dringlichkeit_fuer(typ: Pop_NeedBasis) -> float:
	var schema_faktor := _rassen_schema.faktor_dringlichkeit if _rassen_schema != null else 1.0
	return maxf(typ.dringlichkeit_pro_tick * schema_faktor * _modifikatoren.faktor(), 0.0)

func abfall_fuer(typ: Pop_NeedBasis) -> float:
	var schema_faktor := _rassen_schema.faktor_abfall if _rassen_schema != null else 1.0
	return maxf(typ.abfall_pro_tick * schema_faktor * _modifikatoren.faktor(), 0.0)

func schwellwert_fuer(typ: Pop_NeedBasis) -> int:
	var schema_faktor := _rassen_schema.faktor_schwellwert if _rassen_schema != null else 1.0
	return maxi(int(round(float(typ.schwellwert) * schema_faktor)), 0)

func nahrungs_faktor() -> float:
	# Kombinierter Verbrauchsfaktor je Rasse: Schema mal zentraler Faktor.
	var schema_faktor := _rassen_schema.faktor_nahrung if _rassen_schema != null else 1.0
	return maxf(schema_faktor * _modifikatoren.faktor(), 0.1)

func bewegungs_faktor() -> float:
	# Rassen-Multiplikator für die Bewegung der Einheit.
	return _rassen_schema.faktor_bewegung if _rassen_schema != null else 1.0

func waerme_wert() -> float:
	if _waerme_feld == null:
		return 0.0
	var hell := 1.0 if _tageszyklus == null else _tageszyklus.helligkeit()
	return _waerme_feld.waerme_an(_welt_position, hell)

func _hp_folge_und_ziel() -> Vector2:
	var w := waerme_wert()
	var mod: Pop_MoodModifikator = null
	if w < -0.35 and _mood_mods != null:
		mod = _mood_mods.mod_fuer("kaelte")
	elif w > 0.55 and _mood_mods != null:
		mod = _mood_mods.mod_fuer("hitze")
	if mod != null and mod.verhalten == "in_sicherheit_bringen" and _waerme_feld != null:
		return _waerme_feld.naechstes_feuer_fuer(_welt_position) if w < -0.35 else _flucht_von_feuer()
	return Vector2.INF

func _flucht_von_feuer() -> Vector2:
	if _waerme_feld == null:
		return Vector2.INF
	var feuer := _waerme_feld.naechstes_feuer_fuer(_welt_position)
	if feuer == Vector2.INF:
		return Vector2.INF
	return _welt_position + (_welt_position - feuer).normalized() * Welt_Model.KACHEL_GROESSE * 3.0

func _ableiten() -> void:
	var w := waerme_wert() if _waerme_feld != null else 0.0
	var gate_mod: Pop_MoodModifikator = null
	if w < -0.35 and _mood_mods != null:
		gate_mod = _mood_mods.mod_fuer("kaelte")
	elif w > 0.55 and _mood_mods != null:
		gate_mod = _mood_mods.mod_fuer("hitze")
	if gate_mod != null:
		var g := Pop_Mood.new()
		g.aktive_need_id = gate_mod.need_id
		g.emoji = gate_mod.emoji
		g.sprechblase_text = gate_mod.sprechblase_text
		g.intensitaet = clampf(absf(w), 0.4, 1.0)
		g.quelle = "waerme"
		_mood = g
		mood_geaendert.emit(_mood)
		return
	var best_id := ""
	var best_staerke := 0.0
	for need_id: String in _werte.keys():
		var staerke := float(_werte[need_id])
		if staerke > best_staerke:
			best_staerke = staerke
			best_id = need_id
	if best_staerke < 0.15:
		if not _mood.leer():
			_mood = Pop_Mood.new()
			mood_geaendert.emit(_mood)
		return
	var typ := _need_registry.typ_fuer(best_id) if _need_registry != null else null
	var neu := Pop_Mood.new()
	neu.aktive_need_id = best_id
	neu.intensitaet = best_staerke
	neu.quelle = "tick"
	if typ != null:
		neu.emoji = typ.emoji
		neu.sprechblase_text = typ.sprechblase_text
	_mood = neu
	mood_geaendert.emit(_mood)

func _setze_gedanke(need_id: String, emoji: String, text: String) -> void:
	var neu := Pop_Mood.new()
	neu.aktive_need_id = need_id
	neu.emoji = emoji
	neu.sprechblase_text = text
	neu.intensitaet = 0.6
	neu.quelle = "uebergang"
	_mood = neu
	mood_geaendert.emit(_mood)
