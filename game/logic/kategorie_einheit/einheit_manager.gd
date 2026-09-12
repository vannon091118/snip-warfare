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

## Parallel-Map: Referenz auf die Welt für 1/6 Tick-Gate.
var _welt_world: Welt_World = null

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

func einrichten(model: Welt_Model, tiere: Tier_Manager, ressourcen: Einheit_Ressourcen, welt_world: Welt_World = null) -> void:
	_model = model
	_tiere = tiere
	_ressourcen = ressourcen
	_welt_world = welt_world
	_weg_planung_erneuern()
	_ziel_suche = Einheit_ZielSuche.new()
	_ziel_suche.einrichten(model, tiere)
	_ziel_suche.einheiten_quelle_setzen(self)
	_ernte = Einheit_ErnteMaschine.new()
	_ernte.einrichten(null, ressourcen, model, tiere)  # Inventar wird pro Einheit gesetzt
	_ernte.zufall_setzen(_zufall)
	_ernte.manager_setzen(self)
	_ernte.beute_erlegt.connect(_auf_beute_erlegt)
	# Rein optisch: Jeder Ernteschlag meldet seinen Ort, die Atmosphaeren-
	# Domaene zeigt dort Staub. Der Manager reicht nur durch.
	_ernte.schlag_ort_gemeldet.connect(_auf_schlag_ort)
	_ernte.schlag_objekt_gemeldet.connect(_auf_schlag_objekt)
	_ernte.inventar_voll.connect(_auf_inventar_voll)
	_trupp.einrichten(_einheiten)
	_trupp.job_registry_setzen(_job_registry)
	_trupp.weg_planer_setzen(_planner_fuer)
	_job_fluss.einrichten(_trupp, _job_registry, _ziel_suche, _ernte, _planner_fuer)
	_versorgung = Einheit_Versorgung.new()
	_versorgung.einrichten(ressourcen)
	# Verbrauchs-Vorgabe aus dem Datenpool: Der Wert aus needs.json gilt, bis
	# der Spieler im Verteilungs-Fenster etwas anderes setzt.
	_versorgung.verteilung_setzen(_need_registry.verbrauch_je_takt())
	# Die zwei Regel-Maschinen des Managers: Verhalten (Kannibalismus-Auslöser)
	# und Versorgung (Wachstum und Einwanderung) tragen ihre Rechnung selbst.
	_versorgung_neu.einrichten({
		"manager": self,
		"ressourcen": _ressourcen,
		"fortschritt": null,
	})
	_verhalten.einrichten({
		"manager": self,
		"mood_mod_registry": _mood_mod_registry,
		"job_registry": _job_registry,
		"ressourcen": _ressourcen,
		"tiere": _tiere,
	})
	_einwanderung.einrichten(_einwanderungs_kontext())
	_takt.einrichten(_takt_kontext())

func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager
	_trupp.lager_setzen(lager)
	_job_fluss.lager_setzen(lager)
	_einwanderung.einrichten(_einwanderungs_kontext())
	for einheit: Dictionary in _einheiten:
		var m: Pop_MoodMaschine = einheit["mood"]
		m.einrichten(_need_registry, _lager)
		m.waerme_und_zyklus_setzen(_waerme_feld, _tageszyklus, _mood_mod_registry)

func need_baum_setzen(baum: Pop_NeedBaum) -> void:
	# Der eigene Need-Tree erzeugt und besitzt die Mood-Maschinen als Kinder;
	# der Manager greift nur noch über Referenzen zu.
	_need_baum = baum
	_einwanderung.einrichten(_einwanderungs_kontext())

func waerme_quellen_aktualisieren(feuer_positionen: Array[Vector2]) -> void:
	# Die Kachelkante kommt aus dem Modell (eine Quelle), der Rest aus dem
	# Feuer-Eintrag in element_katalog.json ueber den Waermesammler-Aufruf.
	if _model != null:
		_waerme_feld.kachel_groesse_setzen(_model.kachel_groesse)
	_waerme_feld.quellen_setzen(feuer_positionen, 5, 1.0)

func fortschritt_setzen(maschine: Welt_FortschrittsMaschine) -> void:
	_fortschritt = maschine
	_versorgung_neu.einrichten({
		"manager": self,
		"ressourcen": _ressourcen,
		"fortschritt": _fortschritt,
	})

## Autonomes Verhalten: Die Verhaltens-Maschine trägt den Kannibalismus-Auslöser
## und ihre Scans; der Manager reicht nur den Takt und die Einheiten durch.
var _verhalten := Einheit_VerhaltensMaschine.new()
## Wachstum und Einwanderung: Die Versorgungs-Maschine trägt die Nachschub-
## Regel, der Manager nur den Takt und den Spawn-Schnitt.
var _versorgung_neu := Einheit_VersorgungsMaschine.new()
## Job-Fluss und Trupp-Zusammenschau: Die zwei Maschinen tragen die Reaktionen
## auf den Job-Rhythmus und die Zusammenschau des Trupps; der Manager behält
## nur Knoten, Ticks und Lese-Schnittstellen.
var _job_fluss := Einheit_JobFlussMaschine.new()
var _trupp := Einheit_TruppMaschine.new()
## Einwanderung: Die Maschine traegt die Ankunft samt Status, Stimmung und Inventar.
var _einwanderung := Einheit_EinwanderungsMaschine.new()
## Takt: Die Maschine fuehrt die Einheiten-Schleife an der Weltuhr.
var _takt := Einheit_TaktMaschine.new()


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
	_einwanderung.einrichten(_einwanderungs_kontext())
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

