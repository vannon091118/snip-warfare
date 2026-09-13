extends SceneTree
## Beweislauf der Sozial-Domäne (Regel 9): Eine Tat am Bus, drei Zeugen,
## ein wanderndes Gerücht mit Farbe und Stufe, eine langfristige Beziehung.
## Der Manager wird in der ersten Runde geholt, damit sein _ready gefeuert hat
## und der Datenpool geladen ist; danach folgt die Beweis-Kette.

const SOZ_SKRIPT := "res://population/logic/sozial/logic/soz_manager.gd"

var _manager: Node = null
var _runde := 0

func _initialize() -> void:
	var manager: Node = load(SOZ_SKRIPT).new()
	root.add_child(manager)
	process_frame.connect(_auf_frame)

func _auf_frame() -> void:
	_runde += 1
	if _runde == 1:
		# Jetzt ist _ready gelaufen: Der Datenpool trägt seine Gruppen.
		_manager = root.get_children().filter(func(k: Node): return k.get_script() != null \
			and (k.get_script() as Script).resource_path.contains("soz_manager")).front()
		print("DATENPOOL_GRUPPEN: ", _manager.call("test_datenpool_groesse"))
		_beweis_kette()
		quit(0)

func _beweis_kette() -> void:
	# Drei Einheiten: Taeter (0), Opfer (1), weit entfernter Nachbar (2).
	_manager.call("einheit_anmelden", 0, Vector2.ZERO, ["tratscht_gerne"])
	_manager.call("einheit_anmelden", 1, Vector2(50, 0), ["skeptiker"])
	_manager.call("einheit_anmelden", 2, Vector2(4000, 0), [])
	# Tat: Ein Einheiten-Tod am Ort des Taeters (Kannibalismus-Fall).
	var bus := Kern_SignalBus.bus()
	print("BUS_DA: ", bus != null)
	if bus != null:
		bus._emit_gestorben(Vector2(10, 0), "einheit", true)
	print("ETHIK_TAETER: ", _manager.call("ethik_von", 0))
	print("ETHIK_ZEUGE: ", _manager.call("ethik_von", 1))
	print("GERUECHT_TAEGER: ", (_manager.call("geruechte_von", 0) as Array).size())
	# Gerede-Takte: Das Gerücht wandert an den nächsten Nachbarn.
	for i in 200:
		_manager.call("auf_tick", i, 1.0 / 24.0)
	var blaese: Array = _manager.call("geruechte_von", 1)
	print("GERUECHT_BEIM_ZEUGEN_NACH_TAKTEN: ", blaese.size())
	for g in blaese:
		print("GERUECHT art=", g.art, " stufe=", g.eskalation(), " glaube=%.2f" % g.glaube, " farbe=", g.farbe())
		print("BLASE_ERZAEHLT: ", g.erzaehlung())
	print("BEZIEHUNG_ZEUGE_ZU_TAETER: %.3f stufe=%s" % [
		_manager.call("beziehung_von", 1, 0), _manager.call("beziehungs_stufe", 1, 0)])
	print("BEZIEHUNG_FERN_ZU_TAETER: %.3f" % _manager.call("beziehung_von", 2, 0))
