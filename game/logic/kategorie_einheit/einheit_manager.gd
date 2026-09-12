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
var _fortschritt: Welt_FortschrittsMaschine = null

var _schlag_ort_empfaenger: Callable = Callable()
var _schlag_empfaenger: Callable = Callable()

func _ready() -> void:
	y_sort_enabled = true

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
	_ziel_suche.einheiten_quelle_setzen(self)
	_ernte = Einheit_ErnteMaschine.new()
	_ernte.einrichten(ressourcen, model, tiere)
	_ernte.zufall_setzen(_zufall)
	_ernte.manager_setzen(self)
	_ernte.beute_erlegt.connect(_auf_beute_erlegt)
	# Rein optisch: Jeder Ernteschlag meldet seinen Ort, die Atmosphaeren-
	# Domaene zeigt dort Staub. Der Manager reicht nur durch.
	_ernte.schlag_ort_gemeldet.connect(_auf_schlag_ort)
	_ernte.schlag_objekt_gemeldet.connect(_auf_schlag_objekt)
	_versorgung = Einheit_Versorgung.new()
	_versorgung.einrichten(ressourcen)
	# Verbrauchs-Vorgabe aus dem Datenpool: Der Wert aus needs.json gilt, bis
	# der Spieler im Verteilungs-Fenster etwas anderes setzt.
	_versorgung.verteilung_setzen(_need_registry.verbrauch_je_takt())

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
	# Die Kachelkante kommt aus dem Modell (eine Quelle), der Rest aus dem
	# Feuer-Eintrag in element_katalog.json ueber den Waermesammler-Aufruf.
	if _model != null:
		_waerme_feld.kachel_groesse_setzen(_model.kachel_groesse)
	_waerme_feld.quellen_setzen(feuer_positionen, 5, 1.0)

func fortschritt_setzen(maschine: Welt_FortschrittsMaschine) -> void:
	_fortschritt = maschine

## Autonomes Verhalten: Der hungergetriebene Kannibalismus ist die erste
## Verbraucherin der Eskalationsketten. Der Verzweifelte jagt den
## schwächsten Nachbarn, wenn weder ein jagdbares Tier in Reichweite noch
## Fleisch im Lager ist. Vor dem ersten Lagerfeuer ist die Siedlung allein,
## die Opfersuche bleibt leer, und mit der Einwanderung aus der
## Einstiegs-Kette gibt es erstmals Nachbarn. Der Auslöser sitzt am eigenen
## Idle, der Job läuft wie jede Jagd über dieselben Maschinen.
## Slice C: Performance-Cache für den teuren Tier- und Nachbarschafts-Scan.
var _tier_reichweite_cache: Dictionary = {}
var _tier_cache_tick: int = -1

func _pruefe_verhalten(einheit: Dictionary, index: int) -> void:
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
	job_vergeben(index, "kannibale", Job_Basis.ZielTyp.OWN, opfer, einheit_position(opfer))
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
	var eigene := einheit_position(jaeger_index)
	var bester := -1
	var beste_hp := 0
	for index in _einheiten.size():
		if index == jaeger_index:
			continue
		if einheit_status(index).vital.hp <= 0:
			continue
		if einheit_position(index).distance_to(eigene) > reichweite:
			continue
		var hp := einheit_hp(index)
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
	var eigene := einheit_position(jaeger_index)
	var treffer := false
	for tier_index in _tiere.tier_zahl():
		var tier_pos := _tiere.tier_position(tier_index)
		if tier_pos != Vector2.INF and tier_pos.distance_to(eigene) <= 160.0:
			treffer = true
			break
	_tier_reichweite_cache[jaeger_index] = treffer
	return treffer


func schlag_ort_empfaenger_setzen(empfaenger: Callable) -> void:
	# Die Welt-Szene reicht die Atmosphaeren-Spitze herein; der Manager
	# kennt die Domäne nicht, nur den Aufruf staub_zeigen(position).
	_schlag_ort_empfaenger = empfaenger

func schlag_empfaenger_setzen(empfaenger: Callable) -> void:
	# Die Progressions-Domäne meldet sich als Empfänger für jeden echten
	# Arbeitsschlag; der Manager kennt nur den Aufruf schlag(index).
	_schlag_empfaenger = empfaenger

func _auf_schlag_ort(welt_position: Vector2) -> void:
	if _schlag_ort_empfaenger.is_valid():
		_schlag_ort_empfaenger.call(welt_position)

