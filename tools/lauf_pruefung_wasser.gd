extends SceneTree
## Beweislauf des Wasser-Automaten: Schalter aus dem Datenpool, echter Fluss
## mit Ausbreitungs-Begrenzung, Ufer-Saum, Koppelung ueber den Signalbus und
## die Platzierungs-Geste des Renderers. Alles ueber die bestehenden Systeme.
## Aufruf: godot --headless --path . --script tools/lauf_pruefung_wasser.gd

const TICK_DELTA := 1.0 / 24.0

func _initialize() -> void:
	# Der ganze Beweislauf lebt in _initialize: Erst dann ist der Szenenbaum
	# bereit, einen angehängten Signalbus auch wirklich zu finden.
	_beweisen()

func _beweisen() -> void:
	var fehler := 0
	# 1) Schalter und Reichweite kommen aus welt_definition.json.
	var definitionen := Welt_DefinitionRegistry.new()
	definitionen.laden()
	var schalter := bool(definitionen.wasser_wert("laeuft", false))
	var schritte := int(definitionen.wasser_wert("ausbreitung_schritte", 0))
	if not schalter or schritte <= 0:
		print("FEHLER: Wasser-Schalter steht auf aus oder ohne Reichweite (laeuft %s, schritte %d)" % [str(schalter), schritte])
		fehler += 1
	# 2) Anlage: kleine Karte, eine Wasser-Quelle in der Mitte.
	var model := Welt_Model.new()
	model.karte_erzeugen(16, 16, "wiese")
	var mitte := 8
	model.fliese_setzen(mitte, mitte, "wasser", 0)
	var registry := Welt_Registry.new()
	# 3) Automat einrichten und Takte geben (Intervall 3 aus dem Pool).
	var automat := Welt_WasserAutomat.new()
	automat.einrichten(model, registry)
	for _tick in 6 * 24:
		automat.tick(TICK_DELTA)
	var wasser_nach_takt := _zaehle(model, "wasser", 0)
	if wasser_nach_takt <= 1:
		print("FEHLER: Wasser fließt nicht (wiese %d, nachher %d)" % [1, wasser_nach_takt])
		fehler += 1
	# 4) Reichweite: Bei Radius 6 kann die Fläche den Kreis r=6 nie übersteigen.
	var radius := 0
	for y in model.raster_hoehe:
		for x in model.raster_breite:
			if model.fliese(x, y, 0) == "wasser":
				radius = maxi(radius, absi(x - mitte) + absi(y - mitte))
	if radius > schritte:
		print("FEHLER: Wasser läuft über die Reichweite (radius %d > %d)" % [radius, schritte])
		fehler += 1
	# 5) Ufer-Saum: Um jedes Wasser steht Land oder Ufer, nie nackter Boden.
	var nacktes_ufer := 0
	# Diagnose-Ausschnitt: Reihe durch die Mitte, Zustände als Buchstaben.
	var zeile := ""
	for x in model.raster_breite:
		zeile += _zeichen_fuer(model.fliese(x, mitte, 0))
	print("DIAGNOSE Reihe %d: %s" % [mitte, zeile])
	for y in model.raster_hoehe:
		for x in model.raster_breite:
			if model.fliese(x, y, 0) == "ufer":
				continue
			if model.fliese(x, y, 0) == "wasser":
				# Wasser selbst ist kein Ufer-Kandidat: Nur Land zählt.
				continue
			var ist_rand := x == 0 or y == 0 or x == model.raster_breite - 1 or y == model.raster_hoehe - 1
			if ist_rand:
				continue
			var wasser_nachbar := false
			for richtung in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if model.fliese(x + richtung.x, y + richtung.y, 0) == "wasser":
					wasser_nachbar = true
			if wasser_nachbar:
				nacktes_ufer += 1
	if nacktes_ufer > 0:
		print("FEHLER: %d Wasser-Nachbarn ohne Ufer-Saum" % nacktes_ufer)
		fehler += 1
	# 6) Signal-Koppelung: Jede Modellschreibung meldet am Bus; ein einfacher
	# Lauscher zählt die Meldungen einer frischen Schreibung.
	var bus := Kern_SignalBus.bus()
	if bus == null:
		# Script-Modus ohne Autoloads: Die Bus-Instanz wird unter dem Namen
		# angelegt, den bus() sucht — derselbe Weg wie im Spielbetrieb.
		var test_bus := Kern_SignalBus.new()
		test_bus.name = "KernSignalBusAutoload"
		if root != null:
			root.add_child(test_bus)
			bus = Kern_SignalBus.bus()
		print("DIAGNOSE: root=%s, bus_nach_anhang=%s" % [str(root != null), str(bus != null)])
	if bus == null or not bus.has_signal("kachel_geaendert"):
		print("FEHLER: Signalbus mit kachel_geaendert fehlt")
		fehler += 1
	else:
		var meldungen := [0]
		bus.kachel_geaendert.connect(func(_x: int, _y: int, _element_id: String, _z: int) -> void:
			meldungen[0] += 1)
		model.fliese_setzen(2, 2, "wasser", 0)
		if meldungen[0] != 1:
			print("FEHLER: fliese_setzen meldet nicht am Bus (%d Meldungen)" % meldungen[0])
			fehler += 1
	# 7) Geste: Die Klasse lebt und trägt den Sichtbefehl; der Renderer
	# verdrahtet sie beim Aufbau (Textnaht geprüft, Knoten-Lauf folgt im Spiel).
	var gesten_text := FileAccess.open("res://world/logic/kategorie_welt/welt_kachel_geste.gd", FileAccess.READ)
	if gesten_text == null or not gesten_text.get_as_text().contains("platzieren_falls_neu"):
		print("FEHLER: Kachel-Geste fehlt oder trägt die Platzierungs-Prüfung nicht")
		fehler += 1
	if fehler == 0:
		print("ALLE WASSER-PRUEFUNGEN GRUEN (wasser nachher %d, radius %d)" % [wasser_nach_takt, radius])
		quit(0)
	else:
		print("%d WASSER-PRUEFUNGEN ROT" % fehler)
		quit(1)

func _zeichen_fuer(element_id: String) -> String:
	match element_id:
		"wasser":
			return "~"
		"ufer":
			return "u"
		"wiese":
			return "."
		_:
			return "?"

func _zaehle(model: Welt_Model, element_id: String, z_ebene: int) -> int:
	var treffer := 0
	for y in model.raster_hoehe:
		for x in model.raster_breite:
			if model.fliese(x, y, z_ebene) == element_id:
				treffer += 1
	return treffer
