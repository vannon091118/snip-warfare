extends RefCounted
class_name Einheit_VerhaltensMaschine
## Autonomes Verhalten der Einheiten: Der hungergetriebene Kannibalismus ist
## die erste Verbraucherin der Eskalationsketten, die Moral (Pop_MoralInstanz)
## entscheidet, ob die Kolonie die Tat traegt, und die Autonomie-Maschine
## vergibt Idle-Einheiten den ersten erfuellten Prioritaetsschritt. Diese
## Maschine waehlt nur; Opfer-Wahl sitzt in der Not-Jagd-Maschine, die
## Ausfuehrung bleibt in der Ernte-Maschine und der Job-Architektur.
## Jede Moral-Blockade meldet sich an die Zustands-Timeline, damit das
## Warum-Fenster die Eskalations-Entscheidung beantworten kann (CP-8.1).

## Kategorie daten: Referenzen und die drei Untermaschinen.
var _manager: Einheit_Manager = null
var _mood_mod_registry: Pop_MoodModifikatorRegistry = null
var _moral: Pop_MoralInstanz = null
var _autonomie: Einheit_AutonomieMaschine = null
var _timeline: Kern_Timeline = null
var _not_jagd := Einheit_NotJagdMaschine.new()

## Kategorie logik: Idle-Verhalten pruefen und Job vergeben.

func einrichten(p: Dictionary) -> void:
	_manager = p.get("manager")
	_mood_mod_registry = p.get("mood_mod_registry")
	_not_jagd.einrichten(p)
	_moral = p.get("moral")
	_autonomie = p.get("autonomie")
	_timeline = p.get("timeline")

func tiere_setzen(neue_tiere: Tier_Manager) -> void:
	_not_jagd.tiere_setzen(neue_tiere)

func cache_erneuern(nummer: int) -> void:
	_not_jagd.cache_erneuern(nummer)

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
		_autonomie_fuer(index)
		return
	var opfer := _not_jagd.opfer_fuer(index)
	if opfer < 0:
		_autonomie_fuer(index)
		return
	if _moral != null and not _moral.darf_verhalten("kannibalismus"):
		# Ersatzhandlung statt Verzweiflungstat: Die Autonomie nimmt den
		# naechsten legalen Auftrag; bleibt sie leer, verhungert die Einheit
		# bewusst, statt den Nachbarn zu jagen.
		_blockade_melden(index, "kannibalismus_verboten")
		_autonomie_fuer(index)
		return
	_manager.job_vergeben(index, "kannibale", Job_Basis.ZielTyp.OWN, opfer, _manager.einheit_position(opfer))
	# Die Hervorhebung nach der Vergabe: Der Jobwechsel denkt sonst seine
	# Zeile ueber die Erzaehlung der Tat.
	mood.bereich_hervorheben(hunger_mod.mod_id, stufe)

func _autonomie_fuer(index: int) -> void:
	if _autonomie == null:
		return
	_autonomie.autonom_fuer(index)

func _blockade_melden(index: int, blockade_id: String) -> void:
	## Die Buchung der Verweigerung: Warum keine Jagd auf den Nachbarn.
	if _timeline == null:
		return
	var aktion := _moral.ersatzhandlung_fuer(blockade_id)
	_timeline.eintrag_anhaengen(_tick_nummer(), "einheit_%d" % index, "moral",
		"Eskalation blockiert (%s), Ersatzhandlung: %s" % [blockade_id, aktion if aktion != "" else "keine"],
		{"verhalten": "kannibalismus"}, {"verhalten": "autonomie"}, "moral", 1.0)

func _tick_nummer() -> int:
	var baum := Engine.get_main_loop() as SceneTree
	if baum == null:
		return 0
	var weltuhr := baum.root.get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_method("tick_nummer"):
		return int(weltuhr.tick_nummer())
	return 0
