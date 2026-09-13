extends Einheit_Basis
class_name Einheit_Manager
## Kompositions-Wurzel der Einheiten-Domäne: Sie hält die Maschinen, den Takt
## und die Verdrahtung und reicht jeden Ruf an die Stelle, die ihn fachlich
## besitzt. Eigenes Wissen bleibt hier klein; die Lesefragen trägt die Basis,
## den Aufbau die Verdrahtung und die Regeln die Maschinen.

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
var _fortschritt: Welt_FortschrittsMaschine = null
var _ziel_suche: Einheit_ZielSuche = null
var _ernte: Einheit_ErnteMaschine = null
var _versorgung: Einheit_Versorgung = null
var _vergabe := Einheit_JobVergabeMaschine.new()
var _verhalten := Einheit_VerhaltensMaschine.new()
var _versorgung_neu := Einheit_VersorgungsMaschine.new()
var _job_fluss := Einheit_JobFlussMaschine.new()
var _trupp := Einheit_TruppMaschine.new()
var _einwanderung := Einheit_EinwanderungsMaschine.new()
var _takt := Einheit_TaktMaschine.new()
var _verdrahtung := Einheit_Verdrahtung.new()
var _welt_world: Welt_World = null

func _ready() -> void:
	y_sort_enabled = true

func _enter_tree() -> void:
	# Die Weltuhr wird zur Laufzeit aufgelöst, damit Headless-Läufe ohne
	# Autoloads funktionieren; im Spiel ist es dieselbe zentrale Uhr.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func einrichten(model: Welt_Model, tiere: Tier_Manager, ressourcen: Einheit_Ressourcen, welt_world: Welt_World = null) -> void:
	_verdrahtung.einrichten(self, model, tiere, ressourcen, welt_world)

func lager_setzen(lager: Lager_Manager) -> void:
	_verdrahtung.lager_erneuern(self, lager)

func need_baum_setzen(baum: Pop_NeedBaum) -> void:
	# Der eigene Need-Tree erzeugt und besitzt die Mood-Maschinen als Kinder.
	_verdrahtung.need_baum_erneuern(self, baum)

func sozial_lese_ruf_setzen(ruf: Callable) -> void:
	# Die Szene reicht den Lese-Ruf der Sozial-Domäne herein; jede neue
	# Einheit bekommt seither ihre Gerücht-Blase.
	_verdrahtung.sozial_ruf_erneuern(self, ruf)

func waerme_quellen_aktualisieren(feuer_positionen: Array[Vector2]) -> void:
	_verdrahtung.waerme_erneuern(self, feuer_positionen)

func fortschritt_setzen(maschine: Welt_FortschrittsMaschine) -> void:
	_verdrahtung.fortschritt_erneuern(self, maschine)

func tageszyklus_setzen(zyklus: Welt_TageszyklusMaschine) -> void:
	_verdrahtung.zyklus_erneuern(self, zyklus)

func weg_planung_aktualisieren() -> void:
	# Nach einer Gebäudeplatzierung kennt das Netz das Hindernis erst hier.
	_verdrahtung.wegnetz_erneuern(self)

func modell_wechseln(neues_modell: Welt_Model, neue_tiere: Tier_Manager, welt_world: Welt_World = null) -> void:
	# Kartenwechsel: keine Einheit darf auf der alten Karte weiterlaufen.
	_verdrahtung.modell_uebernehmen(self, neues_modell, neue_tiere, welt_world)

func verteilung_setzen(nahrung_je_takt: float) -> void:
	_versorgung.verteilung_setzen(nahrung_je_takt)

func verteilung_wert() -> float:
	# Der Startwert des Reglers ist der geltende Verbrauch, keine zweite Zahl.
	return _versorgung.verbrauch_je_takt()

func takt_minuten() -> float:
	return _need_registry.takt_minuten()

func tag_minuten() -> float:
	return _need_registry.tag_minuten()

func nacht_minuten() -> float:
	return _need_registry.nacht_minuten()

func einheit_hinzufuegen(welt_position: Vector2, rasse_id: String = "") -> int:
	return _einwanderung.hinzufuegen(welt_position, rasse_id)

func auswahl_markierung_erneuern(aktiver_index: int, auswahl_liste: Array[int] = []) -> void:
	_trupp.auswahl_markierung_erneuern(aktiver_index, auswahl_liste)

func einheit_beschreibung(index: int) -> Dictionary:
	return _trupp.beschreibung_fuer(index, einheit_rasse(index))

func need_baum() -> Pop_NeedBaum:
	return _need_baum

func job_vergeben(einheit_index: int, job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ziel_position: Vector2) -> bool:
	# Vergabe, Blickrichtung und Darsteller-Folge trägt die Verdrahtung.
	return _verdrahtung.job_praesentieren(self, einheit_index, job_id, ziel_typ, ziel_index, ziel_position)

func einheit_job_abbrechen(einheit_index: int) -> void:
	# Der Spieler bricht den Job ab; die Einheit fällt zurück in den Idle.
	_verdrahtung.job_abbrechen(self, einheit_index)

func einheit_bewegen_nach(einheit_index: int, ziel_position: Vector2) -> bool:
	# Spieler-Befehl: Die Trupp-Maschine bricht laufende Jobs ab und marschiert.
	return _trupp.einheit_bewegen_nach(einheit_index, ziel_position)

func versuche_wachstum(haus_welt_position: Vector2) -> bool:
	# Leerlauf-Wachstum: Die Versorgungs-Maschine besitzt die Regel.
	return _versorgung_neu.versuche_wachstum(haus_welt_position)

func lager_anker_position() -> Vector2:
	# Der erste Lagerpunkt ist der Anker der Einwanderung; ohne Lager der Ursprung.
	if _lager != null and _lager.lager_zahl() > 0:
		return _lager.lager_position(0)
	return Vector2.ZERO

func schlag_ort_empfaenger_setzen(empfaenger: Callable) -> void:
	_verdrahtung.schlag_ort_empfaenger_setzen(empfaenger)

func schlag_empfaenger_setzen(empfaenger: Callable) -> void:
	# Die Progressions-Domäne hört jeden echten Arbeitsschlag.
	_verdrahtung.schlag_empfaenger_setzen(empfaenger)

func _auf_tick(nummer: int, delta: float) -> void:
	# Der Manager reicht den Takt nur an seine Takt-Maschine weiter.
	_takt.tick(nummer, delta)

func _nahrung_verteilen() -> void:
	_takt.nahrung_verteilen()

func _auf_zustand_geaendert(neu: int, status: Einheit_Status, mood: Pop_MoodMaschine) -> void:
	# Trupp merkt den Zustand, der Job-Fluss trägt die Stimmungs-Regel.
	_trupp.zustand_merken(status)
	_job_fluss.auf_zustand_geaendert(neu, status, mood)
