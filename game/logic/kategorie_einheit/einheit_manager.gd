extends Node2D
class_name Einheit_Manager
## Verwaltung aller Strichmännchen-Einheiten im Takt der globalen Weltuhr.
## Die Einheiten bewegen sich nie selbst: Positionen legt der Spieler fest.
## Der Manager setzt Jobs ein, prüft, ob das Ziel noch existiert, und leitet
## Ernteergebnisse an die Ressourcenverwaltung weiter.

## Kategorie daten: Einheiten-Liste mit Status, Darsteller und Position.
var _einheiten: Array[Dictionary] = []

## Kategorie logik: Registries und Verbindungen zu anderen Domänen.
var _job_registry := Job_Registry.new()
var _need_registry := Pop_NeedRegistry.new()
var _mood_mod_registry := Pop_MoodModifikatorRegistry.new()
var _waerme_feld: Welt_WaermeFeld = Welt_WaermeFeld.new()
var _tageszyklus: Welt_TageszyklusMaschine = Welt_TageszyklusMaschine.new()
var _zufall := Kern_Zufall.new()
var _nahrung_je_einheit_je_takt: float = 0.8
var _model: Welt_Model = null
var _tiere: Tier_Manager = null
var _ressourcen: Einheit_Ressourcen = null
var _lager: Lager_Manager = null
var _need_baum: Pop_NeedBaum = null

func _enter_tree() -> void:
	# Die Weltuhr wird zur Laufzeit aufgelöst statt über den Autoload-Namen,
	# damit der Manager auch in Headless-Testläufen ohne Autoloads ladbar
	# bleibt. Im Spiel ist es dieselbe zentrale Uhr aus project.godot.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func einrichten(model: Welt_Model, tiere: Tier_Manager, ressourcen: Einheit_Ressourcen) -> void:
	_model = model
	_tiere = tiere
	_ressourcen = ressourcen

func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager
	for einheit: Dictionary in _einheiten:
		var m: Pop_MoodMaschine = einheit["mood"]
		m.einrichten(_need_registry, _lager)
		m.waerme_und_zyklus_setzen(_waerme_feld, _tageszyklus, _mood_mod_registry)

func need_baum_setzen(baum: Pop_NeedBaum) -> void:
	# Der eigene Need-Tree erzeugt und besitzt die Mood-Maschinen als Kinder;
	# der Manager greift nur noch über Referenzen zu.
	_need_baum = baum

func waerme_quellen_aktualisieren(feuer_positionen: Array[Vector2]) -> void:
	_waerme_feld.quellen_setzen(feuer_positionen, 5, 1.0)

func tageszyklus_setzen(zyklus: Welt_TageszyklusMaschine) -> void:
	_tageszyklus = zyklus
	for einheit: Dictionary in _einheiten:
		(einheit["mood"] as Pop_MoodMaschine).waerme_und_zyklus_setzen(_waerme_feld, _tageszyklus, _mood_mod_registry)

func verteilung_setzen(nahrung_je_takt: float) -> void:
	_nahrung_je_einheit_je_takt = clampf(nahrung_je_takt, 0.1, 5.0)

func einheit_hinzufuegen(welt_position: Vector2, rasse_id: String = "") -> void:
	var status := Einheit_Status.new()
	status.welt_position_setzen(welt_position)
	var darsteller := Einheit_Darsteller.new()
	darsteller.einrichten(status)
	darsteller.position = welt_position
	darsteller.animation_setzen(status.animation())
	var rasse := rasse_id
	if rasse == "":
		# Ohne Wunsch gilt die Standard-Rasse des Need-Baums; ohne Baum bleibt
		# der neutrale Mensch als Fallback für Testläufe.
		rasse = _need_baum.standard_rasse() if _need_baum != null else "mensch"
	var mood: Pop_MoodMaschine = null
	if _need_baum != null:
		mood = _need_baum.einheit_need_anlegen(rasse, welt_position)
	else:
		# Fallback ohne Baum: Maschine bleibt ohne Parent, damit Testläufe
		# ohne Szenenbaum weiterhin laufen.
		mood = Pop_MoodMaschine.new()
		mood.einrichten(_need_registry, _lager)
		mood.welt_position_setzen(welt_position)
	mood.waerme_und_zyklus_setzen(_waerme_feld, _tageszyklus, _mood_mod_registry)
	status.rasse_faktor_setzen(mood.bewegungs_faktor())
	var denkblase := Pop_Denkblase.new()
	denkblase.einrichten(mood)
	darsteller.add_child(denkblase)
	add_child(darsteller)
	status.zustand_geaendert.connect(_auf_zustand_geaendert.bind(status, mood))
	status.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	status.job_loop_gefragt.connect(_auf_job_loop_gefragt.bind(status))
	status.naechster_job_aus_queue.connect(_auf_naechster_job_aus_queue.bind(status))
	_einheiten.append({
		"status": status,
		"darsteller": darsteller,
		"mood": mood,
		"denkblase": denkblase,
		"position": welt_position,
		"rasse": rasse,
		"_letzter_zustand": status.zustand,
	})

