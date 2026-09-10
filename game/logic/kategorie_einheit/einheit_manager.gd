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
var _tageszyklus: Welt_TageszyklusMaschine = null
var _zufall := Kern_Zufall.new()
var _model: Welt_Model = null
var _tiere: Tier_Manager = null
var _ressourcen: Einheit_Ressourcen = null
var _lager: Lager_Manager = null
var _need_baum: Pop_NeedBaum = null
var _weg_planung: Einheit_WegPlanung = null
var _ziel_suche: Einheit_ZielSuche = null
var _ernte: Einheit_ErnteMaschine = null
var _versorgung: Einheit_Versorgung = null

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
	_weg_planung_erneuern()
	_ziel_suche = Einheit_ZielSuche.new()
	_ziel_suche.einrichten(model, tiere)
	_ernte = Einheit_ErnteMaschine.new()
	_ernte.einrichten(ressourcen, model, tiere)
	_ernte.beute_erlegt.connect(_auf_beute_erlegt)
	_versorgung = Einheit_Versorgung.new()
	_versorgung.einrichten(ressourcen)

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

func _weg_planung_erneuern() -> void:
	# Die Wegplanung ist eine geteilte Maschine des Managers: Ein Netz für
	# alle Einheiten, der Weg-Cache macht den A-Stern bezahlbar.
	if _weg_planung == null:
		_weg_planung = Einheit_WegPlanung.new()
	_weg_planung.netz_erneuern(_model)

func _planner_fuer(status: Einheit_Status, ziel_position: Vector2) -> void:
	if _weg_planung == null:
		return
	status.weg_ziele_uebernehmen(_weg_planung.weg_zu(status.welt_position, ziel_position))

func verteilung_setzen(nahrung_je_takt: float) -> void:
	# Die Regel gehört der Versorgungs-Maschine; der Manager reicht nur durch.
	_versorgung.verteilung_setzen(nahrung_je_takt)

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

## Geschlossener Schnittpunkt: Nur diese Leseschnittstellen duerfen Einheiten
## lesen. Direkter Zugriff auf _einheiten bleibt der Manager-Interna.
func einheit_status(index: int) -> Einheit_Status:
	if index < 0 or index >= _einheiten.size():
		return null
	return _einheiten[index]["status"] as Einheit_Status

func einheit_rasse(index: int) -> String:
	if index < 0 or index >= _einheiten.size():
		return ""
	return str(_einheiten[index].get("rasse", ""))

func einheit_vital(index: int) -> Einheit_VitalStatus:
	var st := einheit_status(index)
	if st == null:
		return null
	return st.vital

func einheit_beschreibung(index: int) -> Dictionary:
	# Schlanker Snapshot fuer Observer: alles, was ein Fenster braucht,
	# ohne die Interna preiszugeben.
	if index < 0 or index >= _einheiten.size():
		return {}
	var st := einheit_status(index)
	if st == null:
		return {}
	var hp := 0.0
	if st.vital != null:
		hp = st.vital.hp
	var job_id := ""
	if st.job != null:
		job_id = st.job.job_id
	return {
		"position": st.welt_position,
		"rasse": einheit_rasse(index),
		"zustand": st.zustand,
		"job_id": job_id,
		"ziel_index": st.aktuelles_ziel_index,
		"hp": hp,
		"queue": st.queue_laenge(),
	}

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
	_planner_fuer(status, ziel_position)
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
	# Der Tageszyklus tickt nicht mehr hier: Die Weltmaschine hängt seit
	# der Besitzkorrektur direkt an der Weltuhr und lebt nicht mehr in
	# der Einheiten-Domäne. Dieser Takt kennt nur Einheiten-Arbeit.
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
	return _ziel_suche.ziel_position_fuer(ziel_typ, ziel_index)

func _ziel_existiert(status: Einheit_Status) -> bool:
	return _ziel_suche.ziel_existiert(status)

func _naechstes_objekt(status: Einheit_Status, alter_ziel_index: int) -> int:
	return _ziel_suche.naechstes_objekt(status, alter_ziel_index)

func _naechstes_tier(status: Einheit_Status, alter_ziel_index: int) -> int:
	return _ziel_suche.naechstes_tier(status, alter_ziel_index)

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
	var ziel_position := _ziel_position_fuer(int(eintrag.get("ziel_typ", 0)), int(eintrag.get("ziel_index", -1)))
	status.geh_ziel_setzen(ziel_position)
	_planner_fuer(status, ziel_position)
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
	var ziel_position := _ziel_position_fuer(ziel_typ, such_index)
	status.geh_ziel_setzen(ziel_position)
	_planner_fuer(status, ziel_position)
	status.job_loopy_fortsetzen(job, ziel_typ, such_index, job.ressource())

func _auf_arbeitsschritt(ressource: String, menge: int) -> void:
	# Ein Arbeitsschritt ist fertig; die Ernte-Maschine verarbeitet ihn.
	if _ernte == null:
		return
	for einheit: Dictionary in _einheiten:
		_ernte.arbeitsschritt_verarbeiten(ressource, menge, einheit["status"])

func _auf_beute_erlegt(status: Einheit_Status) -> void:
	# Beute gefallen: Die Darstellung der Einheit folgt dem Job-Ende.
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
	# Die Versorgungs-Maschine besitzt die Regel; der Manager nur den Takt.
	if _versorgung != null:
		_versorgung.verteilen(_einheiten)
