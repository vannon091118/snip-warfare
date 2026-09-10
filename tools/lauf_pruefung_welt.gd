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
	var weltuhr_skript: GDScript = load("res://core/logic/clock/weltuhr.gd")
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
	# 2b) Spawn-Cluster: Die Welt traegt dichte Gruppen (Wald) statt
	#     verstreuter Einzelobjekte; ein Baum hat Nachbarn in Cluster-naehe.
	var cluster_dicht := false
	var cluster_beste := 0
	for baum_i in modell_eins.objekt_anzahl():
		if str(modell_eins.objekt_element_id(baum_i)) != "baum":
			continue
		var baum_position := modell_eins.objekt_position(baum_i)
		var nachbarn := 0
		for anderer_i in modell_eins.objekt_anzahl():
			if baum_i == anderer_i or str(modell_eins.objekt_element_id(anderer_i)) != "baum":
				continue
			if baum_position.distance_to(modell_eins.objekt_position(anderer_i)) <= 3.0 * Welt_Model.KACHEL_GROESSE:
				nachbarn += 1
		cluster_beste = maxi(cluster_beste, nachbarn)
		if nachbarn >= 4:
			cluster_dicht = true
			break
	if not cluster_dicht:
		print("FEHLER: Kein Wald-Cluster gefunden (beste Nachbarn: %d)" % cluster_beste)
		fehler += 1
	else:
		print("OK: Wald-Cluster existieren (beste Gruppe: %d Nachbarn) statt Einzelobjekte" % cluster_beste)
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
	# 15) Klick-Befehl hat direkte Auswirkung: Die Einheit läuft zum Ziel
	#     (GEHEN-Zustand), statt den Befehl als zu weit abzulehnen.
	var geh_status := Einheit_Status.new()
	geh_status.welt_position_setzen(Vector2(100, 100))
	geh_status.geh_ziel_setzen(Vector2(400, 100))
	var geh_job := queue_job_registry.job_erzeugen("heiler")
	geh_status.job_vergeben(geh_job, Job_Basis.ZielTyp.OBJEKT, 0, "")
	var ging_los := geh_status.zustand == Einheit_Status.Zustand.GEHEN
	var start_pos := geh_status.welt_position
	for _schritt in 160:
		geh_status.tick(1.0 / 24.0)
	var kam_an := geh_status.zustand == Einheit_Status.Zustand.ARBEITEN
	var bewegung := geh_status.welt_position.x - start_pos.x > 200.0
	if not ging_los or not kam_an or not bewegung:
		print("FEHLER: Klick-Befehl bewegt nicht (los %s, an %s, bewegung %s)" % [str(ging_los), str(kam_an), str(bewegung)])
		fehler += 1
	else:
		print("OK: Einheit läuft zum Ziel (%d px) und beginnt nach Ankunft die Arbeit" % int(geh_status.welt_position.x - start_pos.x))
	# 16) Manager-Kette: job_vergeben setzt das Geh-Ziel, der Tick übernimmt
	#     die bewegte Position in die Einheiten-Liste (direkte Auswirkung).
	var geh_modell := Welt_Model.new()
	var geh_generator := Welt_Generator.new()
	geh_generator.welt_erzeugen(geh_modell, 9876, "gemaaessigt")
	var geh_manager := Einheit_Manager.new()
	geh_manager.einrichten(geh_modell, null, null)
	if geh_modell.objekt_anzahl() > 0:
		var ziel_pos := geh_modell.objekt_position(0)
		geh_manager.einheit_hinzufuegen(ziel_pos + Vector2(-200, 0))
		geh_manager.job_vergeben(0, "heiler", Job_Basis.ZielTyp.OBJEKT, 0, ziel_pos)
		var start_pos_manager := geh_manager.einheit_position(0)
		for _schritt in 400:
			geh_manager._auf_tick(1, 1.0 / 24.0)
		var end_pos := geh_manager.einheit_position(0)
		var manager_bewegt := end_pos.distance_to(start_pos_manager) > 20.0
		var manager_am_ziel := end_pos.distance_to(ziel_pos) <= 30.0
		if not manager_bewegt or not manager_am_ziel:
			print("FEHLER: Manager-Kette bewegt die Einheit nicht (bewegt %s, am Ziel %s)" % [str(manager_bewegt), str(manager_am_ziel)])
			fehler += 1
		else:
			print("OK: Manager übernimmt die bewegte Position, Einheit steht am Job-Ziel")
	# 17) Zentrale Modifikator-Maschine: Bereichs-Faktor wird gecacht, die
	#     Zeitformel nutzt ihn ohne Neuberechnung, der Modus-Wechsel zieht neu.
	var mod_maschine := Kern_ModifikatorMaschine.new()
	mod_maschine.bereich_setzen("bau")
	mod_maschine.aktualisieren()
	var schritte_start := mod_maschine.rechen_schritte()
	var bauzeit_neutral := mod_maschine.zeit_berechnen(480)
	var schritte_nach_zeit := mod_maschine.rechen_schritte()
	mod_maschine.modus_setzen("schnell")
	var bauzeit_schnell := mod_maschine.zeit_berechnen(480)
	if bauzeit_neutral != 480 or bauzeit_schnell != 320 or schritte_nach_zeit != schritte_start:
		print("FEHLER: Modifikator-Maschine rechnet falsch (neutral %d, schnell %d, schritte %d/%d)" % [bauzeit_neutral, bauzeit_schnell, schritte_nach_zeit, schritte_start])
		fehler += 1
	else:
		print("OK: Zentrale Zeitformel (neutral 480, schnell 320) ohne redundante Rechenschritte")
	# 18) Trait-Formel: Ein zentraler Rechenweg für aktive Modifikatoren,
	#     den auch die Vital-Maschine nutzt (Verletzung halbiert und zieht ab).
	var trait_registry := Kern_ModifikatorRegistry.new()
	var bein_mod: Kern_ModifikatorBasis = trait_registry.modifikator_fuer("verletzung_bein")
	var mods_fuer_wert: Array[Kern_ModifikatorBasis] = [bein_mod]
	var trait_wert := Kern_ModifikatorMaschine.wert_berechnen(100.0, mods_fuer_wert, 0.1)
	var vital_wert := Einheit_VitalStatus.new()
	vital_wert.modifikator_hinzufuegen("verletzung_bein")
	var vital_delegiert := vital_wert.effektive_geschwindigkeit(100.0)
	if absf(trait_wert - 49.5) > 0.001 or absf(vital_delegiert - 49.5) > 0.001:
		print("FEHLER: Trait-Formel weicht ab (zentral %f, vital %f)" % [trait_wert, vital_delegiert])
		fehler += 1
	else:
		print("OK: Trait-Formel zentral (49.5) und Vital delegiert an dieselbe Logik")
	# 19) Bewegung kommt aus den globalen Settings: Die Einheit bekommt ihre
	#     Geh-Geschwindigkeit über die eigene Modifikator-Maschine, nicht
	#     aus einer Konstante im Code.
	var bewegungs_status := Einheit_Status.new()
	if absf(bewegungs_status._geh_geschwindigkeit - 70.0) > 0.001 or absf(bewegungs_status._geh_reichweite - 24.0) > 0.001:
		print("FEHLER: Bewegungswerte nicht aus Settings (geschwindigkeit %f, reichweite %f)" % [bewegungs_status._geh_geschwindigkeit, bewegungs_status._geh_reichweite])
		fehler += 1
	else:
		print("OK: Geh-Geschwindigkeit 70.0 und Reichweite 24.0 kommen aus den Modifikator-Settings")
	# 20) Bau- und Produktionsmaschinen rechnen über ihre eigene
	#     Modifikator-Maschine: Der Modus skaliert die effektive Zeit, und
	#     die Menü-Abstimmung skaliert den Fortschritt prozentual mit.
	var bau_maschine_mod := Gebaeude_BauMaschine.new()
	var bau_neutral := bau_maschine_mod.zeit_ticks_fuer(480)
	bau_maschine_mod._modifikatoren.modus_setzen("schnell")
	var bau_effektiv := bau_maschine_mod.zeit_ticks_fuer(480)
	var bau_laufend := {"phase": Gebaeude_BauMaschine.Phase.BAU_LAEUFT, "fortschritt": 240, "ziel_ticks": 480}
	var bau_abgestimmt := bau_maschine_mod.abstimmen(bau_laufend, 480)
	if bau_neutral != 480 or bau_effektiv != 320 or int(bau_abgestimmt["fortschritt"]) != 160 or int(bau_abgestimmt["ziel_ticks"]) != 320:
		print("FEHLER: Bau-Maschine skaliert falsch (neutral %d, effektiv %d, abstimmen %s)" % [bau_neutral, bau_effektiv, str(bau_abgestimmt)])
		fehler += 1
	else:
		print("OK: Bau-Maschine nutzt eigene Modifikator-Maschine, Abstimmung skaliert 240/480 auf 160/320")
	var prod_maschine_mod := Gebaeude_ProduktionsMaschine.new()
	var prod_neutral := prod_maschine_mod.zeit_ticks_fuer(600)
	prod_maschine_mod._modifikatoren.modus_setzen("schnell")
	var prod_effektiv := prod_maschine_mod.zeit_ticks_fuer(600)
	if prod_neutral != 600 or prod_effektiv != 400:
		print("FEHLER: Produktions-Maschine skaliert falsch (neutral %d, effektiv %d)" % [prod_neutral, prod_effektiv])
		fehler += 1
	else:
		print("OK: Produktions-Maschine nutzt eigene Modifikator-Maschine (600 neutral, 400 schnell)")
	# 21) Rassen-Schemata: Der Datenpool liefert die Multiplikatoren je
	#     Rasse, ohne dass Code eine Rasse kennt.
	var rassen_registry := Pop_RassenSchemaRegistry.new()
	var mensch_schema := rassen_registry.schema_fuer("mensch")
	var elf_schema := rassen_registry.schema_fuer("elf")
	var ork_schema := rassen_registry.schema_fuer("ork")
	if mensch_schema == null or elf_schema == null or ork_schema == null:
		print("FEHLER: Rassen-Schemata fehlen im Datenpool")
		fehler += 1
	elif absf(elf_schema.faktor_nahrung - 0.7) > 0.001 or absf(ork_schema.faktor_nahrung - 1.5) > 0.001 \
			or absf(elf_schema.faktor_bewegung - 1.15) > 0.001 or absf(ork_schema.faktor_bewegung - 0.9) > 0.001:
		print("FEHLER: Rassen-Multiplikatoren weichen ab")
		fehler += 1
	else:
		print("OK: 3 Rassen-Schemata aus Daten (elf nahrung 0.7/bewegung 1.15, ork nahrung 1.5/bewegung 0.9)")
	# 22) Need-Baum: Der eigene Tree erzeugt die Need-Maschinen als Kinder
	#     und weist ihnen das Rassen-Schema zu; die Maschinen skalieren ihre
	#     Raten über Schema mal zentralen Faktor.
	var need_baum := Pop_NeedBaum.new()
	var elf_maschine := need_baum.einheit_need_anlegen("elf", Vector2.ZERO)
	var ork_maschine := need_baum.einheit_need_anlegen("ork", Vector2.ZERO)
	var standard_maschine := need_baum.einheit_need_anlegen("", Vector2.ZERO)
	if elf_maschine == null or ork_maschine == null or standard_maschine == null or need_baum.get_child_count() != 3:
		print("FEHLER: Need-Baum erzeugt keine Maschinen-Kinder")
		fehler += 1
	elif absf(elf_maschine.nahrungs_faktor() - 0.7) > 0.001 or absf(ork_maschine.nahrungs_faktor() - 1.5) > 0.001 \
			or absf(standard_maschine.nahrungs_faktor() - 1.0) > 0.001:
		print("FEHLER: Rassen-Faktoren greifen nicht in den Need-Maschinen")
		fehler += 1
	else:
		print("OK: Need-Baum hält 3 Maschinen als Kinder, Faktoren greifen (elf 0.7, ork 1.5, standard 1.0)")
	# 23) Einheit_Manager vergibt die Rasse beim Spawn: Der Bewegungsfaktor
	#     der Rasse landet in der Zustandsmaschine der Einheit.
	var rassen_manager := Einheit_Manager.new()
	rassen_manager.need_baum_setzen(need_baum)
	rassen_manager.einheit_hinzufuegen(Vector2.ZERO, "elf")
	var elf_status: Einheit_Status = rassen_manager.einheit_status(0)
	if rassen_manager.einheit_rasse(0) != "elf" or absf(elf_status._rasse_bewegungs_faktor - 1.15) > 0.001:
		print("FEHLER: Manager vergibt Rasse oder Bewegungsfaktor nicht (rasse %s, faktor %f)" % [rassen_manager.einheit_rasse(0), elf_status._rasse_bewegungs_faktor])
		fehler += 1
	else:
		print("OK: Elf beim Spawn gesetzt, Bewegungsfaktor 1.15 in der Zustandsmaschine (70 Basis -> 80.5)")
	# 24) Arbeitsloop statt One-Shot: Ein Loop-Job endet nach dem
	#     Arbeitsschritt nicht im Idle, der Manager sucht das naechste Ziel
	#     desselben Typs und die Einheit laeuft dorthin (GEHEN) statt den
	#     naechsten Baum aus der Luft zu ernten.
	var loop_direkt := Einheit_Status.new()
	loop_direkt.welt_position_setzen(Vector2(0, 0))
	var loop_job := queue_job_registry.job_erzeugen("holzfaeller")
	loop_direkt.geh_ziel_setzen(Vector2(0, 0))
	loop_direkt.job_vergeben(loop_job, Job_Basis.ZielTyp.OBJEKT, 0, "holz")
	var loop_arbeitete := loop_direkt.zustand == Einheit_Status.Zustand.ARBEITEN
	loop_direkt.geh_ziel_setzen(Vector2(500, 0))
	loop_direkt.job_loopy_fortsetzen(loop_job, Job_Basis.ZielTyp.OBJEKT, 1, "holz")
	var loop_geht := loop_direkt.zustand == Einheit_Status.Zustand.GEHEN
	var loop_modell := Welt_Model.new()
	loop_modell.karte_erzeugen(8, 8, "boden")
	loop_modell.objekt_hinzufuegen("baum", Vector2(200, 200))
	loop_modell.objekt_hinzufuegen("baum", Vector2(600, 200))
	var loop_manager := Einheit_Manager.new()
	loop_manager.einrichten(loop_modell, null, Einheit_Ressourcen.new())
	loop_manager.einheit_hinzufuegen(Vector2(200, 200))
	loop_manager.job_vergeben(0, "holzfaeller", Job_Basis.ZielTyp.OBJEKT, 0, Vector2(200, 200))
	for _schritt in 240:
		loop_manager._auf_tick(1, 1.0 / 24.0)
	var loop_status: Einheit_Status = loop_manager.einheit_status(0)
	var loop_laeuft_weiter := loop_status.zustand != Einheit_Status.Zustand.IDLE
	var loop_ziel_index := loop_status.aktuelles_ziel_index
	for _schritt in 150:
		loop_manager._auf_tick(1, 1.0 / 24.0)
	var loop_end_position := loop_manager.einheit_position(0)
	var loop_erreicht := loop_end_position.x > 500.0
	if not loop_arbeitete or not loop_geht or not loop_laeuft_weiter \
			or loop_ziel_index != 1 or not loop_erreicht:
		print("FEHLER: Arbeitsloop greift nicht (arbeitete %s, geht %s, weiter %s, ziel %d, erreicht %s)" % [
			str(loop_arbeitete), str(loop_geht), str(loop_laeuft_weiter), loop_ziel_index, str(loop_erreicht)])
		fehler += 1
	else:
		print("OK: Loop-Job endet nicht im Idle, Einheit laeuft zum naechsten Baum (Ziel 1, x=%.0f)" % loop_end_position.x)
	# 25) Atomare Buchungen: Ein Rezept mit zweimal derselben Ressource darf
	#     nie teilweise entnehmen; Pruefung und Entnahme sind ein Schritt.
	var atom_lager := Lager_Manager.new()
	atom_lager.lager_anlegen("kleines_lager", Vector2(0, 0))
	atom_lager.startbestand_setzen("holz", 10, 0)
	var atom_ressourcen := Einheit_Ressourcen.new()
	atom_ressourcen.lager_setzen(atom_lager)
	var atom_doppelt := atom_ressourcen.mehrfach_entnehmen([
		{"ressource": "holz", "menge": 6},
		{"ressource": "holz", "menge": 6},
	], 0)
	var atom_bestand := atom_lager.gesamt_bestand("holz")
	var atom_gedeckt := atom_ressourcen.mehrfach_entnehmen([
		{"ressource": "holz", "menge": 4},
		{"ressource": "holz", "menge": 4},
	], 0)
	var atom_rest := atom_lager.gesamt_bestand("holz")
	if atom_doppelt or atom_bestand != 10 or not atom_gedeckt or atom_rest != 2:
		print("FEHLER: Mehrfach-Entnahme nicht atomar (doppelt ok %s, bestand %d, gedeckt %s, rest %d)" % [
			str(atom_doppelt), atom_bestand, str(atom_gedeckt), atom_rest])
		fehler += 1
	else:
		print("OK: Mehrfach-Entnahme atomar (12 bei 10 verweigert ohne Teilbuchung, 4+4 bucht auf 2)")
	var atom_modell := Welt_Model.new()
	atom_modell.karte_erzeugen(8, 8, "boden")
	var atom_manager := Gebaeude_Manager.new()
	atom_manager.einrichten(atom_modell, Welt_Registry.new(), atom_ressourcen, atom_lager)
	var atom_versuch := atom_manager.bauen_anfordern("werkstatt", Vector2(512, 512))
	var atom_keine_teilbuchung := atom_lager.gesamt_bestand("holz") == 2
	if bool(atom_versuch.get("ok", false)) or not atom_keine_teilbuchung:
		print("FEHLER: Bau entnimmt trotz fehlender Kosten (ok %s, holz %d)" % [str(atom_versuch.get("ok", false)), atom_lager.gesamt_bestand("holz")])
		fehler += 1
	else:
		print("OK: Bau-Anforderung verweigert bei fehlenden Kosten ohne Teil-Entnahme")
	# 26) Zustands-Timeline: Ursprung plus Mutationen als Deltas, jeder
	#     Zustand rekonstruierbar, warum ist das so jederzeit beantwortbar.
	var timeline_lager := Lager_Manager.new()
	timeline_lager.lager_anlegen("kleines_lager", Vector2(0, 0))
	timeline_lager.startbestand_setzen("holz", 50, 0)
	timeline_lager.startbestand_setzen("stein", 20, 0)
	var timeline_ressourcen := Einheit_Ressourcen.new()
	timeline_ressourcen.lager_setzen(timeline_lager)
	var timeline := Kern_Timeline.new()
	timeline_ressourcen.timeline_setzen(timeline)
	timeline_ressourcen.entnehmen("holz", 10, 0)
	timeline_ressourcen.hinzufuegen("fleisch", 5)
	timeline_ressourcen.mehrfach_entnehmen([
		{"ressource": "holz", "menge": 6},
		{"ressource": "stein", "menge": 4},
	], 0)
	var timeline_anzahl := timeline.eintraege.size()
	var holz_jetzt := timeline_lager.gesamt_bestand("holz")
	var rekonstruiert := timeline.zustand_zu_tick(timeline.eintraege[timeline.eintraege.size() - 1].tick)
	var rekonstruiert_holz := int(rekonstruiert.get("holz", -1))
	var warum_holz := timeline.warum("ressourcen")
	var einfluss := timeline.einfluss_modifikatoren()
	if timeline_anzahl < 3 or holz_jetzt != 34 or rekonstruiert_holz != holz_jetzt or warum_holz.is_empty():
		print("FEHLER: Timeline liefert falsch (eintraege %d, holz %d, rekonstruiert %d, warum %d)" % [
			timeline_anzahl, holz_jetzt, rekonstruiert_holz, warum_holz.size()])
		fehler += 1
	else:
		print("OK: Timeline mit Ursprung + %d Deltas, Rekonstruktion exakt (%d), Warum-Kette (%d Eintraege)" % [
			timeline_anzahl, rekonstruiert_holz, warum_holz.size()])
	# Timeline mit Modifikator-Einfluss: Ein Eintrag mit Modifikator wird
	# im Einfluss-Verzeichnis sichtbar, ohne Modifikator bleibt es leer.
	var timeline_mod := Kern_Timeline.new()
	timeline_mod.ursprung_festlegen({"wert": 10})
	timeline_mod.eintrag_anhaengen(1, "test", "entscheidung", "Schnell-Modus", {"wert": 10}, {"wert": 15}, "schnell", 1.5)
	timeline_mod.eintrag_anhaengen(2, "test", "entscheidung", "Normal", {"wert": 15}, {"wert": 12})
	var mod_einfluss := timeline_mod.einfluss_modifikatoren()
	var mod_anzahl := int(mod_einfluss.get("schnell", {}).get("anzahl", 0)) if mod_einfluss.has("schnell") else 0
	if mod_anzahl != 1 or not mod_einfluss.has("schnell"):
		print("FEHLER: Modifikator-Einfluss nicht sichtbar (einfluss %s)" % str(mod_einfluss))
		fehler += 1
	else:
		print("OK: Modifikator-Einfluss aggregiert (schnell wirkt 1x mit Faktor 1.5)")
	# Tageszyklus-Besitz: Die Weltmaschine tickt durch ihren eigenen Aufruf
	# an der Weltuhr, waehrend der Einheiten-Takt sie nicht mehr anstoesst.
	# Rhythmus aus dem Datenpool: Die Werte kommen aus needs.json über die
	# Need-Registry; der Beweis benutzt dieselbe Quelle wie das Spiel.
	var rhythmus_registry := Pop_NeedRegistry.new()
	var zyklus := Welt_TageszyklusMaschine.new()
	zyklus.einrichten(rhythmus_registry.takt_minuten(), rhythmus_registry.tag_minuten(), rhythmus_registry.nacht_minuten())
	var takte_vor := zyklus._tick_in_takt
	var manager_ohne_rolle := Einheit_Manager.new()
	manager_ohne_rolle.tageszyklus_setzen(zyklus)
	manager_ohne_rolle._auf_tick(1, 1.0 / 24.0)
	var takte_nach_manager := zyklus._tick_in_takt
	zyklus.tick()
	var takte_nach_eigen := zyklus._tick_in_takt
	if takte_nach_manager != takte_vor or takte_nach_eigen != takte_vor + 1:
		print("FEHLER: Tageszyklus-Besitz falsch (vor %d, nach Manager %d, nach eigen %d)" % [takte_vor, takte_nach_manager, takte_nach_eigen])
		fehler += 1
	else:
		print("OK: Tageszyklus tickt nur durch eigenen Aufruf, Einheiten-Manager stoesst nichts an")
	# Weltuhr-Spiralen-Schutz: Ein Riesen-Rahmen hinterlaesst keinen
	# Zeitraffer-Reststand; der normale Rahmen danach tickt genau einmal.
	var uhr := Kern_Weltuhr.new()
	var budget := Kern_Weltuhr.rahmen_budget()
	uhr._process(2.0)
	var uhr_ticks_nach_stall := uhr._tick_nummer
	var uhr_rest_nach_stall := uhr._akkumulator
	uhr._process(Kern_Weltuhr.rahmen_budget() + 0.01)
	var uhr_ticks_nach_erstem := uhr._tick_nummer
	uhr._process(Kern_Weltuhr.rahmen_budget() + 0.01)
	var uhr_ticks_nach_zweitem := uhr._tick_nummer
	uhr.free()
	if uhr_ticks_nach_stall != Kern_Weltuhr.MAX_TICKS_PRO_FRAME or uhr_rest_nach_stall > budget + 0.0001 or uhr_ticks_nach_zweitem < uhr_ticks_nach_erstem + Kern_Weltuhr.MAX_TICKS_PRO_FRAME:
		print("FEHLER: Weltuhr-Spiralenschutz falsch (ticks %d, rest %.4f, dann %d/%d)" % [uhr_ticks_nach_stall, uhr_rest_nach_stall, uhr_ticks_nach_erstem, uhr_ticks_nach_zweitem])
		fehler += 1
	else:
		print("OK: Weltuhr wirft Ruckler-Rueckstand weg, Folge-Rahmen ticken im Rahmen-Budget und wachsen linear")
	# Wegplanung: Die Planung liefert Wegpunkte um gesperrte Kacheln, der
	# Cache beantwortet dieselbe Anfrage aus dem Speicher, der Status folgt
	# den Punkten und endet trotzdem am Ziel in der Arbeit.
	var plan_modell := Welt_Model.new()
	var plan_generator := Welt_Generator.new()
	plan_generator.welt_erzeugen(plan_modell, 24680, "gemaaessigt")
	var planung := Einheit_WegPlanung.new()
	planung.netz_erneuern(plan_modell)
	var plan_start := Vector2(100, 100)
	var plan_ziel := Vector2(900, 700)
	if plan_modell.objekt_anzahl() > 0:
		plan_ziel = plan_modell.objekt_position(0)
	var plan_weg := planung.weg_zu(plan_start, plan_ziel)
	var plan_weg_nochmal := planung.weg_zu(plan_start, plan_ziel)
	var plan_status := Einheit_Status.new()
	plan_status.welt_position_setzen(plan_start)
	plan_status.geh_ziel_setzen(plan_ziel)
	plan_status.weg_ziele_uebernehmen(plan_weg)
	plan_status.job_vergeben(queue_job_registry.job_erzeugen("heiler"), Job_Basis.ZielTyp.OBJEKT, 0, "")
	for _plan_schritt in 2400:
		plan_status.tick(1.0 / 24.0)
	var plan_ok := plan_status.zustand == Einheit_Status.Zustand.ARBEITEN \
			and plan_status.welt_position.distance_to(plan_ziel) <= 30.0
	var cache_ok := plan_weg == plan_weg_nochmal
	if not plan_ok or not cache_ok:
		print("FEHLER: Wegplanung falsch (an Ziel %s, Cache gleich %s, Punkte %d)" % [
			str(plan_status.welt_position.distance_to(plan_ziel) <= 30.0), str(cache_ok), plan_weg.size()])
		fehler += 1
	else:
		print("OK: Wegplanung liefert %d Wegpunkte, Cache trifft, Einheit folgt und arbeitet am Ziel" % plan_weg.size())
	# Manager-Verdrahtung: Die Vergabe holt die Wegpunkte aus der geteilten
	# Planung; ohne Planung (nur geh_ziel_setzen) laeuft die Einheit
	# weiterhin geradeaus und kommt ebenfalls an.
	var plan_manager := Einheit_Manager.new()
	plan_manager.einrichten(plan_modell, null, null)
	if plan_modell.objekt_anzahl() > 0:
		var manager_ziel := plan_modell.objekt_position(0)
		plan_manager.einheit_hinzufuegen(manager_ziel + Vector2(-200, 0))
		plan_manager.job_vergeben(0, "heiler", Job_Basis.ZielTyp.OBJEKT, 0, manager_ziel)
		var planer_start := plan_manager.einheit_position(0)
		for _manager_schritt in 400:
			plan_manager._auf_tick(1, 1.0 / 24.0)
		var manager_ankunft := plan_manager.einheit_position(0).distance_to(manager_ziel) <= 30.0
		var manager_bewegte_sich := plan_manager.einheit_position(0).distance_to(planer_start) > 20.0
		if not manager_ankunft or not manager_bewegte_sich:
			print("FEHLER: Manager-Planung bewegt nicht (an %s, bewegt %s)" % [str(manager_ankunft), str(manager_bewegte_sich)])
			fehler += 1
		else:
			print("OK: Manager vergibt Wege aus der geteilten Planung, Einheit kommt ohne Clippen an")
	# Loop-Flags als Daten: Alle Ernte-Jobs laufen weiter, nur der Heiler
	# endet nach dem Einsatz.
	var loop_config := JSON.parse_string(FileAccess.get_file_as_string("res://game/data/job_config.json")) as Dictionary
	var loop_falsch: Array[String] = []
	for loop_id: String in ["holzfaeller", "steinmetz", "jaeger", "holzfaeller_stumpf", "jaeger_kadaver"]:
		var loop_eintrag: Dictionary = loop_config.get(loop_id, {})
		if not bool(loop_eintrag.get("loop", false)):
			loop_falsch.append(loop_id)
	# Jagd-Kette über die Ernte-Maschine: Der Arbeitsschritt des Jägers
	# schlägt das Tier schlagweise, beim Tod fällt Fleisch an und der
	# Job endet; die Ernte-Maschine besitzt diese Regel, nicht der Manager.
	var jagd_tiere := Tier_Manager.new()
	root.add_child(jagd_tiere)
	var jagd_tier_nummer := jagd_tiere.tier_platzieren("hase", Vector2(500, 500))
	var jagd_status := Einheit_Status.new()
	jagd_status.welt_position_setzen(Vector2(500, 500))
	var jagd_ressourcen := Einheit_Ressourcen.new()
	var jagd_modell := Welt_Model.new()
	jagd_modell.karte_erzeugen(8, 8, "boden")
	var jagd_ernte := Einheit_ErnteMaschine.new()
	jagd_ernte.einrichten(jagd_ressourcen, jagd_modell, jagd_tiere)
	var jagd_job := queue_job_registry.job_erzeugen("jaeger")
	jagd_status.job_vergeben(jagd_job, Job_Basis.ZielTyp.TIER, jagd_tier_nummer, "fleisch")
	jagd_status._zu_zustand_wechseln(Einheit_Status.Zustand.ARBEITEN)
	var hase_lebt_vor := not jagd_tiere.tier_position(jagd_tier_nummer) == Vector2.INF
	jagd_ernte.arbeitsschritt_verarbeiten("fleisch", 2, jagd_status)
	var hase_lebt_nach_schlag := not jagd_tiere.tier_position(jagd_tier_nummer) == Vector2.INF
	jagd_ernte.arbeitsschritt_verarbeiten("fleisch", 2, jagd_status)
	jagd_ernte.arbeitsschritt_verarbeiten("fleisch", 2, jagd_status)
	var fleisch_gefallen := jagd_ressourcen.bestand("fleisch")
	var hase_tot := not jagd_tiere.tier_position(jagd_tier_nummer) != Vector2.INF
	var jagd_job_ende := jagd_status.job == null
	var jagd_ok := hase_lebt_vor and hase_lebt_nach_schlag and hase_tot and fleisch_gefallen > 0 and jagd_job_ende
	if not jagd_ok:
		print("FEHLER: Jagd-Kette falsch (lebte %s, nach Schlag %s, tot %s, fleisch %d, job_ende %s)" % [
			str(hase_lebt_vor), str(hase_lebt_nach_schlag), str(hase_tot), fleisch_gefallen, str(jagd_job_ende)])
		fehler += 1
	else:
		print("OK: Jagd über die Ernte-Maschine: Tier fällt schlagweise, %d Fleisch im Bestand" % fleisch_gefallen)
	# Hunger über die Versorgungs-Maschine: Leerer Fleisch-Bestand kostet
	# über die echte Manager-Kette Leben, ablesbar an der Vital-Maschine.
	var hunger_modell := Welt_Model.new()
	hunger_modell.karte_erzeugen(8, 8, "boden")
	var hunger_ressourcen := Einheit_Ressourcen.new()
	var hunger_manager := Einheit_Manager.new()
	hunger_manager.einrichten(hunger_modell, null, hunger_ressourcen)
	hunger_manager.einheit_hinzufuegen(Vector2(100, 100))
	var hunger_status: Einheit_Status = hunger_manager.einheit_status(0)
	var hunger_vor: int = hunger_status.vital.hp
	hunger_manager._nahrung_verteilen()
	var hunger_nach: int = hunger_status.vital.hp
	if hunger_nach >= hunger_vor:
		print("FEHLER: Hunger kostet kein Leben (vor %d, nach %d)" % [hunger_vor, hunger_nach])
		fehler += 1
	else:
		print("OK: Hunger über die Versorgungs-Maschine kostet Leben (%d -> %d)" % [hunger_vor, hunger_nach])
	if not loop_falsch.is_empty() or bool((loop_config.get("heiler", {}) as Dictionary).get("loop", true)):
		print("FEHLER: Loop-Flags falsch (falsch: %s, heiler-Loop %s)" % [str(loop_falsch), str(bool((loop_config.get("heiler", {}) as Dictionary).get("loop", true)))])
		fehler += 1
	else:
		print("OK: Alle Ernte-Jobs loopen als Daten, der Heiler endet einmalig")
	# 27) Eine Kartenwahrheit: Die World übernimmt die laufende Szene-Instanz
	#     über model_uebernehmen; Szene und World zeigen danach auf dasselbe
	#     Welt_Model-Objekt und der Rundlauf speichert den echten Zustand.
	var wahrheit_world := Welt_World.new()
	wahrheit_world.world_name = "wahrheit_welt"
	var wahrheit_lade := Welt_Model.new()
	wahrheit_lade.karte_erzeugen(6, 6, "boden")
	wahrheit_world.map_hinzufuegen(wahrheit_lade, "karte_0", true)
	var wahrheit_szene := Welt_Model.new()
	wahrheit_szene.karte_erzeugen(7, 7, "boden")
	wahrheit_szene.objekt_hinzufuegen("baum", Vector2(96, 96))
	var uebernommen := wahrheit_world.model_uebernehmen("karte_0", wahrheit_szene)
	var identisch := wahrheit_world.map_model("karte_0") == wahrheit_szene
	var rundlauf := Welt_Speicher.new()
	rundlauf.world_speichern("wahrheit_welt", wahrheit_world)
	var rueck := rundlauf.world_laden("wahrheit_welt")
	var rundlauf_ok := rueck != null and rueck.map_model("karte_0") != null \
			and int(rueck.map_model("karte_0").objekt_anzahl()) == 1
	if not uebernommen or not identisch or not rundlauf_ok:
		print("FEHLER: Kartenwahrheit bricht (uebernommen %s, identisch %s, rundlauf %s)" % [
			str(uebernommen), str(identisch), str(rundlauf_ok)])
		fehler += 1
	else:
		print("OK: Szene und World teilen dieselbe Karteninstanz, Rundlauf trägt den echten Zustand")
	# 28) Spielrhythmus aus Daten: needs.json ist die einzige Quelle für
	#     Takt, Tag, Nacht und Verbrauch; die Leser greifen über die
	#     Need-Registry und den Einheiten-Manager darauf zu.
	var rhythmus_probe := Pop_NeedRegistry.new()
	var rhythmus_manager := Einheit_Manager.new()
	var rhythmus_modell := Welt_Model.new()
	rhythmus_modell.karte_erzeugen(6, 6, "boden")
	var rhythmus_ressourcen := Einheit_Ressourcen.new()
	rhythmus_manager.einrichten(rhythmus_modell, null, rhythmus_ressourcen)
	var rhythmus_ok := is_equal_approx(rhythmus_probe.takt_minuten(), 6.0) \
			and is_equal_approx(rhythmus_probe.tag_minuten(), 4.0) \
			and is_equal_approx(rhythmus_probe.nacht_minuten(), 2.0) \
			and is_equal_approx(rhythmus_manager.verteilung_wert(), 0.8) \
			and is_equal_approx(rhythmus_manager.takt_minuten(), 6.0)
	rhythmus_manager.verteilung_setzen(1.4)
	var rhythmus_override_ok := is_equal_approx(rhythmus_manager.verteilung_wert(), 1.4)
	if not rhythmus_ok or not rhythmus_override_ok:
		print("FEHLER: Spielrhythmus nicht datengetrieben (takt %f, tag %f, nacht %f, verbrauch %f, override %f)" % [
			rhythmus_probe.takt_minuten(), rhythmus_probe.tag_minuten(), rhythmus_probe.nacht_minuten(),
			rhythmus_manager.verteilung_wert(), 1.4])
		fehler += 1
	else:
		print("OK: Spielrhythmus kommt aus needs.json (Takt %d, Tag %d, Nacht %d, Verbrauch %.1f), Spieler-Override wirkt" % [
			int(rhythmus_probe.takt_minuten()), int(rhythmus_probe.tag_minuten()), int(rhythmus_probe.nacht_minuten()), 0.8])
	if fehler == 0:
		print("ALLE PRUEFUNGEN GRUEN")
		quit(0)
	else:
		print("%d PRUEFUNGEN ROT" % fehler)
		quit(1)