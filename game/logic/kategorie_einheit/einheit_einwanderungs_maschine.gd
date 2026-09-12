extends RefCounted
class_name Einheit_EinwanderungsMaschine
## Einwanderung: Diese Maschine erzeugt eine neue Einheit samt Status,
## Darsteller, Stimmung, Denkblase und Inventar und haengt sie an die
## Einheitenliste des Managers. Sie kennt die Regeln der Ankunft, nicht die
## Regeln der Arbeit: Takt, Jobs und Verteilung liegen bei anderen Maschinen.

var _kontext: Dictionary = {}


func einrichten(kontext: Dictionary) -> void:
	## Der Kontext traegt Liste, Szene, Datenquellen und die Verbinder.
	_kontext = kontext


func hinzufuegen(welt_position: Vector2, rasse_id: String = "") -> int:
	## Legt eine Einheit an und liefert ihren Index in der Einheitenliste.
	var einheiten: Array[Dictionary] = _kontext["einheiten"]
	var verbinder: Dictionary = _kontext["verbinder"]
	var status := Einheit_Status.new()
	status.welt_position_setzen(welt_position)
	var darsteller := Einheit_Darsteller.new()
	darsteller.einrichten(status)
	darsteller.position = welt_position
	darsteller.animation_setzen(status.animation())
	var rasse := _rasse_fuer(rasse_id)
	var mood := _mood_fuer(rasse, welt_position)
	status.rasse_faktor_setzen(mood.bewegungs_faktor())
	var denkblase := Pop_Denkblase.new()
	denkblase.einrichten(mood)
	darsteller.add_child(denkblase)
	(_kontext["node"] as Node2D).add_child(darsteller)
	status.zustand_geaendert.connect(verbinder["zustand_geaendert"].bind(status, mood))
	status.arbeitsschritt_erledigt.connect(verbinder["arbeitsschritt"].bind(status))
	status.job_loop_gefragt.connect(verbinder["job_loop"].bind(status))
	status.naechster_job_aus_queue.connect(verbinder["naechster_job"].bind(status))
	var inventar := _inventar_anlegen()
	var ei := einheiten.size()
	inventar.einheit_id_setzen("einheit_%d" % ei)
	inventar.inventar_voll.connect(verbinder["inventar_voll"].bind(ei))
	einheiten.append({
		"status": status,
		"darsteller": darsteller,
		"mood": mood,
		"denkblase": denkblase,
		"position": welt_position,
		"rasse": rasse,
		"inventar": inventar,
		"_letzter_zustand": status.zustand,
	})
	if _kontext["ernte"] != null:
		(_kontext["ernte"] as Einheit_ErnteMaschine).inventar_fuer_einheit_setzen(ei, inventar)
	return ei


func _rasse_fuer(rasse_id: String) -> String:
	## Ohne Wunsch gilt die Standard-Rasse des Need-Baums, sonst der Mensch.
	if rasse_id != "":
		return rasse_id
	var baum: Pop_NeedBaum = _kontext["need_baum"]
	return baum.standard_rasse() if baum != null else "mensch"


func _mood_fuer(rasse: String, welt_position: Vector2) -> Pop_MoodMaschine:
	## Mit Need-Baum gehoert die Stimmung in den Baum, ohne ihn steht sie allein.
	var baum: Pop_NeedBaum = _kontext["need_baum"]
	var mood: Pop_MoodMaschine = null
	if baum != null:
		mood = baum.einheit_need_anlegen(rasse, welt_position)
	else:
		mood = Pop_MoodMaschine.new()
		mood.einrichten(_kontext["need_registry"], _kontext["lager"])
		mood.welt_position_setzen(welt_position)
	mood.waerme_und_zyklus_setzen(_kontext["waerme_feld"], _kontext["tageszyklus"],
		_kontext["mood_mod_registry"])
	return mood


func _inventar_anlegen() -> Einheit_Inventar:
	## Das physische Inventar jeder Einheit; die Timeline kommt aus den Ressourcen.
	var inventar := Einheit_Inventar.new()
	var ressourcen: Einheit_Ressourcen = _kontext["ressourcen"]
	if ressourcen != null and ressourcen.has_method("timeline_holen"):
		inventar.timeline_setzen(ressourcen.timeline_holen())
	return inventar