func einheit_zahl() -> int:
	return _einheiten.size()

func einheit_position(index: int) -> Vector2:
	if index < 0 or index >= _einheiten.size():
		return Vector2.ZERO
	var status: Einheit_Status = _einheiten[index]["status"]
	if status != null:
		return status.welt_position
	return _einheiten[index]["position"]

func einheit_position_setzen(index: int, welt_position: Vector2) -> void:
	# Bewegung kommt vom Spieler oder aus dem GEHEN-Zustand der Maschine;
	# beide Wege schreiben über dieselbe Schnittstelle.
	if index < 0 or index >= _einheiten.size():
		return
	_einheiten[index]["position"] = welt_position
	var status_pos: Einheit_Status = _einheiten[index]["status"]
	if status_pos != null:
		status_pos.welt_position_setzen(welt_position)
	var darsteller: Einheit_Darsteller = _einheiten[index]["darsteller"]
	darsteller.position = welt_position
	var mood_pos: Pop_MoodMaschine = _einheiten[index]["mood"]
	mood_pos.welt_position_setzen(welt_position)

func job_vergeben(einheit_index: int, job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ziel_position: Vector2) -> bool:
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return false
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	var job := _job_registry.job_erzeugen(job_id)
	if job == null:
		return false
	var ressource := job.ressource()
	if status.zustand == Einheit_Status.Zustand.ARBEITEN or status.zustand == Einheit_Status.Zustand.GEHEN:
		# Beschäftigt: Auftrag wird an die eigene Queue der Einheit gehängt;
		# der Job wird erst beim Start über die Registry erzeugt.
		status.job_vormerken(job_id, ziel_typ, ziel_index, ressource)
		return true
	status.geh_ziel_setzen(ziel_position)
	status.job_vergeben(job, ziel_typ, ziel_index, ressource)
	# Die Blickrichtung zeigt zum gewählten Job-Objekt.
	status.blick_richtung_setzen(ziel_position.x >= einheit_position(einheit_index).x)
	var darsteller: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())
	darsteller.flip_h = not status.blick_richtung_rechts()
	return true

func job_id_einheit(einheit_index: int) -> String:
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return ""
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	if status.job == null:
		return ""
	return status.job.job_id

func einheit_job_abbrechen(einheit_index: int) -> void:
	# Der Spieler bricht den Job ab; die Einheit fällt zurück in den Idle.
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	status.job_abbrechen()
	var darsteller: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())

func _auf_tick(nummer: int, delta: float) -> void:
	if _tageszyklus != null:
		_tageszyklus.tick()
	var takt_ticks := Kern_Weltuhr.ticks_aus_faktor(6.0 * 60.0 / 10.0)
	var verbrauch_faellig := takt_ticks > 0 and nummer % takt_ticks == 0 and nummer != 0
	if verbrauch_faellig:
		_nahrung_verteilen()
	for einheit: Dictionary in _einheiten:
		var status: Einheit_Status = einheit["status"]
		var mood: Pop_MoodMaschine = einheit["mood"]
		if (status.zustand == Einheit_Status.Zustand.ARBEITEN or status.zustand == Einheit_Status.Zustand.GEHEN) and not _ziel_existiert(status):
			# Ziel wurde in der Zwischenzeit entfernt: Job endet.
			status.job_abbrechen()
			var darsteller: Einheit_Darsteller = einheit["darsteller"]
			darsteller.animation_setzen(status.animation())
			continue
		status.tick(delta)
		if status.welt_position != einheit["position"]:
			# Bewegung hat direkte Auswirkung: Position, Darsteller und Mood
			# folgen auch im Ankunfts-Tick, wenn der Zustand schon wechselt.
			einheit["position"] = status.welt_position
			var darsteller_g: Einheit_Darsteller = einheit["darsteller"]
			darsteller_g.position = status.welt_position
			darsteller_g.animation_setzen(status.animation())
			darsteller_g.flip_h = not status.blick_richtung_rechts()
			mood.welt_position_setzen(status.welt_position)
		var ziel := mood.auf_tick(nummer, delta)
		var w := mood.waerme_wert()
		(status.vital as Einheit_VitalStatus).umgebungsschaden_anwenden(w, _mood_mod_registry, _zufall)
		if ziel != Vector2.INF and status.zustand == Einheit_Status.Zustand.IDLE:
			_in_sicherheit_bringen(einheit, ziel)

