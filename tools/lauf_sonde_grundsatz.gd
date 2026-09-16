extends SceneTree
## Regel-9-Sonde fuer das Grundsatz-Fenster: Sie laedt die echte Welt-Szene
## mit allen Autoloads, oeffnet das echte Fenster auf dem Weg des Spielers,
## legt den Kannibalismus-Schalter ueber das UI-Ereignis um und beobachtet
## an den bestehenden Tueren, ob die Einheiten die Tat tragen. Kein
## Spielcode kennt diese Datei; die Moral-Daten werden nie direkt
## beschrieben, nur ueber das Fenster und die Manager-Tuer gelesen.
##
## Beweisplan in zwei Phasen:
## Phase 1 (Schalter zu, Werkstatt-Stand): Zwei hungrige Einheiten fern der
## Tiere; der Job kannibale darf nicht erscheinen.
## Phase 2 (Schalter umgelegt ueber den CheckButton-Toggled): derselbe
## Hunger, nun muss ein Kannibale erscheinen und die Blase die Tat tragen.

const STEPPER := "res://tools/sonden/sonden_frame_stepper.gd"

var _start_frame: int = 0
var _frist_frames: int = 6000

func _ueber_budget() -> bool:
	## Wachhund in Frames statt Uhrzeit: Die Verfassung verbietet
	## Zeitquellen, und der Rahmenzaehler friert nie ein.
	return Engine.get_process_frames() - _start_frame > _frist_frames

func _fehler(text: String) -> void:
	printerr("SONDE-FEHLER: %s" % text)
	quit(1)

