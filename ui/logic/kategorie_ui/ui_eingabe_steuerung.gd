extends RefCounted
class_name Ui_EingabeSteuerung
## Spitze: RTS Eingabe-Übersetzer. Einzige Stelle, die Maus- und Tasten-
## Eingaben in Aufrufe an Maschinen übersetzt (Auswahl, Jobs, Kamera, Hud).
## Sie besitzt keine Bau-, Expansions- oder Job-Vergabe-Rechnung mehr: Diese
## drei Abläufe wohnen in den Maschinen Ui_BauAuftragMaschine, Ui_Expansion-
## Maschine und Ui_JobVergabeMaschine. Der Übersetzer verteilt nur noch
## Ereignisse und ermittelt Klick-Orte. RTS: Spieler wählt Einheiten, vergibt
## Jobs, Kamera (WASD) ist reine Beobachtung.

const SCHNELLWAHL_MAX := 9

signal debug_umgeschaltet(sichtbar: bool)

## Kategorie daten: Eingabe-Ziel-Referenzen, Auswahl-Hilfen und die drei
## Ablauf-Maschinen der Eingabe-Domäne.
var _steuerung: Kern_SteuerungRegistry = null
var _model: Welt_Model = null
var _registry: Welt_Registry = null
var _stockmaenner: Einheit_Manager = null
var _tiere: Tier_Manager = null
var _auswahl: Ui_AuswahlManager = null
var _karte: Welt_Renderer = null
var _kamera: Camera2D = null
var _hud: VBoxContainer = null
var _rechteck: Control = null
var _kontext: PopupMenu = null
var _schnellwahl: Array[int] = []
var _kamera_steuerung: Ui_KameraSteuerung = null
var _karten_ebene: CanvasLayer = null
var _karten_viewer: Ui_KartenViewer = null
var _karten_oeffnen: bool = false
var _fortschritt: Welt_FortschrittsMaschine = null
var _rechtsklick_welt_position := Vector2.ZERO
var _debug_sichtbar: bool = false
var _orchestrator_panel: Ui_OrchestratorPriorityPanel = null
var _orchestrator_manager: Orchestrator_Manager = null
var _bau: Ui_BauAuftragMaschine = null
var _expansion: Ui_ExpansionMaschine = null
var _jobs: Ui_JobVergabeMaschine = null

## Kategorie logik: Eingabe in Maschinen-Aufrufe übersetzen.

func einrichten(p: Dictionary) -> void:
	_steuerung = p.get("steuerung")
	_model = p.get("model")
	_registry = p.get("registry")
	_stockmaenner = p.get("stockmaenner")
	_tiere = p.get("tiere")
	_auswahl = p.get("auswahl")
	_karte = p.get("karte")
	_kamera = p.get("kamera")
	_hud = p.get("hud")
	_rechteck = p.get("rechteck")
	_kontext = p.get("kontext")
	_kamera_steuerung = p.get("kamera_steuerung")
	_karten_ebene = p.get("karten_ebene")
	_karten_viewer = p.get("karten_viewer")
	_fortschritt = p.get("fortschritt")
	_orchestrator_panel = p.get("orchestrator_panel")
	_orchestrator_manager = p.get("orchestrator_manager")
	if p.has("schnellwahl"):
		_schnellwahl = p["schnellwahl"]
	# Die drei Ablauf-Maschinen tragen Bau, Expansion und Job-Vergabe.
	_bau = Ui_BauAuftragMaschine.new()
	_bau.einrichten(p.get("gebaeude"), _hud, p.get("moebel_platzierer"))
	_expansion = Ui_ExpansionMaschine.new()
	_expansion.einrichten(p.get("map_fabrik"), _hud, p.get("modell_ersetzen", Callable()))
	_jobs = Ui_JobVergabeMaschine.new()
	_jobs.einrichten({
		"steuerung": _steuerung,
		"model": _model,
		"job_registry": p.get("job_registry"),
		"stockmaenner": _stockmaenner,
		"tiere": _tiere,
		"auswahl": _auswahl,
		"hud": _hud,
	})