func _ziel_position_fuer(ziel_typ: Job_Basis.ZielTyp, ziel_index: int) -> Vector2:
	# Zielposition für die Bewegung: Objekte liegen im Modell, Tiere im
	# Tier-Manager. Ohne Treffer bleibt der Punkt unverändert.
	match ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model != null and ziel_index >= 0 and ziel_index < _model.objekt_anzahl():
				return _model.objekt_position(ziel_index)
		Job_Basis.ZielTyp.TIER:
			if _tiere != null:
				var tier_pos := _tiere.tier_position(ziel_index)
				if tier_pos != Vector2.INF:
					return tier_pos
	return Vector2.ZERO

func _ziel_existiert(status: Einheit_Status) -> bool:
	if status.job == null:
		return false
	match status.aktuelles_ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model == null:
				return false
			return status.aktuelles_ziel_index < _model.objekt_anzahl()
		Job_Basis.ZielTyp.TIER:
			if _tiere == null:
				return false
			return _tiere.tier_position(status.aktuelles_ziel_index) != Vector2.INF
	return false

func _naechstes_objekt(status: Einheit_Status, alter_ziel_index: int) -> int:
	if _model == null or status.job == null:
		return -1
	var anzahl := _model.objekt_anzahl()
	if anzahl == 0:
		return -1
	for schritt in anzahl:
		var pruef_index := (alter_ziel_index + 1 + schritt) % anzahl
		if pruef_index == alter_ziel_index:
			continue
		var element_id := _model.objekt_element_id(pruef_index)
		if status.job.passt_zu_objekt(element_id):
			return pruef_index
	return -1

func _naechstes_tier(status: Einheit_Status, alter_ziel_index: int) -> int:
	if _tiere == null or status.job == null:
		return -1
	var anzahl := _tiere.tier_zahl()
	if anzahl == 0:
		return -1
	for schritt in anzahl:
		var pruef_index := (alter_ziel_index + 1 + schritt) % anzahl
		if pruef_index == alter_ziel_index:
			continue
		if _tiere.tier_position(pruef_index) == Vector2.INF:
			continue
		var tier_art := _tiere.tier_art(pruef_index)
		if status.job.passt_zu_tier(tier_art):
			return pruef_index
	return -1

## Leerlauf und Wachstum: ein Haus aus 3 Nahrung erzeugt einen neuen Stickman.

func versuche_wachstum(haus_welt_position: Vector2) -> bool:
	if _ressourcen == null:
		return false
	_ressourcen.ernte_position_setzen(haus_welt_position)
	if not _ressourcen.entnehmen("fleisch", 3):
		return false
	einheit_hinzufuegen(haus_welt_position + Vector2(0, 20))
	return true

func _auf_naechster_job_aus_queue(_job_id: String, _ziel_typ: Job_Basis.ZielTyp, _ziel_index: int, _ressource: String, status: Einheit_Status) -> void:
	# Die eigene Queue der Einheit startet den nächsten Auftrag: Der Manager
	# erzeugt den Job frisch über die Registry und entfernt die Vormerkung.
	if status.zustand != Einheit_Status.Zustand.IDLE:
		return
	var eintrag := status.queue_naechster()
	if eintrag.is_empty():
		return
	var job := _job_registry.job_erzeugen(str(eintrag.get("job_id", "")))
	if job == null:
		status.queue_vorne_entfernen()
		return
	status.queue_vorne_entfernen()
	status.geh_ziel_setzen(_ziel_position_fuer(int(eintrag.get("ziel_typ", 0)), int(eintrag.get("ziel_index", -1))))
	status.job_vergeben(job, int(eintrag.get("ziel_typ", 0)),
		int(eintrag.get("ziel_index", -1)), str(eintrag.get("ressource", "")))

func _auf_job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int, status: Einheit_Status) -> void:
	# Die Schleife endet nie hart im Idle: Der Manager sucht das naechste
	# gueltige Ziel desselben Typs und setzt den Job direkt neu. Der Status
	# haengt ueber bind() am Ende der Signal-Argumente, der Job kommt zuerst.
	if job == null or status.job != job or _ressourcen == null:
		return
	var such_index := -1
	match ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model != null:
				such_index = _naechstes_objekt(status, alter_ziel_index)
		Job_Basis.ZielTyp.TIER:
			if _tiere != null:
				such_index = _naechstes_tier(status, alter_ziel_index)
	if such_index < 0:
		return
	status.geh_ziel_setzen(_ziel_position_fuer(ziel_typ, such_index))
	status.job_loopy_fortsetzen(job, ziel_typ, such_index, job.ressource())

