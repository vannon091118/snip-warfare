extends RefCounted
class_name Ui_EingabeSteuerung
## Spitze: Eingabe-Übersetzer. Einzige Stelle, die Maus- und Tasten-
## Eingaben in Aufrufe an Maschinen übersetzt (Auswahl, Jobs, Kamera,
## Hud). Sie besitzt keine Welt-Generierung, keine Lager-Fabrik und
## keine Biom-Logik. Jede Fremd-Logik läuft strikt über die gereichte
## Maschinen-Referenz, nie direkt in der Szene.

const SCHNELLWAHL_MAX := 9

## Kategorie daten: Eingabe-Ziel-Referenzen und Auswahl-Hilfen.
var _steuerung: Kern_SteuerungRegistry = null
var _model: Welt_Model = null
var _registry: Welt_Registry = null
var _job_registry: Job_Registry = null
var _stockmaenner: Einheit_Manager = null
var _tiere: Tier_Manager = null
var _lager: Lager_Manager = null
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

signal karten_umschalten_gewuenscht
signal verteilung_gewuenscht(nahrung_je_takt: float)

## Kategorie logik: Eingabe in Maschinen-Aufrufe übersetzen.

func einrichten(p: Dictionary) -> void:
	_steuerung = p.get("steuerung")
	_model = p.get("model")
	_registry = p.get("registry")
	_job_registry = p.get("job_registry")
	_stockmaenner = p.get("stockmaenner")
	_tiere = p.get("tiere")
	_lager = p.get("lager")
	_auswahl = p.get("auswahl")
	_karte = p.get("karte")
	_kamera = p.get("kamera")
	_hud = p.get("hud")
	_rechteck = p.get("rechteck")
	_kontext = p.get("kontext")
	_kamera_steuerung = p.get("kamera_steuerung")
	_karten_ebene = p.get("karten_ebene")
	_karten_viewer = p.get("karten_viewer")
	if p.has("schnellwahl"):
		_schnellwahl = p["schnellwahl"]

func karten_umschalten() -> void:
	_karten_oeffnen = not _karten_oeffnen
	if _karten_ebene != null:
		_karten_ebene.visible = _karten_oeffnen
	if _karten_oeffnen and _karten_viewer != null:
		_karten_viewer.fokus_auf_spieler()

func unhandled_input(ereignis: InputEvent, klick_position: Callable, rechteck_pflegen: Callable, hotkey: Callable) -> void:
	if ereignis is InputEventMouseButton and ereignis.pressed:
		match ereignis.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if _kamera_steuerung != null:
					_kamera_steuerung.zoom(1.0 / _kamera_steuerung.zoom_schritt(), _kamera)
			MOUSE_BUTTON_WHEEL_DOWN:
				if _kamera_steuerung != null:
					_kamera_steuerung.zoom(_kamera_steuerung.zoom_schritt(), _kamera)
			MOUSE_BUTTON_LEFT:
				if _auswahl != null:
					_auswahl.einzel_start(klick_position.call(ereignis))
			MOUSE_BUTTON_RIGHT:
				_rechtsklick_verarbeiten(klick_position.call(ereignis))
	elif ereignis is InputEventMouseButton and not ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		_linksklick_ende(klick_position.call(ereignis))
	elif ereignis is InputEventMouseMotion and _auswahl != null and _auswahl.ziehen_aktiv:
		rechteck_pflegen.call()
	elif ereignis is InputEventKey and ereignis.pressed:
		if ereignis.keycode == KEY_M:
			karten_umschalten()
		else:
			hotkey.call(ereignis)
	elif ereignis.is_action_pressed("ui_cancel"):
		pass

func eingabe(ereignis: InputEvent, eltern: Node, verteilung_cb: Callable) -> void:
	if ereignis is InputEventKey and ereignis.pressed and ereignis.keycode == KEY_V and ereignis.ctrl_pressed:
		var dlg := preload("res://population/scenes/verteilung_dialog.gd").new()
		eltern.add_child(dlg)
		(dlg as Window).popup_centered()
		dlg.verteilung_gesetzt.connect(verteilung_cb)
		eltern.get_viewport().set_input_as_handled()

func klick_position(ereignis: InputEventMouseButton) -> Vector2:
	if _karte == null:
		return Vector2.ZERO
	var karten_transform := _karte.get_global_transform_with_canvas().affine_inverse()
	return karten_transform * ereignis.position

func linksklick_ende(ende: Vector2) -> void:
	_linksklick_ende(ende)

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
		# Schnellwahl merken: aktiven Index in den Slot legen.
		if slot >= _schnellwahl.size():
			_schnellwahl.resize(slot + 1)
		_schnellwahl[slot] = _auswahl.aktiver_einheit_index
		(_hud as Variant).meldung_setzen("Schnellwahl %d gesetzt auf Einheit %d" % [slot + 1, _auswahl.aktiver_einheit_index])
	elif slot < _schnellwahl.size() and _schnellwahl[slot] < _stockmaenner.einheit_zahl():
		_auswahl.aktiver_einheit_index = _schnellwahl[slot]
		(_hud as Variant).meldung_setzen("Einheit %d gewählt" % (_auswahl.aktiver_einheit_index + 1))