func modell_wechseln(neues_modell: Welt_Model, neue_tiere: Tier_Manager) -> void:
	## Kartenwechsel-Handshake: Tauscht Modell und Tier-Manager atomar aus,
	## damit Klick-Auswahl und Job-Vergabe auf der neuen Karte arbeiten.
	_model = neues_modell
	_tiere = neue_tiere
	_jobs.modell_wechseln(neues_modell)

func bau_auftrag_setzen(gebaeude_id: String) -> void:
	_bau.auftrag_setzen(gebaeude_id)

func debug_umschalten() -> void:
	_debug_sichtbar = not _debug_sichtbar
	debug_umgeschaltet.emit(_debug_sichtbar)
	if _hud != null:
		(_hud as Variant).meldung_setzen("Debug-Overlay: %s" % ("Aktiv" if _debug_sichtbar else "Deaktiviert"))

func karten_umschalten() -> void:
	_karten_oeffnen = not _karten_oeffnen
	if _karten_ebene != null:
		_karten_ebene.visible = _karten_oeffnen
	if _karten_oeffnen and _karten_viewer != null:
		_karten_viewer.fokus_auf_spieler()

func unhandled_input(ereignis: InputEvent, klick_ermitteln: Callable, rechteck_pflegen: Callable, hotkey: Callable) -> void:
	if ereignis is InputEventMouseButton and ereignis.pressed:
		match ereignis.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if _kamera_steuerung != null:
					_kamera_steuerung.zoom(1.0 / _kamera_steuerung.zoom_schritt(), _kamera)
			MOUSE_BUTTON_WHEEL_DOWN:
				if _kamera_steuerung != null:
					_kamera_steuerung.zoom(_kamera_steuerung.zoom_schritt(), _kamera)
			MOUSE_BUTTON_LEFT:
				if _bau != null and _bau.auftrag_aktiv():
					_bau.auftrag_platzieren_an(klick_ermitteln.call(ereignis))
					return
				if _auswahl != null:
					_auswahl.einzel_start(klick_ermitteln.call(ereignis))
			MOUSE_BUTTON_RIGHT:
				if _bau != null and _bau.auftrag_aktiv():
					_bau.auftrag_abbrechen()
					return
				_rechtsklick_verarbeiten(klick_ermitteln.call(ereignis))
	elif ereignis is InputEventMouseButton and not ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		if _bau == null or not _bau.auftrag_aktiv():
			_linksklick_ende(klick_ermitteln.call(ereignis))
	elif ereignis is InputEventMouseMotion and _auswahl != null and _auswahl.ziehen_aktiv:
		rechteck_pflegen.call()
	elif ereignis is InputEventKey and ereignis.pressed:
		if ereignis.keycode == KEY_M:
			karten_umschalten()
		elif ereignis.keycode == KEY_F3:
			debug_umschalten()
		elif ereignis.keycode == KEY_ESCAPE:
			if _bau != null:
				_bau.auftrag_abbrechen()
		else:
			hotkey.call(ereignis)
	elif ereignis.is_action_pressed("ui_cancel"):
		pass

func eingabe(ereignis: InputEvent, eltern: Node, verteilung_cb: Callable) -> void:
	if ereignis is InputEventKey and ereignis.pressed and ereignis.keycode == KEY_V and ereignis.ctrl_pressed:
		var dlg := preload("res://population/scenes/verteilung_dialog.gd").new()
		# Werte aus dem Datenpool: Takt und Verbrauch kommen über den Manager
		# (Need-Registry aus needs.json); das Fenster führt keine eigenen Zahlen.
		if _stockmaenner != null:
			(dlg as Object).call("werte_setzen", _stockmaenner.takt_minuten(), _stockmaenner.tag_minuten(), _stockmaenner.nacht_minuten(), _stockmaenner.verteilung_wert())
		eltern.add_child(dlg)
		(dlg as Window).popup_centered()
		dlg.verteilung_gesetzt.connect(verteilung_cb)
		eltern.get_viewport().set_input_as_handled()