func _auf_arbeitsschritt(ressource: String, menge: int) -> void:
	# Ein Arbeitsschritt ist fertig; je nach Job-Typ wird geerntet.
	if _ressourcen == null:
		return
	for einheit: Dictionary in _einheiten:
		var status: Einheit_Status = einheit["status"]
		if status.zustand != Einheit_Status.Zustand.ARBEITEN or status.ziel_ressource != ressource:
			continue
		var ernte_position := Vector2.ZERO
		match status.aktuelles_ziel_typ:
			Job_Basis.ZielTyp.OBJEKT:
				if _model != null and status.aktuelles_ziel_index >= 0 and status.aktuelles_ziel_index < _model.objekt_anzahl():
					ernte_position = _model.objekt_position(status.aktuelles_ziel_index)
			Job_Basis.ZielTyp.TIER:
				if _tiere != null:
					ernte_position = _tiere.tier_position(status.aktuelles_ziel_index)
		_ressourcen.ernte_position_setzen(ernte_position)
		match status.aktuelles_ziel_typ:
			Job_Basis.ZielTyp.OBJEKT:
				# Bäume und Steine liefern ihre Ernte ins naechste lokale Lager.
				_ressourcen.hinzufuegen(ressource, menge)
			Job_Basis.ZielTyp.TIER:
				# Jagen: erst mit jedem Schlag verletzen, ernten, wenn das Tier tot ist.
				_jagd_schlag(status, menge)

func _jagd_schlag(status: Einheit_Status, schaden: int) -> void:
	# Jeder Schlag verletzt das Tier; erst beim Tod fällt die Beute an.
	if _tiere == null or _ressourcen == null:
		return
	if _tiere.tier_angreifen(status.aktuelles_ziel_index, schaden):
		_tier_ernten(status)

func _tier_ernten(status: Einheit_Status) -> void:
	if _tiere == null or _ressourcen == null:
		return
	var fleisch := _tiere.tier_ernten(status.aktuelles_ziel_index)
	if fleisch > 0:
		var ernte_position := Vector2.ZERO
		if _tiere != null:
			ernte_position = _tiere.tier_position(status.aktuelles_ziel_index)
		_ressourcen.ernte_position_setzen(ernte_position)
		_ressourcen.hinzufuegen("fleisch", fleisch)
	# Erlegte Beute ist verbraucht: der Job endet.
	status.job_abbrechen()
	for einheit: Dictionary in _einheiten:
		if einheit["status"] == status:
			(einheit["darsteller"] as Einheit_Darsteller).animation_setzen(status.animation())

func _auf_zustand_geaendert(_neu: int, status: Einheit_Status, mood: Pop_MoodMaschine) -> void:
	var vorher: int = 0
	for einheit: Dictionary in _einheiten:
		if einheit["status"] == status:
			vorher = int(einheit.get("_letzter_zustand", 0))
			einheit["_letzter_zustand"] = status.zustand
			break
	var von_str := "idle" if vorher == Einheit_Status.Zustand.IDLE else "arbeiten"
	var nach_str := "idle" if status.zustand == Einheit_Status.Zustand.IDLE else "arbeiten"
	var job_id := status.job.job_id if status.job != null else ""
	mood.auf_jobwechsel(von_str, nach_str, job_id)

func transport_fuer_idle(einheit_index: int, _freies_lager: Lager_Manager) -> bool:
	# Das Lager wird in der Transportkette des Status gezogen; der Manager
	# braucht es hier nicht, der Parameter bleibt als Vertrag erhalten und
	# trägt einen eigenen Namen, damit das Klassenfeld _lager nicht verschattet wird.
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return false
	var mood: Pop_MoodMaschine = _einheiten[einheit_index]["mood"]
	mood.auf_jobwechsel("idle", "transport", "transport")
	return true

func _in_sicherheit_bringen(einheit: Dictionary, ziel: Vector2) -> void:
	# Progression-Gate: Wärme triggert in_sicherheit_bringen am Gate.
	einheit["position"] = ziel
	(einheit["darsteller"] as Einheit_Darsteller).position = ziel
	(einheit["mood"] as Pop_MoodMaschine).welt_position_setzen(ziel)
	(einheit["status"] as Einheit_Status).welt_position_setzen(ziel)

func _nahrung_verteilen() -> void:
	if _ressourcen == null or _lager == null:
		return
	# Rassen-Schemata: Jede Einheit verbraucht ihren eigenen Rassen-Faktor
	# mal den zentralen Need-Faktor, geliefert von ihrer Mood-Maschine.
	var gesamt := 0
	for einheit: Dictionary in _einheiten:
		var m: Pop_MoodMaschine = einheit["mood"]
		gesamt += int(ceil(_nahrung_je_einheit_je_takt * m.nahrungs_faktor()))
	if gesamt <= 0:
		return
	if not _ressourcen.entnehmen("fleisch", gesamt):
		for einheit: Dictionary in _einheiten:
			var st: Einheit_Status = einheit["status"]
			st.vital.schaden_nehmen(5, _zufall, "hunger")