func _initialize() -> void:
	_start_frame = Engine.get_process_frames()
	await process_frame
	await process_frame
	var paket := load("res://world/scenes/welt.tscn") as PackedScene
	if paket == null:
		_fehler("welt.tscn nicht ladbar (Kompilierung des Spielcodes)")
		return
	var szene: Node = paket.instantiate()
	root.add_child(szene)
	# Ladekette frameweise abwarten, wie die Welt-Szene-Sonde es haelt.
	for i in 40:
		await process_frame
		if _ueber_budget():
			_fehler("Budget beim Laden erschöpft")
			return
	var mgr: Einheit_Manager = szene.call("einheiten_liefern") if szene.has_method("einheiten_liefern") else null
	if mgr == null:
		_fehler("Einheit-Manager nicht über einheiten_liefern erreichbar")
		return
	var lese := mgr.moral_grundsatz_lesen("kannibalismus_erlaubt")
	print("SONDE-ZEILE: schalter_vor_lese=%s" % str(lese))
	if lese:
		_fehler("Schalter steht schon auf erlaubt; der Beweis braucht die Werkstatt-Stellung")
		return
	# Fenster über den Weg des Spielers öffnen: Zuerst der Leisten-Knopf,
	# sonst der oeffentliche Dialog-Ruf popup_centered.
	var leiste: Node = szene.find_child("FensterLeiste", true, false)
	var weg := ""
	if leiste != null:
		for knopf in leiste.find_children("*", "Button", true, false):
			var n := str((knopf as Node).name).to_lower()
			var t := str((knopf as Button).text).to_lower() if knopf is Button else ""
			if n.contains("grundsatz") or t.contains("grundsatz"):
				(knopf as BaseButton).pressed.emit()
				weg = "leisten_knopf"
				break
	var fenster: Node = szene.find_child("GrundsatzFenster", true, false)
	if fenster == null:
		_fehler("GrundsatzFenster nicht im Baum")
		return
	if weg == "":
		(fenster as ConfirmationDialog).popup_centered()
		weg = "popup_centered"
	print("SONDE-ZEILE: oeffnungsweg=%s sichtbar=%s" % [weg, str(fenster.visible)])
	if not fenster.visible:
		_fehler("Fenster blieb zu nach Öffnungsweg %s" % weg)
		return
	# Die Schalter sind jetzt gebaut (about_to_popup); der Kannibalismus-
	# Schalter traegt den Namen Schalter_kannibalismus_erlaubt.
	var schalter: CheckButton = null
	for kind in fenster.find_children("*", "CheckButton", true, false):
		if str(kind.name) == "Schalter_kannibalismus_erlaubt":
			schalter = kind
			break
	if schalter == null:
		_fehler("Kannibalismus-Schalter im Fenster nicht gebaut")
		return
	print("SONDE-ZEILE: schalter_ui=%s text=%s gedrueckt=%s" % [str(schalter.name), schalter.text, str(schalter.button_pressed)])
	if schalter.button_pressed:
		_fehler("Schalter im UI steht auf erlaubt, die Moral-Daten sagen verboten")
		return
	# Zwei Einheiten an einem stillen Winkel: Das Spiel besetzt sie über
	# seine eigene Einwanderungs-Tür, der Ort ist bewusst fern der Mitte.
	var ecke := Vector2(15200.0, 11600.0)
	mgr.einheit_hinzufuegen(ecke)
	mgr.einheit_hinzufuegen(ecke + Vector2(48.0, 0.0))
	print("SONDE-ZEILE: einheiten=%d winkel=%.0f,%.0f" % [mgr.einheit_zahl(), ecke.x, ecke.y])
	var stepper: RefCounted = (load(STEPPER) as GDScript).new(self) as RefCounted
	# Phase 1: Hunger laufen lassen, Schalter bleibt zu. Erwartung: kein
	# kannibale, auch wenn die Kette reif ist; die Moral sperrt die Tat.
	var phase1_kannibale := -1
	for runde in 13:
		stepper.call("ticks_pumpen", 20)
		phase1_kannibale = _kannibale_finden(mgr)
		if phase1_kannibale >= 0 or _ueber_budget():
			break
	print("SONDE-ZEILE: phase1_tor_zu kannibale_einheit=%d" % phase1_kannibale)
	if phase1_kannibale >= 0:
		_fehler("Einheit jagte den Nachbarn bei geschlossenem Schalter (Einheit %d)" % phase1_kannibale)
		return
	# Phase 2: Der Spieler legt den Schalter um — über das echte UI-Ereignis
	# des CheckButton, nicht über die Daten. Der Lauf der Signale:
	# toggled -> _auf_schalter -> grundsatz_setzen -> Manager -> Moral.
	schalter.button_pressed = true
	var nach_lesen := mgr.moral_grundsatz_lesen("kannibalismus_erlaubt")
	print("SONDE-ZEILE: schalter_nach_lese=%s" % str(nach_lesen))
	if not nach_lesen:
		_fehler("Schalter umgelegt, aber die Manager-Tuer liest weiter verboten")
		return
	# Die Spielertür: Hungrige Kolonisten arbeiten stoppellos dem Baum-Pool
	# hinterher, solange die Autonomie sie füttert — und die Kannibalen-Kette
	# wendet sich laut Vertrag nur an Idle-Einheiten. Der Spieler zieht
	# deshalb die Aufträge zurück; genau dafuer ist die Abbruch-Tür da.
	mgr.einheit_job_abbrechen(0)
	mgr.einheit_job_abbrechen(1)
	# Beobachtung: Bei weiterem Hunger muss nun ein Kannibale erscheinen.
	var phase2_kannibale := -1
	var gezogen := 0
	for runde2 in 13:
		stepper.call("ticks_pumpen", 20)
		# Halteleine: Ohne Auftrag wandern die Einheiten auseinander; die
		# Opfer-Reichweite aus dem Job-Pool liegt bei 60 px. Driftet das
		# Paar darueber hinaus, setzt die Sonde den Nachbarn wieder an den
		# Jaeger heran — dieselbe Tuer, die auch die Geh-Probe benutzt.
		var abstand := mgr.einheit_position(0).distance_to(mgr.einheit_position(1))
		if abstand > 40.0:
			mgr.einheit_status(1).welt_position_setzen(mgr.einheit_position(0) + Vector2(6.0, 0.0))
			gezogen += 1
			print("SONDE-ZEILE: halteleine runde=%d abstand_war=%.0f" % [runde2, abstand])
		phase2_kannibale = _kannibale_finden(mgr)
		if phase2_kannibale >= 0 or _ueber_budget():
			break
	var mood_null: Pop_MoodMaschine = mgr._einheiten[0]["mood"]
	var zeile_null := mood_null.mood()
	print("SONDE-ZEILE: stimmung_null kette=%s stufe=%d verhalten=%s gezogen=%d" % [zeile_null.kette, zeile_null.stufe, zeile_null.verhalten, gezogen])
	print("SONDE-ZEILE: jobs=%s anker=%s zustand0=%d zustand1=%d" % [str([mgr.job_id_einheit(0), mgr.job_id_einheit(1)]), str(mgr.ankunftsort()), int(mgr.einheit_status(0).zustand), int(mgr.einheit_status(1).zustand)])
	print("SONDE-ZEILE: phase2_tor_offen kannibale_einheit=%d" % phase2_kannibale)
	if phase2_kannibale < 0:
		_fehler("Schalter offen, aber kein Kannibale trat die Tat an")
		return
	var jaeger_id := mgr.job_id_einheit(phase2_kannibale)
	print("SONDE-ZEILE: tat_getragen einheit=%d job=%s" % [phase2_kannibale, jaeger_id])
	# Aufräumen wie die Verwaisten-Sonde: Szene frei, Rest melden.
	szene.queue_free()
	for i in 5:
		await process_frame
	print("SONDE: OK grundsatz_fenster schalter_umgelegt tat_getragen durch_einheit=%d" % phase2_kannibale)
	quit(0)

func _kannibale_finden(mgr: Einheit_Manager) -> int:
	for i in mgr.einheit_zahl():
		if mgr.job_id_einheit(i) == "kannibale":
			return i
	return -1
