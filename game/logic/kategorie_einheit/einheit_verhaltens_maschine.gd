extends RefCounted
class_name Einheit_VerhaltensMaschine
## Autonomes Verhalten der Einheiten: Der hungergetriebene Kannibalismus ist
## die erste Verbraucherin der Eskalationsketten. Der Verzweifelte jagt den
## schwächsten Nachbarn, wenn weder ein jagdbares Tier in Reichweite noch
## Fleisch im Lager ist. Der Auslöser sitzt am eigenen Idle, der Job läuft
## wie jede Jagd über dieselben Maschinen. Der teure Tier- und Nachbarschafts-
## Scan trägt seinen eigenen Performance-Cache.

## Kategorie daten: Referenzen und der Reichweiten-Cache.
var _manager: Einheit_Manager = null
var _mood_mod_registry: Pop_MoodModifikatorRegistry = null
var _job_registry: Job_Registry = null
var _ressourcen: Einheit_Ressourcen = null
var _tiere: Tier_Manager = null
var _tier_reichweite_cache: Dictionary = {}
var _tier_cache_tick: int = -1

## Kategorie logik: Idle-Verhalten prüfen und Job vergeben.

func einrichten(p: Dictionary) -> void:
	_manager = p.get("manager")
	_mood_mod_registry = p.get("mood_mod_registry")
	_job_registry = p.get("job_registry")
	_ressourcen = p.get("ressourcen")
	_tiere = p.get("tiere")

func tiere_setzen(neue_tiere: Tier_Manager) -> void:
	_tiere = neue_tiere

func cache_erneuern(nummer: int) -> void:
	## Der Tier-Reichweiten-Cache lebt genau einen Takt; der Manager ruft
	## dies einmal pro Tick auf, bevor die verstreuten Prüfungen starten.
	if _tier_cache_tick != nummer:
		_tier_cache_tick = nummer
		_tier_reichweite_cache.clear()

func pruefe_verhalten(einheit: Dictionary, index: int) -> void:
	var status: Einheit_Status = einheit["status"]
	if status.zustand != Einheit_Status.Zustand.IDLE or _mood_mod_registry == null:
		return
	var hunger_mod := _mood_mod_registry.mod_fuer("hunger")
	if hunger_mod == null or not hunger_mod.hat_eskalation():
		return
	var mood: Pop_MoodMaschine = einheit["mood"]
	var not_aktuell := mood.need_wert(hunger_mod.need_id)
	var stufe := hunger_mod.stufe_fuer(not_aktuell)
	if stufe == null or stufe.verhalten != "kannibalismus":
		return
	var opfer := _jagd_nachbarn(index)
	if opfer < 0:
		return
	_manager.job_vergeben(index, "kannibale", Job_Basis.ZielTyp.OWN, opfer, _manager.einheit_position(opfer))
	# Die Hervorhebung nach der Vergabe: Der Jobwechsel denkt sonst seine
	# Zeile über die Erzählung der Tat.
	mood.bereich_hervorheben(hunger_mod.mod_id, stufe)

func _jagd_nachbarn(jaeger_index: int) -> int:
	# Schwächster Nachbar in Reichweite: Reichweite und Mindest-HP stehen
	# im kannibale-Eintrag der Job-Konfiguration; niemand jagt sich selbst.
	if _ressourcen != null and _ressourcen.bestand("fleisch") > 0:
		return -1
	if _tiere != null and _tier_in_reichweite(jaeger_index):
		return -1
	var konfig: Dictionary = _job_registry.job_konfigurationen.get("kannibale", {})
	var reichweite := float(konfig.get("reichweite", 60.0))
	var mindest_hp := int(konfig.get("opfer_mindest_hp", 20))
	var eigene := _manager.einheit_position(jaeger_index)
	var bester := -1
	var beste_hp := 0
	for index in _manager.einheit_zahl():
		if index == jaeger_index:
			continue
		if _manager.einheit_status(index).vital.hp <= 0:
			continue
		if _manager.einheit_position(index).distance_to(eigene) > reichweite:
			continue
		var hp := _manager.einheit_hp(index)
		if hp < mindest_hp:
			continue
		if bester == -1 or hp < beste_hp:
			bester = index
			beste_hp = hp
	return bester

func _tier_in_reichweite(jaeger_index: int) -> bool:
	if _tiere == null:
		return false
	if _tier_reichweite_cache.has(jaeger_index):
		return bool(_tier_reichweite_cache[jaeger_index])
	var eigene := _manager.einheit_position(jaeger_index)
	var treffer := false
	for tier_index in _tiere.tier_zahl():
		var tier_pos := _tiere.tier_position(tier_index)
		if tier_pos != Vector2.INF and tier_pos.distance_to(eigene) <= 160.0:
			treffer = true
			break
	_tier_reichweite_cache[jaeger_index] = treffer
	return treffer
