extends RefCounted
class_name Menue_StoryDaten
## Daten-Grundlage der Menü-Story: Sie liest die 30 Events aus dem JSON-Pool
## und prüft sie mechanisch. Genau eine Verantwortung: geladene, sortierte
## Events bereitstellen. Keine Darstellung, keine Zeit.

## Kategorie daten: die Event-Liste und die Untertitel-Dauer in Ticks.
var events: Array[Dictionary] = []
var untertitel_dauer: int = 96

## Kategorie logik: Laden aus dem Pool und Prüfung der Pflichtfelder.

const PFAD := "res://ui/data/menue_story.json"

func laden() -> bool:
	var datei := FileAccess.open(PFAD, FileAccess.READ)
	if datei == null:
		return false
	var parser := JSON.new()
	if parser.parse(datei.get_as_text()) != OK:
		return false
	var daten: Variant = parser.get_data()
	if not (daten is Dictionary):
		return false
	var pool: Dictionary = daten
	untertitel_dauer = maxi(int(pool.get("untertitel_dauer", 96)), 1)
	var liste: Variant = pool.get("events", [])
	if not (liste is Array):
		return false
	for eintrag: Variant in liste as Array:
		if eintrag is Dictionary and int((eintrag as Dictionary).get("id", 0)) > 0 \
				and str((eintrag as Dictionary).get("art", "")) != "":
			events.append(eintrag as Dictionary)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("id", 0)) < int(b.get("id", 0)))
	return not events.is_empty()

## Das nächste Event nach dem gegebenen Takt, oder ein leeres Wörterbuch.
func naechstes(ab_tick: int) -> Dictionary:
	for event: Dictionary in events:
		if int(event.get("start", 0)) > ab_tick:
			return event
	return {}

func erster() -> Dictionary:
	if events.is_empty():
		return {}
	return events[0]

func letzter_start() -> int:
	if events.is_empty():
		return 0
	return int(events[events.size() - 1].get("start", 0))
