extends SceneTree
## Beweislauf der Papier-Gesten (Regel 7): Echter Renderer, echtes Modell,
## echte Progressions-Kette. Der Lauf schlaegt einen Baum stufenweise,
## faellt ihn und prueft die sichtbaren Spuren am Objekt-Knoten: Riss-Decal,
## Aufstoss des Standbilds, Umsturz-Krone, Wuchs-Massstab des Saemlings.
## Aufruf: godot --headless --path . --script tools/lauf_pruefung_gesten.gd

func _initialize() -> void:
	# Der ganze Beweislauf lebt in _initialize: Erst dann ist der Szenenbaum
	# bereit, einen angehängten Signalbus auch wirklich zu finden.
	_beweisen()

func _beweisen() -> void:
	var fehler := 0
	# 1) Anlage: Registry, Modell mit Wiese, echter Renderer.
	var registry := Welt_Registry.new()
	var model := Welt_Model.new()
	model.karte_erzeugen(12, 12, "wiese")
	var renderer := Welt_Renderer.new()
	root.add_child(renderer)
	# Im Script-Modus ohne Main-Loop feuert _ready nicht von selbst: Der
	# Notruf gilt nur, wenn der Objekt-Container noch fehlt.
	if renderer.get_node_or_null("Objekte") == null:
		renderer._ready()
	renderer.darstellen(model, registry)
	# 2) Die Progressions-Maschine anbringen und verkabeln wie im Spiel.
	var maschine := Welt_ProgressionsMaschine.new()
	maschine.einrichten(model, Welt_BiomRegistry.new(), null)
	root.add_child(maschine)
	renderer.progressions_maschine_setzen(maschine)
	# 3) Baum pflanzen und im Knoten-Spiegel des Renderers finden.
	var baum_stelle := Vector2(5 * 64.0 + 32.0, 5 * 64.0 + 32.0)
	var baum_index := model.objekt_hinzufuegen("baum", baum_stelle)
	renderer.objekt_knoten_anhaengen(baum_index)
	var knoten := _knoten_an_stelle(renderer, baum_stelle)
	if knoten == null or knoten.standbild() == null or knoten.standbild().texture == null:
		print("FEHLER: Baum-Knoten ohne Standbild nach dem Anhaengen")
		quit(1)
		return
	# 4) Vier Schläge: Je Treffer ein Puls, nach Stufe drei der Riss,
	# nach dem vierten die Krone und der Stumpf an derselben Stelle.
	var gesehen := {"stadium": 0, "folge": 0}
	maschine.stadium_geaendert.connect(func(_i: int, _e: String, _s: String) -> void: gesehen["stadium"] += 1)
	maschine.folge_objekt_entstanden.connect(func(_i: int, _e: String) -> void: gesehen["folge"] += 1)
	for schlag_nummer in 4:
		maschine.schlag(baum_index)
		var kinder := []
		for kind in knoten.get_children():
			kinder.append(str(kind.name))
		print("DIAGNOSE Schlag %d: element=%s bestand=%d kinder=%s" % [
			schlag_nummer + 1, str(model.objekt_feld(baum_index, "element_id", "")),
			maschine.bestand(baum_index), str(kinder)])
	if int(gesehen["stadium"]) < 1:
		print("FEHLER: Schlag pulst die Darstellung nicht (Ereignisse %d)" % int(gesehen["stadium"]))
		fehler += 1
	var element_nach_fall := str(model.objekt_feld(baum_index, "element_id", ""))
	if element_nach_fall != "baum_stumpf":
		print("FEHLER: Gefallener Baum trägt nicht den Stumpf (%s)" % element_nach_fall)
		fehler += 1
	if int(gesehen["folge"]) < 1:
		print("FEHLER: Der Fall meldet kein Folge-Objekt (Ereignisse %d)" % int(gesehen["folge"]))
		fehler += 1
	# 5) Sichtbare Spuren: Krone hängt nach dem Fall, das alte Riss-Decal
	# ist mit dem Identitätswechsel abgeräumt und der Stumpf steht im
	# vollen Maß, ohne den Wuchs seiner Kette zu erben.
	var krone := knoten.get_node_or_null("UmsturzKrone") as Sprite2D
	if krone == null:
		print("FEHLER: Nach dem Fall hängt keine Umsturz-Krone am Knoten")
		fehler += 1
	var altes_decal := knoten.get_node_or_null("RissDecal") as Sprite2D
	if altes_decal != null:
		print("FEHLER: Der Stumpf trägt noch den Riss seines Baums")
		fehler += 1
	if knoten.standbild() != null and knoten.standbild().scale != Vector2.ONE:
		print("FEHLER: Stumpf erbt den Wuchs-Maßstab seiner Kette (%s)" % str(knoten.standbild().scale))
		fehler += 1
	# 6) Wuchs: frischer Saemling startet unter dem Stufen-Maßstab.
	var wald_stelle := Vector2(8 * 64.0, 8 * 64.0)
	var saemling := model.objekt_hinzufuegen("busch", wald_stelle)
	renderer.objekt_knoten_anhaengen(saemling)
	var saemling_knoten := _knoten_an_stelle(renderer, wald_stelle)
	if saemling_knoten == null or saemling_knoten.standbild() == null:
		print("FEHLER: Saemling ohne Knoten nach dem Anhaengen")
		fehler += 1
	else:
		var wuchs: Vector2 = saemling_knoten.standbild().scale
		if not (wuchs.x < 1.0 and wuchs.x >= 0.79):
			print("FEHLER: Wuchs-Maßstab folgt nicht der Fraktion (%s)" % str(wuchs))
			fehler += 1
	# 7) Klassen-Areal: Alle vier Gesten leben und tragen ihre eine Pflicht.
	for pfad in [
		"res://world/logic/kategorie_welt/welt_stadium_geste.gd",
		"res://world/logic/kategorie_welt/welt_wuchs_geste.gd",
		"res://world/logic/kategorie_welt/welt_riss_geste.gd",
		"res://world/logic/kategorie_welt/welt_umsturz_geste.gd",
	]:
		if not FileAccess.file_exists(pfad):
			print("FEHLER: Geste %s fehlt" % pfad)
			fehler += 1
	if fehler == 0:
		print("ALLE GESTEN-PRUEFUNGEN GRUEN")
		quit(0)
	else:
		print("%d GESTEN-PRUEFUNGEN ROT" % fehler)
		quit(1)

func _knoten_an_stelle(renderer: Welt_Renderer, stelle: Vector2) -> Welt_ObjektKnoten:
	# Der Renderer trägt die Knoten unter dem Objekt-Container; der Test
	# erkennt sie am Fußpunkt, denn der ist die Wahrheit der Zeichnung.
	var behaelter := renderer.get_node_or_null("Objekte")
	if behaelter == null:
		return null
	for kind in behaelter.get_children():
		var knoten := kind as Welt_ObjektKnoten
		if knoten != null and knoten.fusspunkt().distance_to(stelle) < 2.0:
			return knoten
	return null
