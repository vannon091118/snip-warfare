extends RefCounted
class_name Gebaeude_BauAuftrag
## Buchungsstelle für Bauaufträge: Sie prüft Freigabe, Bauplatz und Kosten,
## entnimmt atomar und schreibt die Baustelle ins Modell. Sie kennt keine
## Szene und keinen Tick. Meldungen und Status gehen als Callables nach oben,
## damit der Manager seine Signale behält.

var _model: Welt_Model = null
var _ressourcen: Einheit_Ressourcen = null
var _lager: Lager_Manager = null
var _definitionen: Gebaeude_DefinitionRegistry = null
var _bau_maschine: Gebaeude_BauMaschine = null
var _produktions_maschine: Gebaeude_ProduktionsMaschine = null
var _fortschritt: Welt_FortschrittsMaschine = null
var _bauplatz: Gebaeude_BauplatzPruefer = null
var _meldung: Callable = Callable()
var _status_melden: Callable = Callable()

func einrichten(model: Welt_Model, ressourcen: Einheit_Ressourcen, lager: Lager_Manager, definitionen: Gebaeude_DefinitionRegistry, bau_maschine: Gebaeude_BauMaschine, produktions_maschine: Gebaeude_ProduktionsMaschine, fortschritt: Welt_FortschrittsMaschine, bauplatz: Gebaeude_BauplatzPruefer, meldung: Callable, status_melden: Callable) -> void:
	_model = model
	_ressourcen = ressourcen
	_lager = lager
	_definitionen = definitionen
	_bau_maschine = bau_maschine
	_produktions_maschine = produktions_maschine
	_fortschritt = fortschritt
	_bauplatz = bauplatz
	_meldung = meldung
	_status_melden = status_melden

func model_setzen(model: Welt_Model) -> void:
	## Kartenwechsel-Handshake: Das Modell wird atomar ausgetauscht.
	_model = model

func bereit() -> bool:
	return _model != null and _ressourcen != null and _lager != null

func bauen_anfordern(gebaeude_id: String, welt_position: Vector2) -> Dictionary:
	## Der Spieler löst den Bau aus: Freigabe, Kosten und Lager werden vorher
	## vollständig geprüft und dann entnommen; das Gebäude erscheint im Modell
	## mit Bauzustand. Die kumulative Prüfung deckt alle Kosten zusammen ab,
	## eine Teil-Entnahme ohne Rücknahme ist damit ausgeschlossen.
	if not bereit():
		return {"ok": false, "grund": "nicht bereit"}
	if _fortschritt != null:
		var zugang := _bauplatz.voraussetzung_erfuellt(gebaeude_id)
		if not zugang.get("ok", false):
			return zugang
	if not _definitionen.hat_gebaeude(gebaeude_id):
		return {"ok": false, "grund": "unbekanntes Gebaeude"}
	var definition := _definitionen.definition_fuer(gebaeude_id)
	# Möbel-Gate: Der Datenvertrag benötigt_tags wird hier zum ersten Mal
	# wirklich befragt. Ohne diese Zeile waeren Möbel schmucklos.
	var moebel := _bauplatz.moebelbedarf_erfuellt(gebaeude_id, welt_position)
	if not moebel.get("ok", false):
		return moebel
	if not _bauplatz.bauplatz_frei(welt_position, definition):
		return {"ok": false, "grund": "Kachel bereits bebaut"}
	var lager_index := _lager.naechstes_lager_fuer(welt_position)
	if lager_index < 0:
		return {"ok": false, "grund": "kein Lager in der Naehe"}
	if not _ressourcen.mehrfach_entnehmen(definition.baukosten_paare(), lager_index):
		return {"ok": false, "grund": "Kosten fehlen"}
	var objekt_index := _neue_baustelle(definition, gebaeude_id, welt_position)
	_model.objekt_feld_setzen(objekt_index, "bedarf", definition.baukosten.duplicate(true))
	_model.objekt_feld_setzen(objekt_index, "geliefert", definition.baukosten.duplicate(true))
	_bauphase_schreiben(objekt_index, definition, _bau_maschine.starten(Gebaeude_BauMaschine.neuer_zustand()))
	_startbestand_einbuchen(definition, lager_index)
	_meldung.call("Bau angefordert: %s (%d Ticks)" % [definition.angezeigter_name, definition.bauzeit_ticks])
	_status_melden.call()
	return {"ok": true, "objekt_index": objekt_index}

