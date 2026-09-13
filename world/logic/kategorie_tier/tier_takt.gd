extends RefCounted
class_name Tier_Takt
## Ein Takt der Tiere: Er ordnet zuerst das Wach-Sein über den Sicht-Wächter,
## tickt dann jeden Eintrag — schlafend als reine Logik, wach mit Darsteller —
## und trägt zum Schluss die erloschenen Einträge aus. Inaktive Karten ticken
## nur jedes sechste Frame.

const KARTEN_GATE := 6

var _mgr: Tier_Manager = null

func _init(mgr: Tier_Manager) -> void:
	_mgr = mgr

func tick(_nummer: int, delta: float) -> void:
	## 1/6 Tick-Gate: Inaktive Karten ticken nur jedes 6. Frame.
	if not _eigene_karte_aktiv():
		return
	# Der Wächter ordnet das Wach-Sein: Wecken im Blick mit Budget,
	# Einschlafen außerhalb, Geister und Ernte-Ausblendungen zum Austrag.
	var entfernte := _mgr._waechter.wachen_und_schlafen(_mgr._tiere, _mgr._darsteller_erzeugen)
	for tier: Dictionary in _mgr._tiere:
		var darsteller_knoten: Variant = tier.get("darsteller")
		if darsteller_knoten == null:
			# Schlafend: Der Logik-Eintrag tickt ohne Node weiter.
			var schlaf_status: Tier_Status = tier["status"]
			schlaf_status.tick(delta, tier["position"], _mgr._spieler_position)
			continue
		if not is_instance_valid(darsteller_knoten):
			continue
		var darsteller := darsteller_knoten as Tier_Darsteller
		var status: Tier_Status = tier["status"]
		var bewegung := status.tick(delta, tier["position"], _mgr._spieler_position)
		if bewegung != Vector2.ZERO:
			tier["position"] = tier["position"] + bewegung
			darsteller.global_position = tier["position"]
	# Von hinten austragen: Das Entfernen verschiebt alle folgenden Indizes,
	# ein Lauf von vorne würde bei mehreren Treffern die falschen Tiere löschen.
	entfernte.reverse()
	for index in entfernte:
		_mgr._tiere.remove_at(index)

func _eigene_karte_aktiv() -> bool:
	if _mgr._welt_world == null or _mgr._model == null:
		return true
	var aktive_map_id := _mgr._welt_world.aktive_map_id()
	if aktive_map_id != "" and aktive_map_id != _mgr._model.map_id:
		return Engine.get_process_frames() % KARTEN_GATE == 0
	return true