func einheit_hinzufuegen(welt_position: Vector2, rasse_id: String = "") -> int:
	## Die Ankunft einer Einheit traegt die Einwanderungs-Maschine.
	return _einwanderung.hinzufuegen(welt_position, rasse_id)

func _einwanderungs_kontext() -> Dictionary:
	# Die Einwanderungs-Maschine bekommt genau die Quellen, die eine Ankunft
	# braucht; die Verbinder sind die Methoden dieses Managers.
	return {
		"node": self,
		"einheiten": _einheiten,
		"need_baum": _need_baum,
		"need_registry": _need_registry,
		"lager": _lager,
		"waerme_feld": _waerme_feld,
		"tageszyklus": _tageszyklus,
		"mood_mod_registry": _mood_mod_registry,
		"ressourcen": _ressourcen,
		"ernte": _ernte,
		"verbinder": {
			"zustand_geaendert": _auf_zustand_geaendert,
			"arbeitsschritt": _auf_arbeitsschritt,
			"job_loop": _auf_job_loop_gefragt,
			"naechster_job": _auf_naechster_job_aus_queue,
			"inventar_voll": _auf_inventar_voll,
		},
	}

func einheit_zahl() -> int:
	return Einheit_LeseSchnittstelle.zahl(_einheiten)

func idle_einheiten() -> Array[int]:
	# Alle Einheiten ohne laufenden Job koennen neue Auftraege uebernehmen.
	return Einheit_LeseSchnittstelle.idle_indizes(_einheiten)

func einheit_bei(welt_position: Vector2, radius: float) -> int:
	## Linksklick-Einheitenwahl: Die naechste Einheit im Radius, sonst -1.
	return Einheit_LeseSchnittstelle.naechste_bei(_einheiten, welt_position, radius)

func auswahl_markierung_erneuern(aktiver_index: int, auswahl_liste: Array[int] = []) -> void:
	## CP-6.1: Die Trupp-Maschine trägt die goldene Markierung aller Einheiten.
	_trupp.auswahl_markierung_erneuern(aktiver_index, auswahl_liste)

func weg_planung_aktualisieren() -> void:
	## Öffentlicher Aufruf nach Gebäudeplatzierung: Das Netz kennt das
	## neue Hindernis erst nach diesem Aufruf. Bisher war _weg_planung_erneuern
	## privat und wurde nur bei einrichten() aufgerufen.
	_weg_planung_erneuern()

func modell_wechseln(neues_modell: Welt_Model, neue_tiere: Tier_Manager, welt_world: Welt_World = null) -> void:
	## Kartenwechsel-Handshake: Alle internen Modellreferenzen werden atomar
	## auf das neue Modell umgestellt. Wegnetz, Zielsuche und Ernte werden
	## neu aufgebaut, damit kein Job auf der alten Karte weiterläuft.
	_model = neues_modell
	_tiere = neue_tiere
	_welt_world = welt_world
	_trupp.model_setzen(neues_modell)
	_job_fluss.model_setzen(neues_modell, neue_tiere)
	_weg_planung_erneuern()
	if _ziel_suche != null:
		_ziel_suche.einrichten(_model, _tiere)
		_ziel_suche.einheiten_quelle_setzen(self)
	if _ernte != null:
		_ernte.einrichten(null, _ressourcen, _model, _tiere)
	_einwanderung.einrichten(_einwanderungs_kontext())
	_takt.einrichten(_takt_kontext())



## Geschlossener Schnittpunkt: Nur diese Leseschnittstellen duerfen Einheiten
## lesen; die Antworten liegen alle in der Lese-Schnittstelle.
func einheit_status(index: int) -> Einheit_Status:
	return Einheit_LeseSchnittstelle.status(_einheiten, index)

func einheit_rasse(index: int) -> String:
	return Einheit_LeseSchnittstelle.rasse(_einheiten, index)

func einheit_hp(index: int) -> int:
	return Einheit_LeseSchnittstelle.hp(_einheiten, index)

func einheit_vital(index: int) -> Einheit_VitalStatus:
	return Einheit_LeseSchnittstelle.vital(_einheiten, index)

func einheit_beschreibung(index: int) -> Dictionary:
	# Schlanker Snapshot fuer Observer, getragen von der Trupp-Maschine.
	return _trupp.beschreibung_fuer(index, einheit_rasse(index))

func einheit_position(index: int) -> Vector2:
	return Einheit_LeseSchnittstelle.position(_einheiten, index)