func klick_position(ereignis: InputEventMouseButton) -> Vector2:
	if _karte == null:
		return Vector2.ZERO
	var karten_transform := _karte.get_global_transform_with_canvas().affine_inverse()
	return karten_transform * ereignis.position

func rechteck_pflegen_bild(maus_global: Vector2, viewport_transform: Transform2D, ziehen_start: Vector2) -> void:
	if _auswahl == null or not _auswahl.ziehen_aktiv or _rechteck == null:
		return
	var start_bild: Vector2 = viewport_transform * ziehen_start
	var end_bild: Vector2 = viewport_transform * maus_global
	_rechteck.rechteck_setzen(start_bild, end_bild)

func hotkey_verarbeiten(ereignis: InputEventKey) -> void:
	if _auswahl == null or _stockmaenner == null or _hud == null:
		return
	if ereignis.keycode < KEY_1 or ereignis.keycode > KEY_9:
		return
	var slot := int(ereignis.keycode) - int(KEY_1)
	if slot >= SCHNELLWAHL_MAX:
		return
	if ereignis.ctrl_pressed:
		if slot >= _schnellwahl.size():
			_schnellwahl.resize(slot + 1)
		_schnellwahl[slot] = _auswahl.aktiver_einheit_index
		(_hud as Variant).meldung_setzen("Schnellwahl %d gesetzt auf Einheit %d" % [slot + 1, _auswahl.aktiver_einheit_index])
	else:
		if slot < _schnellwahl.size() and _schnellwahl[slot] < _stockmaenner.einheit_zahl():
			_auswahl.aktiver_einheit_index = _schnellwahl[slot]
			_auswahl.auswahl_einheiten = [_schnellwahl[slot]]
			_stockmaenner.auswahl_markierung_erneuern(_schnellwahl[slot], [_schnellwahl[slot]])
			(_hud as Variant).meldung_setzen("Einheit %d gewählt" % (_auswahl.aktiver_einheit_index + 1))
			var _bus := Kern_SignalBus.bus()
			if _bus != null:
				_bus._emit_einheit_ausgewaehlt(_schnellwahl[slot])

func auf_verteilung(nahrung_je_takt: float) -> void:
	if _stockmaenner != null:
		_stockmaenner.verteilung_setzen(nahrung_je_takt)
	if _hud != null:
		(_hud as Variant).meldung_setzen("Verteilung: %.1f Nahrung je Einheit je Takt" % nahrung_je_takt)

func auf_kontext_aktion(aktion: Dictionary) -> void:
	var logik := str(aktion.get("logik_id", ""))
	var label_text := str(aktion.get("label", ""))
	# Einstiegs-Gating: Die menschenlesbare Sperre aus steuerung.json
	# entscheidet; die Progressions-Maschine beantwortet nur die Frage.
	if _fortschritt != null and not _fortschritt.stufe_frei(_steuerung.steuerung.gesperrt_ab_stufe_fuer_aktion(str(aktion.get("id", "")))):
		if _hud != null:
			(_hud as Variant).meldung_setzen("Noch nicht freigeschaltet: %s" % str(_fortschritt.ziel_zeile()))
		return
	if logik == "bauen":
		_bau.auftrag_setzen(str(aktion.get("gebaeude_id", "")))
		_bau.auftrag_platzieren_an(_rechtsklick_welt_position)
		return
	if logik == "expansieren":
		_expansion.expansion_ausfuehren()
		return
	if logik == "marschieren":
		_jobs.marschieren_nach(_rechtsklick_welt_position)
		return
	if label_text.to_lower().contains("wachstum") or logik.to_lower().contains("wachstum"):
		_wachstum_ausfuehren()
		return
	if logik == "ressource_holz" or logik == "ressource_stein":
		_jobs.ressource_aktion_ausfuehren(_rechtsklick_welt_position)
		return
	if _hud != null:
		(_hud as Variant).meldung_setzen("Kontext: %s ueber Logik %s" % [label_text, logik])