func auf_verteilung(nahrung_je_takt: float) -> void:
	if _stockmaenner != null:
		_stockmaenner.verteilung_setzen(nahrung_je_takt)
	if _hud != null:
		(_hud as Variant).meldung_setzen("Verteilung: %.1f Nahrung je Einheit je Takt" % nahrung_je_takt)

func auf_kontext_aktion(aktion: Dictionary) -> void:
	var logik := str(aktion.get("logik_id", ""))
	var label_text := str(aktion.get("label", ""))
	if label_text.to_lower().contains("wachstum") or logik.to_lower().contains("wachstum"):
		var haus_pos := _kamera_steuerung.spieler_position if _kamera_steuerung != null else Vector2.ZERO
		if _lager != null and _lager.lager_zahl() > 0:
			haus_pos = _lager.lager_position(0)
		if _stockmaenner != null and _stockmaenner.versuche_wachstum(haus_pos):
			if _hud != null:
				(_hud as Variant).meldung_setzen("Wachstum: Neuer Stickman am Lager, 3 Nahrung verbraucht.")
		elif _hud != null:
			(_hud as Variant).meldung_setzen("Wachstum braucht 3 Nahrung im naechsten Lager.")
		return
	if _hud != null:
		(_hud as Variant).meldung_setzen("Kontext: %s ueber Logik %s" % [label_text, logik])

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
	if _model == null or _tiere == null or _kontext == null or _hud == null:
		return
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung != null and _steuerung.steuerung != null else 60.0
	var ziel_objekt := _model.objekt_bei(welt_pos, radius)
	var ziel_tier := _tiere.tier_id_bei(welt_pos, radius)
	if ziel_objekt >= 0 or ziel_tier >= 0:
		_kontext.position = _kamera.get_viewport_rect().size / 2 if _kamera != null else Vector2.ZERO
		if _kamera != null:
			_kontext.position = _kamera.get_viewport().get_mouse_position() if _kamera.get_viewport() != null else Vector2.ZERO
		_kontext.popup()
		return
	if Input.is_key_pressed(KEY_SHIFT):
		(_hud as Variant).meldung_setzen("Aggressiver Move: Ziel wird automatisch angegriffen")
	else:
		(_hud as Variant).meldung_setzen("Move-Befehl an aktive Einheit")

func _klick_verarbeiten(klick: Vector2) -> void:
	if _model == null or _registry == null or _tiere == null or _job_registry == null or _stockmaenner == null or _auswahl == null or _hud == null:
		return
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung != null and _steuerung.steuerung != null else 60.0
	var ketten_nachfrage := Input.is_key_pressed(KEY_SHIFT)
	var tier_nummer := _tiere.tier_id_bei(klick, radius)
	if tier_nummer >= 0:
		_job_vergeben_fuer_tier(tier_nummer, _tiere.tier_position(tier_nummer), ketten_nachfrage)
		return
	var objekt_index := _model.objekt_bei(klick, radius)
	if objekt_index >= 0:
		var element_id := _model.objekt_element_id(objekt_index)
		var eintrag := _registry.finde_objekt(element_id)
		if eintrag != null and eintrag.typ == &"objekt":
			_job_vergeben_fuer_objekt(objekt_index, _model.objekt_position(objekt_index), element_id, ketten_nachfrage)
			return
	if not ketten_nachfrage:
		(_hud as Variant).meldung_setzen("Hier gibt es nichts zu tun")

func _job_vergeben_fuer_tier(tier_nummer: int, ziel_position: Vector2, _kette: bool) -> void:
	var tier_art := _tiere.tier_art(tier_nummer)
	if tier_art == "":
		return
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung != null and _steuerung.steuerung != null else 60.0
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_tier(tier_art):
			continue
		var cam_pos := _kamera_steuerung.spieler_position if _kamera_steuerung != null else Vector2.ZERO
		if cam_pos.distance_to(ziel_position) > probe.reichweite() + radius:
			if _hud != null:
				(_hud as Variant).meldung_setzen("Zu weit entfernt: erst hinbewegen")
			return
		if _stockmaenner.job_vergeben(_auswahl.aktiver_einheit_index, job_id, Job_Basis.ZielTyp.TIER, tier_nummer, ziel_position):
			if _hud != null:
				(_hud as Variant).job_anzeigen(_job_registry.job_name(job_id))
			return

func _job_vergeben_fuer_objekt(objekt_index: int, ziel_position: Vector2, element_id: String, _kette: bool) -> void:
	var radius := _steuerung.steuerung.auswahl_radius if _steuerung != null and _steuerung.steuerung != null else 60.0
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_objekt(element_id):
			continue
		var cam_pos := _kamera_steuerung.spieler_position if _kamera_steuerung != null else Vector2.ZERO
		if cam_pos.distance_to(ziel_position) > probe.reichweite() + radius:
			if _hud != null:
				(_hud as Variant).meldung_setzen("Zu weit entfernt: erst hinbewegen")
			return
		if _stockmaenner.job_vergeben(_auswahl.aktiver_einheit_index, job_id, Job_Basis.ZielTyp.OBJEKT, objekt_index, ziel_position):
			if _hud != null:
				(_hud as Variant).job_anzeigen(_job_registry.job_name(job_id))
			return