func einheit_mood(index: int) -> Pop_MoodMaschine:
	return Einheit_LeseSchnittstelle.mood(_einheiten, index)

func need_baum() -> Pop_NeedBaum:
	return _need_baum

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
	return Einheit_LeseSchnittstelle.job_id(_einheiten, einheit_index)

func einheit_job_abbrechen(einheit_index: int) -> void:
	# Der Spieler bricht den Job ab; die Einheit fällt zurück in den Idle.
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	status.job_abbrechen()
	var darsteller: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())

func einheit_bewegen_nach(einheit_index: int, ziel_position: Vector2) -> bool:
	# Spieler-Befehl: Die Trupp-Maschine bricht laufende Jobs ab und marschiert
	# zur Position; der Weg-Planer des Managers berechnet die Route.
	return _trupp.einheit_bewegen_nach(einheit_index, ziel_position)

func _auf_tick(nummer: int, delta: float) -> void:
	## Der Manager reicht den Takt nur an seine Takt-Maschine weiter.
	_takt.tick(nummer, delta)

func _takt_kontext() -> Dictionary:
	# Alles, was die Takt-Maschine fuer einen Takt braucht, in einem Bund.
	return {
		"einheiten": _einheiten,
		"welt_world": _welt_world,
		"model": _model,
		"verhalten": _verhalten,
		"need_registry": _need_registry,
		"versorgung_neu": _versorgung_neu,
		"versorgung": _versorgung,
		"ziel_suche": _ziel_suche,
		"trupp": _trupp,
		"mood_mod_registry": _mood_mod_registry,
		"zufall": _zufall,
	}

func _naechstes_objekt(status: Einheit_Status, alter_ziel_index: int) -> int:
	return _ziel_suche.naechstes_objekt(status, alter_ziel_index)

func _naechstes_tier(status: Einheit_Status, alter_ziel_index: int) -> int:
	return _ziel_suche.naechstes_tier(status, alter_ziel_index)

## Leerlauf und Wachstum: Die Versorgungs-Maschine besitzt die Regel.

func versuche_wachstum(haus_welt_position: Vector2) -> bool:
	return _versorgung_neu.versuche_wachstum(haus_welt_position)


func lager_anker_position() -> Vector2:
	# Der erste Lagerpunkt ist der Anker der Einwanderung (Lagerfeuer oder
	# erstes Haus); ohne Lager bleibt der Ursprung.
	if _lager != null and _lager.lager_zahl() > 0:
		return _lager.lager_position(0)
	return Vector2.ZERO

func _auf_naechster_job_aus_queue(_job_id: String, _ziel_typ: Job_Basis.ZielTyp, _ziel_index: int, _ressource: String, status: Einheit_Status) -> void:
	# Die Queue-Reaktion wohnt in der Job-Fluss-Maschine; der Manager reicht nur durch.
	_job_fluss.auf_naechster_job_aus_queue(_job_id, _ziel_typ, _ziel_index, _ressource, status)

func _auf_job_loop_gefragt(job: Job_Basis, ziel_typ: Job_Basis.ZielTyp, alter_ziel_index: int, status: Einheit_Status) -> void:
	# Die Loop-Reaktion wohnt in der Job-Fluss-Maschine; der Manager reicht nur durch.
	_job_fluss.auf_job_loop_gefragt(job, ziel_typ, alter_ziel_index, status)

func _auf_arbeitsschritt(ressource: String, menge: int, status: Einheit_Status) -> void:
	# Die Arbeitsschritt-Buchung wohnt in der Job-Fluss-Maschine.
	_job_fluss.auf_arbeitsschritt(ressource, menge, status)

func _auf_beute_erlegt(status: Einheit_Status) -> void:
	# Die Beute-Darstellung wohnt in der Trupp-Maschine.
	_trupp.beute_darstellen(status)

func _auf_inventar_voll(einheit_index: int) -> void:
	# Die Transport-Vormerkung wohnt in der Job-Fluss-Maschine.
	_job_fluss.auf_inventar_voll(einheit_index)

func _auf_zustand_geaendert(_neu: int, status: Einheit_Status, mood: Pop_MoodMaschine) -> void:
	# Die Stimmungs-Regel wohnt in der Job-Fluss-Maschine; der Manager reicht durch.
	_trupp.zustand_merken(status)
	_job_fluss.auf_zustand_geaendert(_neu, status, mood)

func transport_fuer_idle(einheit_index: int, _freies_lager: Lager_Manager) -> bool:
	# Das Lager wird in der Transportkette des Status gezogen; der Parameter
	# bleibt als Vertrag erhalten und trägt einen eigenen Namen, damit das
	# Klassenfeld _lager nicht verschattet wird.
	return _trupp.transport_fuer_idle(einheit_index)

func _nahrung_verteilen() -> void:
	# Die Versorgungs-Maschine besitzt die Regel; der Takt liegt bei der Takt-Maschine.
	_takt.nahrung_verteilen()
