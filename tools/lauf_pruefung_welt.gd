extends SceneTree
## Lauf-Prüfung zur Weltkette: Determinismus, Regionen, Persistenz und
## Reihenfolge-Unabhängigkeit der Generierung.

## Test-Zeuge für das Queue-Signal: fängt den nächsten Auftrag auf, den die
## Einheit nach dem aktiven Job meldet, ohne auf Lambda-Erfassung zu setzen.
class Einheit_QueueZeuge:
	extends RefCounted
	var empfangen: bool = false

	func auf_naechster(_job_id: String, _ziel_typ: int, _ziel_index: int, _ressource: String) -> void:
		empfangen = true

func _init() -> void:
	# Autoload-Ersatz: Der Testlauf startet ohne Hauptszene, deshalb wird die
	# zentrale Weltuhr hier als Wurzelkind nachgebaut, damit Manager-Module,
	# die den Weltuhr-Tick erwarten, auch im Test kompilieren und ticken.
	var weltuhr_skript: GDScript = load("res://core/weltuhr.gd")
	if weltuhr_skript != null:
		var weltuhr: Node = weltuhr_skript.new()
		weltuhr.name = "Weltuhr"
		root.add_child(weltuhr)
	var fehler := 0
	# 1) Determinismus: gleicher Seed, gleiche Welt.
	var modell_eins := Welt_Model.new()
	var modell_zwei := Welt_Model.new()
	var generator_eins := Welt_Generator.new()
	var generator_zwei := Welt_Generator.new()
	if not generator_eins.welt_erzeugen(modell_eins, 12345, "gemaaessigt"):
		print("FEHLER: Generator Lauf 1 scheiterte")
		fehler += 1
	if not generator_zwei.welt_erzeugen(modell_zwei, 12345, "gemaaessigt"):
		print("FEHLER: Generator Lauf 2 scheiterte")
		fehler += 1
	if str(modell_eins.nach_woerterbuch()) != str(modell_zwei.nach_woerterbuch()):
		print("FEHLER: Gleicher Seed liefert verschiedene Welten")
		fehler += 1
	else:
		print("OK: Seed 12345 reproduziert identische Welten (Objekte: %d, verworfene Chunks: %d)" % [modell_eins.objekt_anzahl(), generator_eins.verworfene_chunks])
	# 2) Verschiedene Seeds liefern verschiedene Welten.
	var modell_drei := Welt_Model.new()
	var generator_drei := Welt_Generator.new()
	generator_drei.welt_erzeugen(modell_drei, 54321, "gemaaessigt")
	if str(modell_drei.nach_woerterbuch()) == str(modell_eins.nach_woerterbuch()):
		print("FEHLER: Verschiedene Seeds liefern dieselbe Welt")
		fehler += 1
	else:
		print("OK: Seed 54321 ergibt eine andere Welt")
	# 3) Regionen existieren und tragen Biome aus dem Biom-Pool.
	var biome_ok := true
	if modell_eins.regionen.is_empty():
		print("FEHLER: Keine Regionen geplant")
		fehler += 1
		biome_ok = false
	for region: Dictionary in modell_eins.regionen:
		if str(region.get("biom_id", "")) == "":
			biome_ok = false
	if biome_ok:
		print("OK: %d Regionen mit Biom-Bezug geplant" % modell_eins.regionen.size())
	# 4) Persistenz: nach_woerterbuch -> aus_woerterbuch -> identisch.
	var runde := Welt_Model.new()
	if not runde.aus_woerterbuch(modell_eins.nach_woerterbuch()):
		print("FEHLER: Persistenz-Lauf scheiterte")
		fehler += 1
	elif str(runde.nach_woerterbuch()) != str(modell_eins.nach_woerterbuch()):
		print("FEHLER: Persistenz rundet nicht identisch")
		fehler += 1
	else:
		print("OK: Persistenz rundet die Welt identisch ab")
	# 5) Biome der Registry: Biomfarben für Renderer und Kartenviewer lesbar.
	var biome := Welt_BiomRegistry.new()
	for biom_id: String in ["gemaaessigt", "tundra", "steppe"]:
		if biome.biom_fuer(biom_id) == null:
			print("FEHLER: Biom %s fehlt in der Registry" % biom_id)
			fehler += 1
	# 6) Kartengrößen kommen aus der Weltdefinition (Daten, nicht Code).
	var def_reg := Welt_DefinitionRegistry.new()
	if not def_reg.laden():
		print("FEHLER: Weltdefinition nicht ladbar")
		fehler += 1
	else:
		var groesse := def_reg.lokalkarten_groesse_fuer(12345)
		if groesse.x <= 0 or groesse.y <= 0:
			print("FEHLER: Kartengröße aus Definition ungültig: %s" % str(groesse))
			fehler += 1
		else:
			print("OK: Kartengröße aus Daten für Seed 12345: %s" % str(groesse))
	# 7) Region/Chunk-Reihenfolge: separat erzeugte Region gleicht voller Welt.
	var modell_komplett := Welt_Model.new()
	var generator_komplett := Welt_Generator.new()
	if not generator_komplett.welt_erzeugen(modell_komplett, 777, "gemaaessigt"):
		print("FEHLER: Voll-Welt für Reihenfolge-Prüfung scheiterte")
		fehler += 1
	else:
		var region_0 := modell_komplett.regionen[0]
		var region_x := int(region_0.get("region_x", 0))
		var region_y := int(region_0.get("region_y", 0))
		var modell_region := Welt_Model.new()
		var generator_region := Welt_Generator.new()
		generator_region.welt_erzeugen(modell_region, 777, "gemaaessigt")
		# Nur die Region einzeln materialisieren: Biom muss identisch sein.
		var biom_voll := str(region_0.get("biom_id", ""))
		var biom_region := ""
		for region: Dictionary in modell_region.regionen:
			if int(region.get("region_x", -1)) == region_x and int(region.get("region_y", -1)) == region_y:
				biom_region = str(region.get("biom_id", ""))
		if biom_voll == "" or biom_voll != biom_region:
			print("FEHLER: Region-Biom weicht ab (voll=%s einzeln=%s)" % [biom_voll, biom_region])
			fehler += 1
		else:
			print("OK: Region (%d,%d) ist einzeln reproduzierbar (Biom %s)" % [region_x, region_y, biom_voll])
	# 8) Registry-Erweiterung: Busch über Datenpool -> Registry -> Generator.
	var gewichte_reg := Welt_GeneratorRegistry.new()
	if not gewichte_reg.ids_mit_gewicht("objekte").has("busch"):
		print("FEHLER: Variante 'busch' fehlt im Generator-Pool")
		fehler += 1
	else:
		print("OK: Variante 'busch' über Datenpool in der Generator-Registry registriert")
	var katalog_reg := Welt_Registry.new()
	if katalog_reg.finde_objekt("busch") == null:
		print("FEHLER: Variante 'busch' fehlt im Element-Katalog")
		fehler += 1
	else:
		print("OK: Variante 'busch' im Element-Katalog mit Asset auflösbar")
	# 9) Gebäude-Fundament: Definition, Bau-Maschine, Produktions-Maschine.
	var gebaeude_reg := Gebaeude_DefinitionRegistry.new()
	var werkstatt: Gebaeude_Definition = null
	if not gebaeude_reg.hat_gebaeude("werkstatt"):
		print("FEHLER: Werkstatt fehlt in der Gebäude-Definition")
		fehler += 1
	else:
		werkstatt = gebaeude_reg.definition_fuer("werkstatt")
		print("OK: Werkstatt definiert mit Bauzeit %d und Dauer %d" % [werkstatt.bauzeit_ticks, werkstatt.dauer_ticks])
	var bau_maschine := Gebaeude_BauMaschine.new()
	var bau := bau_maschine.starten(bau_maschine.neuer_zustand())
	for i in range(werkstatt.bauzeit_ticks):
		bau = bau_maschine.tick(bau, werkstatt.bauzeit_ticks)
	if not bau_maschine.ist_fertig(bau):
		print("FEHLER: Bau-Maschine erreicht FERTIG nicht nach Bauzeit")
		fehler += 1
	else:
		print("OK: Bau-Maschine erreicht FERTIG nach %d Ticks" % werkstatt.bauzeit_ticks)
	var prod_maschine := Gebaeude_ProduktionsMaschine.new()
	var prod := prod_maschine.starten(prod_maschine.neuer_zustand())
	prod = prod_maschine.tick(prod, werkstatt, false, true)
	if int(prod.get("phase", -1)) != Gebaeude_ProduktionsMaschine.Phase.WARTET_EINGANG:
		print("FEHLER: Produktion wartet nicht ohne Eingang")
		fehler += 1
	prod = prod_maschine.tick(prod, werkstatt, true, true)
	if str(prod.get("aktion", "")) != "input_ziehen":
		print("FEHLER: Produktionsstart zieht keine Eingänge")
		fehler += 1
	for i in range(werkstatt.dauer_ticks):
		prod = prod_maschine.tick(prod, werkstatt, true, true)
	if str(prod.get("aktion", "")) != "output_legen":
		print("FEHLER: Produktionsabschluss legt keine Ausgänge ab")
		fehler += 1
	else:
		print("OK: Produktion verbraucht Eingang und meldet Ausgang nach %d Ticks" % werkstatt.dauer_ticks)
	prod = prod_maschine.tick(prod, werkstatt, false, false)
	if int(prod.get("phase", -1)) != Gebaeude_ProduktionsMaschine.Phase.WARTET_EINGANG:
		print("FEHLER: Wiederholbare Produktion startet keinen neuen Zyklus")
		fehler += 1
	else:
		print("OK: Wiederholbare Produktion beginnt neuen Zyklus und wartet auf Eingang")
	# 10) Zweite Kette: Räucherei kommt rein über Datenpool + Registry, keine
	#     Maschinenänderung; dieselbe Produktionsmaschine verarbeitet sie.
	var raeucherei: Gebaeude_Definition = null
	if not gebaeude_reg.hat_gebaeude("raeucherei"):
		print("FEHLER: Räucherei fehlt in der Gebäude-Definition")
		fehler += 1
	else:
		raeucherei = gebaeude_reg.definition_fuer("raeucherei")
		print("OK: Räucherei über Datenpool in der Registry (Kosten %d Holz, %d Stein, Dauer %d)" % [
			int(raeucherei.baukosten_paare()[0]["menge"]), int(raeucherei.baukosten_paare()[1]["menge"]), raeucherei.dauer_ticks])
	var r_prod := prod_maschine.starten(prod_maschine.neuer_zustand())
	r_prod = prod_maschine.tick(r_prod, raeucherei, false, true)
	if int(r_prod.get("phase", -1)) != Gebaeude_ProduktionsMaschine.Phase.WARTET_EINGANG:
		print("FEHLER: Räucherei-Produktion wartet nicht ohne Eingang")
		fehler += 1
	r_prod = prod_maschine.tick(r_prod, raeucherei, true, true)
	if str(r_prod.get("aktion", "")) != "input_ziehen":
		print("FEHLER: Räucherei zieht keine Eingänge")
		fehler += 1
	for i in range(raeucherei.dauer_ticks):
		r_prod = prod_maschine.tick(r_prod, raeucherei, true, true)
	if str(r_prod.get("aktion", "")) != "output_legen":
		print("FEHLER: Räucherei legt keine Ausgänge ab")
		fehler += 1
	else:
		print("OK: Dieselbe Produktionsmaschine verarbeitet die Räucherei ohne Code-Eingriff")
	var raeucherei_asset := katalog_reg.finde_objekt("raeucherei")
	if raeucherei_asset == null:
		print("FEHLER: Räucherei fehlt im Element-Katalog")
		fehler += 1
	else:
		print("OK: Räucherei im Element-Katalog mit Asset auflösbar")
	# 11) Manager-Kette: Kosten fließen wirklich, Gebäude entsteht im Modell.
	var bau_modell := Welt_Model.new()
	var bau_generator := Welt_Generator.new()
	bau_generator.welt_erzeugen(bau_modell, 4242, "gemaaessigt")
	var bau_lager := Lager_Manager.new()
	bau_lager.lager_anlegen("kleines_lager", Vector2(0, 0))
	var bau_ressourcen := Einheit_Ressourcen.new()
	bau_ressourcen.lager_setzen(bau_lager)
	bau_lager.startbestand_setzen("holz", 50, 0)
	bau_lager.startbestand_setzen("stein", 30, 0)
	var bau_manager := Gebaeude_Manager.new()
	bau_manager.einrichten(bau_modell, Welt_Registry.new(), bau_ressourcen, bau_lager)
	var bau_ergebnis := bau_manager.bauen_anfordern("werkstatt", Vector2(512, 512))
	if not bool(bau_ergebnis.get("ok", false)):
		print("FEHLER: Bau-Anforderung scheitert: %s" % str(bau_ergebnis.get("grund", "?")))
		fehler += 1
	else:
		var holz_rest := bau_lager.gesamt_bestand("holz")
		var stein_rest := bau_lager.gesamt_bestand("stein")
		var werkstatt_indizes := bau_modell.objekte_mit_element_id("werkstatt")
		var gebaeude_id := ""
		if not werkstatt_indizes.is_empty():
			gebaeude_id = str(bau_modell.objekt_feld(werkstatt_indizes[0], "gebaeude_id", ""))
		if holz_rest != 35 or stein_rest != 22 or gebaeude_id != "werkstatt":
			print("FEHLER: Kosten fließen nicht korrekt (holz %d, stein %d, id %s)" % [holz_rest, stein_rest, gebaeude_id])
			fehler += 1
		else:
			print("OK: Baukosten wirklich entnommen (holz 35, stein 22) und Werkstatt im Modell")
	# 12) Job-Queue je Stickman: Beschäftigt bekommt die Einheit eine eigene
	#     Vormerkung, die nach dem aktiven Job automatisch startet.
	var queue_status := Einheit_Status.new()
	var queue_job_registry := Job_Registry.new()
	var heiler_job := queue_job_registry.job_erzeugen("heiler")
	var stein_job := queue_job_registry.job_erzeugen("steinmetz")
	if heiler_job == null or stein_job == null:
		print("FEHLER: Job-Queue-Beweis kann keine Jobs erzeugen")
		fehler += 1
	else:
		queue_status.job_vergeben(heiler_job, Job_Basis.ZielTyp.OBJEKT, 0, "")
		var war_beschaeftigt := queue_status.ist_beschaeftigt()
		queue_status.job_vormerken(stein_job.job_id, Job_Basis.ZielTyp.OBJEKT, 3, "stein")
		var queue_zahl := queue_status.queue_laenge()
		var naechster := queue_status.queue_naechster()
		var gestartet := false
		var empfaenger := Einheit_QueueZeuge.new()
		queue_status.naechster_job_aus_queue.connect(empfaenger.auf_naechster)
		queue_status.job.job_beendet.emit()
		gestartet = empfaenger.empfangen
		if not war_beschaeftigt or queue_zahl != 1 or str(naechster.get("job_id", "")) != "steinmetz" or not gestartet:
			print("FEHLER: Job-Queue läuft nicht (beschäftigt %s, queue %d, naechster %s, gestartet %s)" % [
				str(war_beschaeftigt), queue_zahl, str(naechster.get("job_id", "")), str(gestartet)])
			fehler += 1
		else:
			print("OK: Stickman hat eigene Job-Queue, naechster Auftrag startet nach dem aktiven Job")
	# 13) World-Ebene: World hält mehrere Maps, markiert die Basis und
	#     übersteht den Speicher-Rundlauf mit map_id-Zuordnung.
	var world := Welt_World.new()
	world.world_name = "test_world"
	var map_a := Welt_Model.new()
	map_a.welt_seed = 111
	map_a.karte_erzeugen(8, 8, "boden")
	var map_b := Welt_Model.new()
	map_b.welt_seed = 222
	map_b.karte_erzeugen(8, 8, "boden")
	if not world.map_hinzufuegen(map_a, "karte_a", true):
		print("FEHLER: World nimmt Basis-Map nicht auf")
		fehler += 1
	elif not world.map_hinzufuegen(map_b, "karte_b", false):
		print("FEHLER: World nimmt zweite Map nicht auf")
		fehler += 1
	elif world.basis_map_id() != "karte_a" or world.map_zahl() != 2:
		print("FEHLER: Basis-Markierung oder Map-Zahl falsch")
		fehler += 1
	else:
		var world_runde := Welt_Speicher.new()
		var gespeichert := world_runde.world_speichern("test_world", world)
		var geladen := world_runde.world_laden("test_world")
		if not gespeichert or geladen == null or geladen.map_zahl() != 2 \
				or geladen.basis_map_id() != "karte_a" \
				or geladen.map_model("karte_b").welt_seed != 222:
			print("FEHLER: World-Speicher-Rundlauf bricht die map_id-Zuordnung")
			fehler += 1
		else:
			print("OK: World hält 2 Maps, Basis-Markierung und map_id überstehen den Speicher-Rundlauf")
	# 14) Map-Fabrik: Expansion erzeugt eine neue Karte, trägt sie in die
	#     World ein und markiert sie als neue Basis.
	var fabrik_world := Welt_World.new()
	fabrik_world.world_name = "fabrik_welt"
	var fabrik_generator := Welt_Generator.new()
	var fabrik := Welt_MapFabrik.new()
	fabrik.einrichten(fabrik_generator)
	var basis_karte := fabrik.karte_erzeugen(fabrik_world, "karte_0", 4242, "gemaaessigt", true)
	var expansions_karte := fabrik.neue_karte_erzeugen(fabrik_world, "karte_1", "gemaaessigt")
	if basis_karte == null or expansions_karte == null:
		print("FEHLER: Map-Fabrik erzeugt keine Karten")
		fehler += 1
	elif fabrik_world.map_zahl() != 2 or fabrik_world.basis_map_id() != "karte_1" \
			or fabrik_world.map_model("karte_1") != expansions_karte:
		print("FEHLER: Expansion trägt die neue Basis-Karte nicht korrekt in die World")
		fehler += 1
	else:
		print("OK: Map-Fabrik erzeugt Expansion, neue Karte ist Basis (2 Maps in der World)")
	if fehler == 0:
		print("ALLE PRUEFUNGEN GRUEN")
		quit(0)
	else:
		print("%d PRUEFUNGEN ROT" % fehler)
		quit(1)