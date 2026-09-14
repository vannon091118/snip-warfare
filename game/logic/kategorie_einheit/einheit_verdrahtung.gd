extends RefCounted
class_name Einheit_Verdrahtung
## Aufbau-Spitze der Einheiten-Domäne: Trägt die Reihenfolge der Maschinen-
## Einrichtung, die Ernte-Signale, das Wegnetz, die Anschluss- und
## Präsentations-Rufe und die Kontext-Bündel des Managers. Genau eine
## Verantwortung: Verdrahten, verbinden und Kontexte bauen. Kein Tick, keine
## Regel; der Manager bleibt die Kompositions-Wurzel und ruft nur noch hier auf.

## Kategorie daten: Wegnetz, Kontext-Bündel und die Anschluss-Empfänger.
var _weg_planung: Einheit_WegPlanung = null
var _einwanderungs_buendel: Dictionary = {}
var _takt_buendel: Dictionary = {}
var _sozial_blasen: Array = []
var _sozial_lese_ruf: Callable = Callable()
var _schlag_ort_empfaenger: Callable = Callable()
var _schlag_empfaenger: Callable = Callable()
## Kategorie logik: Der Ankunftsort-Vertrag; die Versorgung liest ihn je Takt.
var _ankunftsort: Callable = Callable()


func ankunftsort_erneuern(mgr: Einheit_Manager, ankunft: Callable) -> void:
	## Die Welt-Szene reicht ihren Blick hereingereicht; ohne Vertrag greift
	## die Versorgung auf den Lager-Anker zurück.
	_ankunftsort = ankunft
	versorgung_erneuern(mgr)


## Erster Aufbau: Modell-Referenzen des Managers setzen und die Kette bauen.
func einrichten(mgr: Einheit_Manager, model: Welt_Model, tiere: Tier_Manager,
		ressourcen: Einheit_Ressourcen, welt_world: Welt_World) -> void:
	mgr._model = model
	mgr._tiere = tiere
	mgr._ressourcen = ressourcen
	mgr._welt_world = welt_world
	aufbauen(mgr)


## Lager-Anschluss: Trupp und Job-Fluss kennen das Lager, Einwanderung und
## Stimmungskette werden mit den neuen Quellen neu verdrahtet.
func lager_erneuern(mgr: Einheit_Manager, lager: Lager_Manager) -> void:
	mgr._lager = lager
	mgr._trupp.lager_setzen(lager)
	mgr._job_fluss.lager_setzen(lager)
	einwanderung_erneuern(mgr)
	stimmung_erneuern(mgr)


func need_baum_erneuern(mgr: Einheit_Manager, baum: Pop_NeedBaum) -> void:
	mgr._need_baum = baum
	einwanderung_erneuern(mgr)


func sozial_ruf_erneuern(mgr: Einheit_Manager, ruf: Callable) -> void:
	_sozial_lese_ruf = ruf
	einwanderung_erneuern(mgr)


func waerme_erneuern(mgr: Einheit_Manager, feuer_positionen: Array[Vector2]) -> void:
	# Die Kachelkante kommt aus dem Modell, der Rest aus dem Feuer-Katalog.
	if mgr._model != null:
		mgr._waerme_feld.kachel_groesse_setzen(mgr._model.kachel_groesse)
	mgr._waerme_feld.quellen_setzen(feuer_positionen, 5, 1.0)


func fortschritt_erneuern(mgr: Einheit_Manager, maschine: Welt_FortschrittsMaschine) -> void:
	mgr._fortschritt = maschine
	versorgung_erneuern(mgr)


func zyklus_erneuern(mgr: Einheit_Manager, zyklus: Welt_TageszyklusMaschine) -> void:
	mgr._tageszyklus = zyklus
	einwanderung_erneuern(mgr)
	stimmung_erneuern(mgr)


func modell_uebernehmen(mgr: Einheit_Manager, model: Welt_Model, tiere: Tier_Manager,
		welt_world: Welt_World) -> void:
	mgr._model = model
	mgr._tiere = tiere
	mgr._welt_world = welt_world
	mgr._job_fluss.model_setzen(model, tiere)
	modell_erneuern(mgr)


func job_abbrechen(mgr: Einheit_Manager, einheit_index: int) -> void:
	if einheit_index < 0 or einheit_index >= mgr._einheiten.size():
		return
	var status: Einheit_Status = mgr._einheiten[einheit_index]["status"]
	status.job_abbrechen()
	var darsteller: Einheit_Darsteller = mgr._einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())