func bauplan_anfordern(gebaeude_id: String, welt_position: Vector2) -> Dictionary:
	## Platziert einen Bauplan im Modell mit Materialbedarf. Keine Vorab-
	## Abbuchung von Rohstoffen aus dem Lager.
	if not bereit():
		return {"ok": false, "grund": "nicht bereit"}
	if _fortschritt != null:
		var zugang := _bauplatz.voraussetzung_erfuellt(gebaeude_id)
		if not zugang.get("ok", false):
			return zugang
	if not _definitionen.hat_gebaeude(gebaeude_id):
		return {"ok": false, "grund": "unbekanntes Gebaeude"}
	var definition := _definitionen.definition_fuer(gebaeude_id)
	# Auch der Bauplan kennt das Möbel-Gate: derselbe Vertrag, dieselbe Stelle.
	var moebel := _bauplatz.moebelbedarf_erfuellt(gebaeude_id, welt_position)
	if not moebel.get("ok", false):
		return moebel
	if not _bauplatz.bauplatz_frei(welt_position, definition):
		return {"ok": false, "grund": "Kachel bereits bebaut"}
	var lager_index := _lager.naechstes_lager_fuer(welt_position)
	if lager_index < 0:
		return {"ok": false, "grund": "kein Lager in der Naehe"}
	var bedarf: Dictionary = {}
	var geliefert: Dictionary = {}
	for ressource: String in definition.baukosten.keys():
		var menge := int(definition.baukosten[ressource])
		if menge > 0:
			bedarf[ressource] = menge
			geliefert[ressource] = 0
	var objekt_index := _neue_baustelle(definition, gebaeude_id, welt_position)
	_model.objekt_feld_setzen(objekt_index, "bedarf", bedarf)
	_model.objekt_feld_setzen(objekt_index, "geliefert", geliefert)
	var bau_zustand: Dictionary
	if bedarf.is_empty():
		bau_zustand = _bau_maschine.starten(Gebaeude_BauMaschine.neuer_zustand())
	else:
		bau_zustand = _bau_maschine.bauplan_anlegen(Gebaeude_BauMaschine.neuer_zustand())
	_bauphase_schreiben(objekt_index, definition, bau_zustand)
	_startbestand_einbuchen(definition, lager_index)
	_meldung.call("Bauplan platziert: %s (%d Ticks)" % [definition.angezeigter_name, definition.bauzeit_ticks])
	_status_melden.call()
	return {"ok": true, "objekt_index": objekt_index}

func _neue_baustelle(definition: Gebaeude_Definition, gebaeude_id: String, welt_position: Vector2) -> int:
	var objekt_index := _model.objekt_hinzufuegen(definition.welt_objekt_id, welt_position)
	_model.objekt_feld_setzen(objekt_index, "gebaeude_id", gebaeude_id)
	return objekt_index

func _bauphase_schreiben(objekt_index: int, definition: Gebaeude_Definition, bau_zustand: Dictionary) -> void:
	_model.objekt_feld_setzen(objekt_index, "bau_phase", int(bau_zustand["phase"]))
	_model.objekt_feld_setzen(objekt_index, "bau_fortschritt", 0)
	_model.objekt_feld_setzen(objekt_index, "bau_ziel_ticks", _bau_maschine.zeit_ticks_fuer(definition.bauzeit_ticks))
	_model.objekt_feld_setzen(objekt_index, "prod_phase", int(Gebaeude_ProduktionsMaschine.Phase.DEAKTIVIERT))
	_model.objekt_feld_setzen(objekt_index, "prod_fortschritt", 0)
	_model.objekt_feld_setzen(objekt_index, "prod_ziel_ticks", _produktions_maschine.zeit_ticks_fuer(definition.dauer_ticks))

func _startbestand_einbuchen(definition: Gebaeude_Definition, lager_index: int) -> void:
	## Ankunftsort: Ein Gebäude mit Startvorrat legt seinen Bestand einmalig
	## ins nächste Lager, über dieselbe Buchungsstelle wie jede Einlagerung.
	if definition == null or definition.startbestand.is_empty() or _ressourcen == null:
		return
	if lager_index < 0:
		return
	var teile: Array[String] = []
	for ressource: String in definition.startbestand.keys():
		var menge := int(definition.startbestand[ressource])
		if menge <= 0:
			continue
		_ressourcen.ernte_position_setzen(_lager.lager_position(lager_index))
		_ressourcen.hinzufuegen(ressource, menge)
		teile.append("%d %s" % [menge, ressource])
	if not teile.is_empty():
		teile.sort()
		_meldung.call("Startvorrat im Lager: %s" % ", ".join(teile))
