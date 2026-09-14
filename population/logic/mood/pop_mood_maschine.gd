extends Node
class_name Pop_MoodMaschine
## State-Maschine der Stimmung. Genau eine Verantwortung: Aus Bedürfnissen
## und Status-Übergängen wird die Mood je Einheit abgeleitet. Haltung:
## Sprechblase plus Emoji, nicht Zahl im HUD. Architektur: konsumiert nach
## oben, akkumuliert, gibt nie zurück. Die Raten rechnet Pop_MoodRaten, die
## Wärme prüft Pop_MoodWaermeGate, die Ableitung wohnt in Pop_MoodAbleitung,
## die Blasen baut Pop_MoodEskalation; diese Maschine trägt den Bestand,
## verbindet die vier Helfer und meldet jeden Wechsel nach oben.

signal mood_geaendert(mood: Pop_Mood)

## Kategorie daten: Need-Stand je Einheit und aktuelle Mood.
var _need_registry: Pop_NeedRegistry = null
var _lager_bestaende: Dictionary = {}
var _rassen_schema: Pop_RassenSchema = null
var _mood_mods: Pop_MoodModifikatorRegistry = null
var _werte: Dictionary = {}
var _mood: Pop_Mood = Pop_Mood.new()
## Kategorie logik: Die drei Helfer tragen je eine Verantwortung.
var _raten := Pop_MoodRaten.new()
var _waerme := Pop_MoodWaermeGate.new()
var _ableitung := Pop_MoodAbleitung.new()

func einrichten(need_registry: Pop_NeedRegistry, bestaende: Dictionary = {}) -> void:
	_need_registry = need_registry
	_lager_bestaende = bestaende.duplicate()
	_ableitung.einrichten(_waerme, _mood_mods, need_registry)

func bestand_setzen(bestaende: Dictionary) -> void:
	_lager_bestaende = bestaende.duplicate()

func rassen_schema_setzen(schema: Pop_RassenSchema) -> void:
	_rassen_schema = schema

func waerme_und_zyklus_setzen(waerme_feld: Welt_WaermeFeld, tageszyklus: Welt_TageszyklusMaschine, mood_mods: Pop_MoodModifikatorRegistry) -> void:
	_mood_mods = mood_mods
	_waerme.einrichten(waerme_feld, tageszyklus, mood_mods)
	_ableitung.einrichten(_waerme, mood_mods, _need_registry)

func welt_position_setzen(pos: Vector2) -> void:
	_waerme.position_setzen(pos)

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
		if typ.need_id == "waerme" and _waerme.bereit():
			verfuegbar = _waerme.ersatz_verfuegbarkeit(_raten.schwellwert(typ, _rassen_schema))
		_werte[typ.need_id] = _ableitung.schritt(typ, vorher, verfuegbar, _raten, _rassen_schema)
	_ableiten()
	return _waerme.folge_ziel(_waerme.gate_mod())

func auf_jobwechsel(von: String, nach: String, _job_id: String) -> void:
	# Job -> Idle -> Transport bekommt jeweils eine denkende Zeile.
	match "%s->%s" % [von, nach]:
		"arbeiten->idle":
			_uebernehmen(Pop_MoodEskalation.gedanke("pause", "💭", "Puh, geschafft."))
		"idle->transport":
			_uebernehmen(Pop_MoodEskalation.gedanke("transport", "📦", "Pack ich ins Lager."))
		"idle->arbeiten":
			_uebernehmen(Pop_MoodEskalation.gedanke("arbeiten", "🔨", "Zurück an die Arbeit."))
		_:
			pass
	_ableiten()

func nahrungs_faktor() -> float:
	return _raten.nahrung(_rassen_schema)

func bewegungs_faktor() -> float:
	return _raten.bewegung(_rassen_schema)

func waerme_wert() -> float:
	return _waerme.wert()

func zeugengedanke(tatort: Vector2, hat_gelernt: bool) -> void:
	## Gedanke eines Zeugen: Die Nähe zum Tatort färbt den Satz.
	var neben_an := Pop_MoodEskalation.zeuge_war_nahe(_waerme.position(), tatort)
	_uebernehmen(Pop_MoodEskalation.zeugen(neben_an, hat_gelernt))

func bereich_hervorheben(mod_id: String, stufe: Pop_MoodEskalationStufe) -> void:
	## Sichtbare Hervorhebung einer Kette von außen: Der Manager ruft sie,
	## wenn das autonome Verhalten auslöst, und die Blase erzählt dieselbe
	## Stufe, die das Verhalten wählt. Zwei Erzähl-Quellen entstehen nicht.
	_uebernehmen(Pop_MoodEskalation.aus_stufe(_mod_fuer(mod_id), stufe))

func _verfuegbar_fuer(typ: Pop_NeedBasis) -> int:
	if not _lager_bestaende.is_empty() and not typ.ressource.is_empty():
		# Override-Pfad: Need-Klassen mit mehreren Nahrungsquellen summieren selbst.
		if typ.has_method("hat_verfuegbar_override") and typ.hat_verfuegbar_override():
			return typ.verfuegbar_summe(_lager_bestaende)
		return int(_lager_bestaende.get(typ.ressource, 0))
	return 0

func _ableiten() -> void:
	_uebernehmen(_ableitung.ableiten(_werte))

func _uebernehmen(neu: Pop_Mood) -> void:
	if neu == null:
		return
	if neu.leer() and _mood.leer():
		return
	_mood = neu
	mood_geaendert.emit(_mood)

func _mod_fuer(mod_id: String) -> Pop_MoodModifikator:
	return _mood_mods.mod_fuer(mod_id) if _mood_mods != null else null