func _auf_schlag_objekt(ziel_index: int) -> void:
	if _schlag_empfaenger.is_valid():
		_schlag_empfaenger.call(ziel_index)

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

func verteilung_wert() -> float:
	# Lesender Zugriff für das Verteilungs-Fenster: Der Startwert des Reglers
	# ist der aktuell geltende Verbrauch, nicht eine zweite Zahl im UI.
	return _versorgung.verbrauch_je_takt()

## Spielrhythmus aus dem Datenpool, gelesen über die Need-Registry; dieselbe
## Quelle speist auch den Tageszyklus in der Welt-Szene.
func takt_minuten() -> float:
	return _need_registry.takt_minuten()

func tag_minuten() -> float:
	return _need_registry.tag_minuten()

func nacht_minuten() -> float:
	return _need_registry.nacht_minuten()

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
	status.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt.bind(status))
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

func einheit_bei(welt_position: Vector2, radius: float) -> int:
	## Linksklick-Einheitenwahl: Liefert den Index der nächsten Einheit
	## innerhalb von radius Pixeln um welt_position, sonst -1.
	var bester := -1
	var beste_distanz := radius + 1.0
	for idx in _einheiten.size():
		var status: Einheit_Status = _einheiten[idx]["status"]
		if status == null:
			continue
		var distanz := status.welt_position.distance_to(welt_position)
		if distanz <= radius and distanz < beste_distanz:
			beste_distanz = distanz
			bester = idx
	return bester

func auswahl_markierung_erneuern(aktiver_index: int, auswahl_liste: Array[int] = []) -> void:
	## CP-6.1: Aktualisiert die goldene Auswahl-Markierung aller Einheiten.
	for idx in _einheiten.size():
		var darsteller: Variant = _einheiten[idx].get("darsteller")
		if darsteller != null and darsteller.has_method("markierung_setzen"):
			var ist_gewaehlt := (idx == aktiver_index) or auswahl_liste.has(idx)
			darsteller.markierung_setzen(ist_gewaehlt)

func weg_planung_aktualisieren() -> void:
	## Öffentlicher Aufruf nach Gebäudeplatzierung: Das Netz kennt das
	## neue Hindernis erst nach diesem Aufruf. Bisher war _weg_planung_erneuern
	## privat und wurde nur bei einrichten() aufgerufen.
	_weg_planung_erneuern()

func modell_wechseln(neues_modell: Welt_Model, neue_tiere: Tier_Manager) -> void:
	## Kartenwechsel-Handshake: Alle internen Modellreferenzen werden atomar
	## auf das neue Modell umgestellt. Wegnetz, Zielsuche und Ernte werden
	## neu aufgebaut, damit kein Job auf der alten Karte weiterläuft.
	_model = neues_modell
	_tiere = neue_tiere
	_weg_planung_erneuern()
	if _ziel_suche != null:
		_ziel_suche.einrichten(_model, _tiere)
		_ziel_suche.einheiten_quelle_setzen(self)
	if _ernte != null:
		_ernte.einrichten(_ressourcen, _model, _tiere)



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

func einheit_hp(index: int) -> int:
	# Lebenspunkte je Einheit für die Schwächsten-Suche des autonomen
	# Verhaltens; ohne Treffer bleibt der neutrale Wert.
	var st := einheit_status(index)
	return 0 if st == null else st.vital.hp

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
	# G1: Der effektive Faktor des Ziels skaliert die Arbeitszeit des Jobs.
	job.ziel_faktor_setzen(_ziel_suche.ziel_faktor_fuer(ziel_typ, ziel_index))
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

func einheit_bewegen_nach(einheit_index: int, ziel_position: Vector2) -> bool:
	# Spieler-Befehl: Die Einheit bricht laufende Jobs ab und marschiert zur Position.
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return false
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	if status == null:
		return false
	status.geh_befehl(ziel_position)
	_planner_fuer(status, ziel_position)
	status.blick_richtung_setzen(ziel_position.x >= einheit_position(einheit_index).x)
	var darsteller: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())
	darsteller.flip_h = not status.blick_richtung_rechts()
	return true

