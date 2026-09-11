extends SceneTree
## Lauf-Prüfung des HUD-Rahmens: beweist am echten Szenenbaum, dass die
## Statuszeilen und die Knopfzeile sich nicht überlagern und das Debug-Fenster
## im Normalbetrieb unsichtbar ist. Aufruf:
##   godot --headless --path . --script tools/lauf_pruefung_hud.gd
## Die Prüfung rendert nichts; sie misst nur die Rechtecke der Spitzen.

var _szene: Node = null
var _wartetakte: int = 0

func _init() -> void:
	# Autoload-Ersatz: Der Prüflauf startet ohne Hauptszene; die zentrale
	# Weltuhr und die Sitzung werden als Wurzelkinder nachgebaut, damit die
	# Szene ihre Manager wie im Spiel verdrahtet.
	var weltuhr_skript: GDScript = load("res://core/logic/clock/weltuhr.gd")
	if weltuhr_skript != null:
		var weltuhr: Node = weltuhr_skript.new()
		weltuhr.name = "Weltuhr"
		root.add_child(weltuhr)

func _process(_delta: float) -> bool:
	# Erst ein paar Takte warten: Die Szene baut ihre Knoten in _ready, der
	# Container ordnet sie danach; vorher gäbe es keine gültigen Rechtecke.
	if _szene == null:
		_wartetakte += 1
		if _wartetakte == 2:
			_szene = (load("res://world/scenes/welt.tscn") as PackedScene).instantiate()
			root.add_child(_szene)
		return false
	_wartetakte += 1
	if _wartetakte < 8:
		return false
	_pruefen()
	return true

func _pruefen() -> void:
	var fehler := 0
	var rahmen := _szene.get_node_or_null("%HUDRahmen") as Control
	var produktion := _szene.get_node_or_null("%ProduktionAnzeige") as Control
	var zurueck := _szene.get_node_or_null("%ZurueckKnopf") as Control
	var warum := _szene.get_node_or_null("%WarumKnopf") as Control
	var debug_panel := _szene.get_node_or_null("UILayer/DebugPanel") as Control
	if rahmen == null or produktion == null or zurueck == null or warum == null:
		print("FEHLER: HUD-Spitzen fehlen im Szenenbaum.")
		quit(1)
		return
	var rahmen_rect := rahmen.get_global_rect()
	if not rahmen_rect.encloses(zurueck.get_global_rect()) or not rahmen_rect.encloses(warum.get_global_rect()):
		print("FEHLER: Die Knopfzeile liegt außerhalb des HUD-Rahmens.")
		fehler += 1
	if produktion.get_global_rect().intersects(zurueck.get_global_rect()):
		print("FEHLER: Produktionszeile und Hauptmenü-Knopf überlagern sich.")
		fehler += 1
	if produktion.get_global_rect().intersects(warum.get_global_rect()):
		print("FEHLER: Produktionszeile und Warum-Knopf überlagern sich.")
		fehler += 1
	if debug_panel != null and debug_panel.visible:
		print("FEHLER: Das Debug-Fenster ist im Normalbetrieb sichtbar.")
		fehler += 1
	# Kachelbild-Beweis: Eine Kachel ohne ladbare Textur wäre unsichtbar,
	# der Renderer würde nur seinen Platzhalter malen.
	var registry := Welt_Registry.new()
	var kachel := registry.finde_objekt("boden")
	if kachel == null or not ResourceLoader.exists(kachel.textur_pfad):
		print("FEHLER: Kachelbild fehlt oder ist nicht importiert: %s" % ("" if kachel == null else kachel.textur_pfad))
		fehler += 1
	else:
		var bild: Texture2D = load(kachel.textur_pfad)
		if bild == null or bild.get_width() != 64:
			print("FEHLER: Kachelbild hat nicht 64 Pixel Kantenlänge: %s" % kachel.textur_pfad)
			fehler += 1
	if fehler == 0:
		var modell: Welt_Model = (_szene as Object).call("model_liefern")
		var mass := "%dx%d Kacheln à %d px" % [modell.raster_breite, modell.raster_hoehe, modell.kachel_groesse]
		print("OK: HUD-Rahmen ohne Überlagerung, Debug-Fenster standardmäßig unsichtbar (Rahmen %s, Knopfzeile %s, Welt %s)." % [str(rahmen_rect), str(zurueck.get_global_rect()), mass])
	quit(fehler)