func _wachstum_ausfuehren() -> void:
	var haus_pos := _kamera_steuerung.kamera_position if _kamera_steuerung != null else Vector2.ZERO
	var lager: Lager_Manager = null
	if _stockmaenner != null:
		lager = _stockmanehmer_lager_fallback()
	if lager != null and lager.lager_zahl() > 0:
		haus_pos = lager.lager_position(0)
	if _stockmaenner != null and _stockmaenner.versuche_wachstum(haus_pos):
		if _hud != null:
			(_hud as Variant).meldung_setzen("Wachstum: Neuer Stickman am Lager, 3 Nahrung verbraucht.")
	elif _hud != null:
		(_hud as Variant).meldung_setzen("Wachstum braucht 3 Nahrung im naechsten Lager.")

func _stockmanehmer_lager_fallback() -> Lager_Manager:
	# Das Wachstum braucht das Lager nur als Anker-Quelle; die Szene reicht
	# es über den Manager. Der Fallback liest den Anker aus der Kameramitte.
	return null

func _linksklick_ende(ende: Vector2) -> void:
	if _rechteck != null:
		_rechteck.rechteck_verbergen()
	if _auswahl == null or _stockmaenner == null or _hud == null:
		return
	var treffer: Array[int] = _auswahl.ziehen_ende(ende, _stockmaenner.einheit_zahl(), _stockmaenner.einheit_position)
	if treffer.is_empty():
		_klick_verarbeiten(ende)
	else:
		(_hud as Variant).meldung_setzen("Massenwahl: %d Einheiten im Rechteck" % treffer.size())

func _rechtsklick_verarbeiten(welt_pos: Vector2) -> void:
	if _hud == null:
		return
	_rechtsklick_welt_position = welt_pos

	var hat_einheiten := false
	if _stockmaenner != null and _auswahl != null:
		if _auswahl.aktiver_einheit_index >= 0 and _auswahl.aktiver_einheit_index < _stockmaenner.einheit_zahl():
			hat_einheiten = true

	var radius := _jobs.auswahl_radius()
	var tier_nummer := _tiere.tier_id_bei(welt_pos, radius) if _tiere != null else -1
	var objekt_index := _model.objekt_bei(welt_pos, radius) if _model != null else -1
	var element_id := _model.objekt_element_id(objekt_index) if (_model != null and objekt_index >= 0) else ""

	if hat_einheiten:
		if tier_nummer >= 0:
			_jobs.job_fuer_tier_vergeben(tier_nummer, _tiere.tier_position(tier_nummer))
			(_hud as Variant).meldung_setzen("Befehl: Jagen auf Tier #%d" % tier_nummer)
			return
		if objekt_index >= 0 and element_id != "":
			var bau_phase := int(_model.objekt_feld(objekt_index, "bau_phase", Gebaeude_BauMaschine.Phase.NICHT_GEBAUT))
			if bau_phase == Gebaeude_BauMaschine.Phase.BAUPLAN or bau_phase == Gebaeude_BauMaschine.Phase.BAU_ANGEFORDERT:
				_jobs.baustelle_priorisieren(objekt_index, _model.objekt_position(objekt_index))
				return
			var element_pos := _model.objekt_position(objekt_index)
			_jobs.job_fuer_objekt_vergeben(objekt_index, element_pos, element_id)
			return

		# Freier Boden: Ausgewählte Einheiten marschieren dorthin
		_jobs.marschieren_nach(welt_pos)
		return

	# Ohne aktive Einheit: Kontextmenü zielgerichtet öffnen
	if _kontext != null:
		if _kamera != null and _kamera.get_viewport() != null:
			_kontext.position = _kamera.get_viewport().get_mouse_position()
		_kontext.eintraege_aufbauen_fuer_tags(_ziel_tags_fuer_ort(tier_nummer, objekt_index, element_id))
		_kontext.popup()

func _ziel_tags_fuer_ort(tier_nummer: int, objekt_index: int, element_id: String) -> Array[String]:
	# Ziel-Tags statt Objektnamen: Tiere tragen die Tags der Jagd, Objekte ihre
	# Katalog-Tags, freier Boden die des Bodens. Welche Aktion darauf passt,
	# entscheidet allein die Registry aus steuerung.json.
	if tier_nummer >= 0:
		return ["tier", "jagd"]
	if objekt_index >= 0 and element_id != "" and _registry != null:
		return _registry.ziel_tags_fuer(element_id)
	return ["boden"]