func _auf_tick(nummer: int, delta: float) -> void:
	# Der Tageszyklus tickt nicht mehr hier: Die Weltmaschine hängt seit
	# der Besitzkorrektur direkt an der Weltuhr und lebt nicht mehr in
	# der Einheiten-Domäne. Dieser Takt kennt nur Einheiten-Arbeit.
	# Taktdauer aus dem Datenpool: Der Wert kommt über die Need-Registry aus
	# population/data/needs.json und wird von der Weltuhr in Ticks übersetzt;
	# dieselbe Zahl steuert auch den Tageszyklus.
	if _tier_cache_tick != nummer:
		_tier_cache_tick = nummer
		_tier_reichweite_cache.clear()
	var takt_ticks := Kern_Weltuhr.ticks_aus_minuten(_need_registry.takt_minuten())
	var verbrauch_faellig := takt_ticks > 0 and nummer % takt_ticks == 0 and nummer != 0
	if verbrauch_faellig:
		_nahrung_verteilen()
		# Einwanderung: Der aktive Progressions-Zieltyp einwanderung liefert
		# die Rate (einwanderer_je_tag), der Takt kommt aus dem Datenpool;
		# der Spawn läuft über denselben einheit_hinzufuegen-Schnitt.
		_einwanderung_ticken(takt_ticks)
	for ei: int in _einheiten.size():
		var einheit: Dictionary = _einheiten[ei]
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
		# Slice C: Verhaltensprüfung auf 12 Ticks gestreut verteilen (0.5s Reaktionszeit)
		if status.zustand == Einheit_Status.Zustand.IDLE and (nummer % 12 == (ei % 12)):
			_pruefe_verhalten(einheit, ei)


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

## Einwanderung: Die Einstiegs-Kette macht aus dem Wachstum eine automatische
## Kette. Die Rate steht menschenlesbar in progression.json je Stufe; ohne
## aktive einwanderung-Stufe kommt niemand. Der Ankömmling meldet sich an
## die Maschine zurück, damit die Stufe weiterzählt.
func _einwanderung_ticken(_takt_ticks: int) -> void:
	## Einwanderung: Pro Verbrauchstakt erscheint je_tag Einwanderer direkt,
	## sofern die aktive Progressions-Stufe den Typ einwanderung trägt.
	## Der frühere _einwanderer_takt-Zähler verdoppelte die Wartezeit auf
	## takt_ticks² und ist entfernt worden.
	if _fortschritt == null:
		return
	var stufe := _fortschritt.aktive_stufe()
	if str(stufe.get("ziel_typ", "")) != "einwanderung":
		return
	var je_tag := int(stufe.get("einwanderer_je_tag", 0))
	for _i: int in je_tag:
		einheit_hinzufuegen(lager_anker_position() + Vector2(24, 20))
		_fortschritt.einwanderer_angekommen()


func lager_anker_position() -> Vector2:
	# Der erste Lagerpunkt ist der Anker der Einwanderung (Lagerfeuer oder
	# erstes Haus); ohne Lager bleibt der Ursprung.
	if _lager != null and _lager.lager_zahl() > 0:
		return _lager.lager_position(0)
	return Vector2.ZERO

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
	var ziel_typ := int(eintrag.get("ziel_typ", 0)) as Job_Basis.ZielTyp
	var ziel_index := int(eintrag.get("ziel_index", -1))
	# G1: Auch aus der Queue startet der Job mit dem Faktor seines Ziels.
	job.ziel_faktor_setzen(_ziel_suche.ziel_faktor_fuer(ziel_typ, ziel_index))
	var ziel_position := _ziel_position_fuer(int(eintrag.get("ziel_typ", 0)), ziel_index)
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
	# G1: Das neue Loop-Ziel bringt seinen eigenen Faktor mit.
	job.ziel_faktor_setzen(_ziel_suche.ziel_faktor_fuer(ziel_typ, such_index))
	status.job_loopy_fortsetzen(job, ziel_typ, such_index, job.ressource())

func _auf_arbeitsschritt(ressource: String, menge: int, status: Einheit_Status) -> void:
	# Ein Arbeitsschritt ist fertig; die Ernte-Maschine verarbeitet ihn.
	# Nur der Status, der den Schritt geschafft hat, bucht seine Ernte:
	# Der frühere Sammel-Lauf über alle Einheiten war ein Doppelpfad, der
	# mit bind() auf dem Arbeitsloop-Signal zweimal die gleiche Ernte
	# angestoßen hätte. bind(status) legt den Absender fest, beide Pfade
	# landen auf demselben Empfänger und laufen exakt einmal durch.
	if _ernte == null or status == null:
		return
	_ernte.arbeitsschritt_verarbeiten(ressource, menge, status)

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
