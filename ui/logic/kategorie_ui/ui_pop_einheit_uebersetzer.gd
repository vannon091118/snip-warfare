extends RefCounted
class_name Ui_PopEinheitUebersetzer
## Uebersetzer für das Pop_EinheitPanel. Liest über geschlossene Schnittpunkte
## aus NeedBaum, MoodMaschine, Einheit_Status und Einheit_Ressourcen.
## Keine eigene Logik, nur Daten-Aggregation für die Anzeige.

var _need_baum: Pop_NeedBaum = null
var _einheit_manager: Einheit_Manager = null
var _ressourcen: Einheit_Ressourcen = null

func einrichten(need_baum: Pop_NeedBaum, einheit_manager: Einheit_Manager, ressourcen: Einheit_Ressourcen) -> void:
	_need_baum = need_baum
	_einheit_manager = einheit_manager
	_ressourcen = ressourcen

func daten_fuer_einheit(index: int) -> Dictionary:
	if _einheit_manager == null or index < 0 or index >= _einheit_manager.einheit_zahl():
		return {}

	var status: Einheit_Status = _einheit_manager.einheit_status(index)
	var mood: Pop_MoodMaschine = _einheit_manager.einheit_mood(index)
	var rasse: String = _einheit_manager.einheit_rasse(index)
	var vital: Einheit_VitalStatus = _einheit_manager.einheit_vital(index)

	if status == null or mood == null:
		return {}

	var need_werte: Dictionary = {}
	var need_registry: Pop_NeedRegistry = null
	if _need_baum != null:
		need_registry = _need_baum.need_registry()

	if mood != null and need_registry != null:
		for typ in need_registry.alle_typen():
			need_werte[typ.need_id] = mood.need_wert(typ.need_id)

	var hunger_wert: float = need_werte.get("nahrung", 0.0)
	var waerme_wert: float = need_werte.get("waerme", 0.0)

	var mood_daten: Dictionary = {}
	if mood != null:
		var aktuelle_mood: Pop_Mood = mood.mood()
		mood_daten = {
			"emoji": aktuelle_mood.emoji,
			"sprechblase": aktuelle_mood.sprechblase_text,
			"intensitaet": aktuelle_mood.intensitaet,
			"quelle": aktuelle_mood.quelle,
			"grund": aktuelle_mood.grund,
			"wirkung": aktuelle_mood.wirkung,
			"verhalten": aktuelle_mood.verhalten,
			"stufe": aktuelle_mood.stufe,
			"kette": aktuelle_mood.kette,
			"aktive_need_id": aktuelle_mood.aktive_need_id,
		}

	var job_name: String = ""
	if status.job != null:
		job_name = status.job.job_id

	var zustand_name: String = "IDLE"
	match status.zustand:
		Einheit_Status.Zustand.GEHEN:
			zustand_name = "GEHEN"
		Einheit_Status.Zustand.ARBEITEN:
			zustand_name = "ARBEITEN"

	var inventar: Dictionary = {}
	if _ressourcen != null:
		for res_id in _ressourcen.ressource_ids():
			inventar[res_id] = _ressourcen.bestand(res_id)

	var hp: int = 0
	if vital != null:
		hp = vital.hp

	return {
		"index": index,
		"rasse": rasse,
		"zustand": zustand_name,
		"job": job_name,
		"hp": hp,
		"hunger_wert": hunger_wert,
		"waerme_wert": waerme_wert,
		"need_werte": need_werte,
		"mood": mood_daten,
		"inventar": inventar,
		"queue_laenge": status.queue_laenge(),
		"ziel_index": status.aktuelles_ziel_index,
		"ziel_ressource": status.ziel_ressource,
		"welt_position": status.welt_position,
	}

func hunger_farbe(hunger_wert: float) -> Color:
	if hunger_wert < 0.25:  # RUECKFALL-Farbstufen, echte Werte in mood_modifikatoren.json
		return Color(0.2, 0.8, 0.2, 1.0)  # Grün - gut genährt
	elif hunger_wert < 0.5:  # RUECKFALL
		return Color(0.9, 0.8, 0.2, 1.0)  # Gelb - hungrig
	elif hunger_wert < 0.75:  # RUECKFALL
		return Color(1.0, 0.5, 0.1, 1.0)  # Orange - sehr hungrig
	else:
		return Color(0.9, 0.1, 0.1, 1.0)  # Rot - verhungert  # RUECKFALL

func waerme_farbe(waerme_wert: float) -> Color:
	if waerme_wert < -0.2:  # RUECKFALL
		return Color(0.4, 0.6, 1.0, 1.0)  # Blau - kalt
	elif waerme_wert < 0.2:  # RUECKFALL
		return Color(0.6, 0.8, 0.4, 1.0)  # Grünlich - angenehm
	elif waerme_wert < 0.6:  # RUECKFALL-Schwelle für UI-Farbstufen, echte Schwellen in mood_modifikatoren.json
		return Color(1.0, 0.7, 0.2, 1.0)  # Orange - warm
	else:
		return Color(1.0, 0.3, 0.1, 1.0)  # Rot - heiß