func _klick_verarbeiten(klick: Vector2) -> void:
	if _model == null or _registry == null or _tiere == null or _stockmaenner == null or _auswahl == null or _hud == null:
		return
	var radius := _jobs.auswahl_radius()
	var ketten_nachfrage := Input.is_key_pressed(KEY_SHIFT)
	## Befund 5: Linksklick wählt zuerst eine Einheit (Priorität 1).
	## Erst wenn keine Einheit im Klickradius liegt, wird ein Job an die
	## aktive Einheit vergeben (Priorität 2).
	var einheit_treffer := _stockmaenner.einheit_bei(klick, radius)
	if einheit_treffer >= 0:
		# Prüfen, ob es sich um eine Orchestrator-Einheit handelt
		if _ist_orchestrator_einheit(einheit_treffer):
			_orchestrator_panel_oeffnen(einheit_treffer)
			return
		_auswahl.aktiver_einheit_index = einheit_treffer
		_auswahl.auswahl_einheiten = [einheit_treffer]
		_stockmaenner.auswahl_markierung_erneuern(einheit_treffer, [einheit_treffer])
		(_hud as Variant).meldung_setzen("Einheit %d gewaehlt." % (einheit_treffer + 1))
		var _klick_bus := Kern_SignalBus.bus()
		if _klick_bus != null:
			_klick_bus._emit_einheit_ausgewaehlt(einheit_treffer)
		return
	# Kein Einheitentreffer: Job an aktive Einheit vergeben, sofern eine gewählt ist
	var aktiv := _auswahl.aktiver_einheit_index
	if aktiv < 0 or aktiv >= _stockmaenner.einheit_zahl():
		if not ketten_nachfrage:
			_auswahl.aktiver_einheit_index = -1
			_auswahl.auswahl_leeren()
			_stockmaenner.auswahl_markierung_erneuern(-1, [])
			(_hud as Variant).meldung_setzen("Zuerst eine Einheit auswaehlen.")
		return
	var tier_nummer := _tiere.tier_id_bei(klick, radius)
	if tier_nummer >= 0:
		_jobs.job_fuer_tier_vergeben(tier_nummer, _tiere.tier_position(tier_nummer))
		return
	var objekt_index := _model.objekt_bei(klick, radius)
	if objekt_index >= 0:
		var element_id := _model.objekt_element_id(objekt_index)
		var eintrag := _registry.finde_objekt(element_id)
		if eintrag != null and eintrag.typ == &"objekt":
			_jobs.job_fuer_objekt_vergeben(objekt_index, _model.objekt_position(objekt_index), element_id)
			return
	if not ketten_nachfrage:
		# CP-6.2: Klick ins Leere hebt die Einheiten-Auswahl auf
		_auswahl.aktiver_einheit_index = -1
		_auswahl.auswahl_leeren()
		_stockmaenner.auswahl_markierung_erneuern(-1, [])
		(_hud as Variant).meldung_setzen("Auswahl aufgehoben.")

func _ist_orchestrator_einheit(einheit_index: int) -> bool:
	# Eine Orchestrator-Einheit hat den Job_Orchestrieren als aktiven Job
	if _stockmaenner == null:
		return false
	var job_id := _stockmaenner.job_id_einheit(einheit_index)
	return job_id == "orchestrieren"

func _orchestrator_panel_oeffnen(einheit_index: int) -> void:
	# Finde den Orchestrator-Config-Index für diese Einheit; der Manager
	# verwaltet die Zonen, das Panel öffnet die passende.
	if _orchestrator_panel == null or _orchestrator_manager == null:
		return
	var zonen_index := _orchestrator_manager.zonen_index_fuer_einheit(einheit_index)
	if zonen_index >= 0:
		_orchestrator_panel.fuer_orchestrator_oeffnen(zonen_index)
	else:
		# Fallback: Erste Zone
		_orchestrator_panel.fuer_orchestrator_oeffnen(0)