## Verbindet Maschinen-Kette, Wegnetz, Ernte-Signale und Kontexte.
func aufbauen(mgr: Einheit_Manager) -> void:
	wegnetz_erneuern(mgr)
	_ziel_suche_verbinden(mgr)
	_ernte_verbinden(mgr)
	mgr._trupp.einrichten(mgr._einheiten)
	mgr._trupp.job_registry_setzen(mgr._job_registry)
	mgr._trupp.weg_planer_setzen(planner_ruf())
	mgr._job_fluss.einrichten(mgr._trupp, mgr._job_registry, mgr._ziel_suche,
		mgr._ernte, planner_ruf())
	# Modell und Tiere gehören auch dem Job-Fluss: Nur so findet der Loop das
	# nächste Ziel desselben Typs über die Ziel-Suche.
	mgr._job_fluss.model_setzen(mgr._model, mgr._tiere)
	mgr._vergabe.einrichten(mgr._einheiten, mgr._job_registry, mgr._ziel_suche,
		planner_ruf())
	_versorgung_verbinden(mgr)
	mgr._verhalten.einrichten({
		"manager": mgr,
		"mood_mod_registry": mgr._mood_mod_registry,
		"job_registry": mgr._job_registry,
		"ressourcen": mgr._ressourcen,
		"tiere": mgr._tiere,
	})
	einwanderung_erneuern(mgr)
	takt_erneuern(mgr)


## Kartenwechsel: Wegnetz, Zielsuche und Ernte frisch aufbauen, Kontexte neu.
func modell_erneuern(mgr: Einheit_Manager) -> void:
	wegnetz_erneuern(mgr)
	_ziel_suche_verbinden(mgr)
	if mgr._ernte != null:
		mgr._ernte.einrichten(null, mgr._ressourcen, mgr._model, mgr._tiere)
	einwanderung_erneuern(mgr)
	takt_erneuern(mgr)


## Stimmungs-Kette aller Einheiten: Need-Registry, Lager und Umfeld neu setzen.
func stimmung_erneuern(mgr: Einheit_Manager) -> void:
	for einheit: Dictionary in mgr._einheiten:
		var mood: Pop_MoodMaschine = einheit["mood"]
		mood.einrichten(mgr._need_registry, mgr._lager)
		mood.waerme_und_zyklus_setzen(mgr._waerme_feld, mgr._tageszyklus,
			mgr._mood_mod_registry)


## Wachstum und Einwanderung: der Kontext der Versorgungs-Maschine.
func versorgung_erneuern(mgr: Einheit_Manager) -> void:
	mgr._versorgung_neu.einrichten({
		"manager": mgr,
		"ressourcen": mgr._ressourcen,
		"fortschritt": mgr._fortschritt,
		"ankunftsort": _ankunftsort,
	})


## Die Wegplanung ist eine geteilte Maschine: Ein Netz für alle Einheiten,
## der Weg-Cache macht den A-Stern bezahlbar.
func wegnetz_erneuern(mgr: Einheit_Manager) -> void:
	if _weg_planung == null:
		_weg_planung = Einheit_WegPlanung.new()
	_weg_planung.netz_erneuern(mgr._model)


func planner_ruf() -> Callable:
	return _planner_fuer


func _planner_fuer(status: Einheit_Status, ziel_position: Vector2) -> void:
	if _weg_planung == null:
		return
	status.weg_ziele_uebernehmen(_weg_planung.weg_zu(status.welt_position, ziel_position))


func _ziel_suche_verbinden(mgr: Einheit_Manager) -> void:
	if mgr._ziel_suche == null:
		mgr._ziel_suche = Einheit_ZielSuche.new()
	mgr._ziel_suche.einrichten(mgr._model, mgr._tiere)
	mgr._ziel_suche.einheiten_quelle_setzen(mgr)


func _ernte_verbinden(mgr: Einheit_Manager) -> void:
	mgr._ernte = Einheit_ErnteMaschine.new()
	mgr._ernte.einrichten(null, mgr._ressourcen, mgr._model, mgr._tiere)
	mgr._ernte.zufall_setzen(mgr._zufall)
	mgr._ernte.manager_setzen(mgr)
	# Rein optisch: Jeder Ernteschlag meldet seinen Ort, die Atmosphaeren-
	# Domaene zeigt dort Staub; die Progressions-Domaene hoert die Schlaege.
	mgr._ernte.beute_erlegt.connect(mgr._trupp.beute_darstellen)
	mgr._ernte.schlag_ort_gemeldet.connect(_auf_schlag_ort)
	mgr._ernte.schlag_objekt_gemeldet.connect(_auf_schlag_objekt)
	mgr._ernte.inventar_voll.connect(mgr._job_fluss.auf_inventar_voll)


func _versorgung_verbinden(mgr: Einheit_Manager) -> void:
	mgr._versorgung = Einheit_Versorgung.new()
	mgr._versorgung.einrichten(mgr._ressourcen)
	# Verbrauchs-Vorgabe aus dem Datenpool: Der Wert aus needs.json gilt, bis
	# der Spieler im Verteilungs-Fenster etwas anderes setzt.
	mgr._versorgung.verteilung_setzen(mgr._need_registry.verbrauch_je_takt())
	versorgung_erneuern(mgr)


## Anschluss der Szene: Staub-Empfänger der Atmosphaere und Schlag-Empfänger
## der Progressions-Domaene; der Manager kennt nur den Aufruf, nicht die Domaene.
func schlag_ort_empfaenger_setzen(empfaenger: Callable) -> void:
	_schlag_ort_empfaenger = empfaenger


func schlag_empfaenger_setzen(empfaenger: Callable) -> void:
	_schlag_empfaenger = empfaenger


func _auf_schlag_ort(welt_position: Vector2) -> void:
	if _schlag_ort_empfaenger.is_valid():
		_schlag_ort_empfaenger.call(welt_position)


func _auf_schlag_objekt(ziel_index: int) -> void:
	if _schlag_empfaenger.is_valid():
		_schlag_empfaenger.call(ziel_index)


## Die Blasen der Einwanderung lesen pro Takt den Geruecht-Stand.
func _sozial_blasen_ticken(nummer: int) -> void:
	for blase: Variant in _sozial_blasen:
		(blase as Soz_Denkblase).auf_tick(nummer)


## Spielersicht: Nach der Vergabe tragen Blick, Animation und Darsteller-
## Flips der Präsentationsgriff; der Manager hält nur den öffentlichen Vertrag.
func job_praesentieren(mgr: Einheit_Manager, einheit_index: int, job_id: String,
		ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ziel_position: Vector2) -> bool:
	if not mgr._vergabe.vergeben(einheit_index, job_id, ziel_typ, ziel_index, ziel_position):
		return false
	if einheit_index < 0 or einheit_index >= mgr._einheiten.size():
		return true
	var status: Einheit_Status = mgr._einheiten[einheit_index]["status"]
	mgr._vergabe.blick_richtung_tragen(einheit_index, ziel_position)
	var darsteller: Einheit_Darsteller = mgr._einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())
	darsteller.flip_h = not status.blick_richtung_rechts()
	return true


## Frische Ankuenfte: Der Kontext traegt genau die Quellen, die eine
## Ankunft braucht; die Maschinen-Rufe binden direkt, der Zustands-Ruf
## bleibt beim Manager, weil Trupp und Job-Fluss beide hoeren wollen.
func einwanderung_erneuern(mgr: Einheit_Manager) -> void:
	_einwanderungs_buendel = {
		"node": mgr,
		"einheiten": mgr._einheiten,
		"need_baum": mgr._need_baum,
		"need_registry": mgr._need_registry,
		"lager": mgr._lager,
		"waerme_feld": mgr._waerme_feld,
		"tageszyklus": mgr._tageszyklus,
		"mood_mod_registry": mgr._mood_mod_registry,
		"ressourcen": mgr._ressourcen,
		"ernte": mgr._ernte,
		"sozial_lese_ruf": _sozial_lese_ruf,
		"sozial_blasen": _sozial_blasen,
		"verbinder": {
			"zustand_geaendert": mgr._auf_zustand_geaendert,
			"arbeitsschritt": mgr._job_fluss.auf_arbeitsschritt,
			"job_loop": mgr._job_fluss.auf_job_loop_gefragt,
			"naechster_job": mgr._job_fluss.auf_naechster_job_aus_queue,
			"inventar_voll": mgr._job_fluss.auf_inventar_voll,
		},
	}
	mgr._einwanderung.einrichten(_einwanderungs_buendel)


## Ein Takt: Alles, was die Takt-Maschine fuer einen Takt braucht, in einem Bund.
func takt_erneuern(mgr: Einheit_Manager) -> void:
	_takt_buendel = {
		"einheiten": mgr._einheiten,
		"welt_world": mgr._welt_world,
		"model": mgr._model,
		"verhalten": mgr._verhalten,
		"need_registry": mgr._need_registry,
		"versorgung_neu": mgr._versorgung_neu,
		"versorgung": mgr._versorgung,
		"ziel_suche": mgr._ziel_suche,
		"trupp": mgr._trupp,
		"mood_mod_registry": mgr._mood_mod_registry,
		"zufall": mgr._zufall,
		"sozial_bubble_tick": _sozial_blasen_ticken,
	}
	mgr._takt.einrichten(_takt_buendel)
