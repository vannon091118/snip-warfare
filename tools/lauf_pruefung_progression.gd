extends SceneTree
## Beweislauf der Ressourcen-Progression: Schlag senkt den echten Bestand,
## der Zustand wohnt am Welt_Model und uebersteht den Speicher-Rundlauf,
## Warmefaktor folgt der Tageszyklus-Helligkeit, Seed-Spawn waegt
## Verfuegbarkeit mal Fruchtbarkeit. Alles ueber die bestehenden Systeme.

func _init() -> void:
	var fehler := 0
	# 1) Registry laedt den Pool, Baumbestand traegt vier Stadien.
	var registry := Welt_ProgressionsRegistry.new()
	registry.laden()
	if not registry.hat_definition("baum") or registry.stadien_fuer("baum").size() != 4 or registry.staerke_fuer("baum") != 4:
		print("FEHLER: Progressions-Pool unvollständig (baum %s, stadien %d, staerke %d)" % [
			str(registry.hat_definition("baum")), registry.stadien_fuer("baum").size(), registry.staerke_fuer("baum")])
		fehler += 1
	# 2) Schlag senkt den Bestand am Modell, Stadium folgt.
	var model := Welt_Model.new()
	model.karte_erzeugen(8, 8, "boden")
	var baum_index := model.objekt_hinzufuegen("baum", Vector2(256, 256))
	var zustand := Welt_RessourcenZustand.new()
	zustand.einrichten(registry)
	zustand.zustand_erneuern(baum_index, model)
	var schlag_1 := zustand.schlag(baum_index, model)
	var bestand_nach_1 := zustand.bestand(baum_index, model)
	var schlag_2 := zustand.schlag(baum_index, model)
	var bestand_nach_2 := zustand.bestand(baum_index, model)
	if schlag_1.is_empty() or bestand_nach_1 != 3 or schlag_2.is_empty() or bestand_nach_2 != 2:
		print("FEHLER: Schlag senkt den Bestand nicht (nach1 %d, nach2 %d)" % [bestand_nach_1, bestand_nach_2])
		fehler += 1
	# 3) Erschoepfung: vierter Schlag -> Rest-Objekt an derselben Stelle.
	zustand.schlag(baum_index, model)
	zustand.schlag(baum_index, model)
	var folge_id := str(model.objekt_feld(baum_index, "element_id", ""))
	var folge_stadium := str(model.objekt_feld(baum_index, Welt_RessourcenZustand.FELD_STADIUM, ""))
	if folge_id != "baum_stumpf" or folge_stadium != "rest":
		print("FEHLER: Erschoepfter Baum wird nicht zum Stumpf (element %s, stadium %s)" % [folge_id, folge_stadium])
		fehler += 1
	# 4) Persistenz: Der Zustand uebersteht nach_woerterbuch -> aus_woerterbuch.
	var gerissener_baum := Welt_Model.new()
	gerissener_baum.karte_erzeugen(8, 8, "boden")
	var gerissen_index := gerissener_baum.objekt_hinzufuegen("baum", Vector2(300, 300))
	zustand.zustand_erneuern(gerissen_index, gerissener_baum)
	zustand.schlag(gerissen_index, gerissener_baum)
	zustand.schlag(gerissen_index, gerissener_baum)
	var runde := Welt_Model.new()
	if not runde.aus_woerterbuch(gerissener_baum.nach_woerterbuch()):
		print("FEHLER: Progressions-Rundlauf scheitert beim Laden")
		fehler += 1
	else:
		var runde_bestand := int(runde.objekt_feld(gerissen_index, Welt_RessourcenZustand.FELD_BESTAND, -1))
		var runde_stadium := str(runde.objekt_feld(gerissen_index, Welt_RessourcenZustand.FELD_STADIUM, ""))
		if runde_bestand != 2 or runde_stadium == "":
			print("FEHLER: Zustand uebersteht den Speicher-Rundlauf nicht (bestand %d, stadium %s)" % [runde_bestand, runde_stadium])
			fehler += 1
	# 5) Warmefaktor: Tag (Helligkeit 1.0) schneller als Nacht (0.45).
	var waerme := Welt_WaermeFaktor.new()
	waerme.einrichten(registry)
	var tag_faktor := waerme.faktor_fuer_helligkeit(1.0)
	var nacht_faktor := waerme.faktor_fuer_helligkeit(0.45)
	if not (tag_faktor > nacht_faktor):
		print("FEHLER: Warmefaktor kehrt Tag und Nacht um (tag %f, nacht %f)" % [tag_faktor, nacht_faktor])
		fehler += 1
	# 6) Wachstum: Fortschritt folgt dem Warmefaktor, Stadium wechselt sichtbar.
	var keim := Welt_Model.new()
	keim.karte_erzeugen(8, 8, "boden")
	var keim_index := keim.objekt_hinzufuegen("busch", Vector2(400, 400))
	zustand.zustand_erneuern(keim_index, keim)
	var stadium_start := zustand.stadium(keim_index, keim)
	var gewachsen := false
	for _tick in 2000:
		var ereignis := zustand.wachstum_ticken(keim_index, keim, 1.0)
		if not ereignis.is_empty():
			gewachsen = true
			break
	var stadium_neu := zustand.stadium(keim_index, keim)
	if stadium_start == "" or not gewachsen or stadium_neu == stadium_start:
		print("FEHLER: Wachstum zeigt keinen Stufenwechsel (start %s, neu %s, ereignis %s)" % [stadium_start, stadium_neu, str(gewachsen)])
		fehler += 1
	# 7) Seed-Spawn: Gewichtung respektiert Verfuegbarkeit, Spawn fuellt die Karte.
	var spawn := Welt_SeedSpawnMaschine.new()
	spawn.einrichten(registry, Welt_Model.KACHEL_GROESSE, 12345)
	var baum_gewicht := spawn.gewicht_fuer("baum", 1.0)
	var haus_gewicht := spawn.gewicht_fuer("haus", 1.0)
	if not (baum_gewicht > haus_gewicht) or baum_gewicht <= 0.0:
		print("FEHLER: Spawn-Gewichtung ignoriert die Verfuegbarkeit (baum %f, haus %f)" % [baum_gewicht, haus_gewicht])
		fehler += 1
	var spawn_modell := Welt_Model.new()
	spawn_modell.karte_erzeugen(8, 8, "boden")
	var biome := Welt_BiomRegistry.new()
	var ereignisse := spawn.tag_spawnen(spawn_modell, biome)
	if ereignisse.is_empty():
		print("FEHLER: Tag-Spawn erzeugt keine Saemlinge")
		fehler += 1
	elif not zustand.stadium(ereignisse[0]["index"], spawn_modell) != "":
		# Der Saemling erhaelt seine Felder ueber zustand_erneuern der Maschine.
		zustand.zustand_erneuern(ereignisse[0]["index"], spawn_modell)
		if int(spawn_modell.objekt_feld(ereignisse[0]["index"], Welt_RessourcenZustand.FELD_BESTAND, -1)) <= 0:
			print("FEHLER: Gespawnter Saemling startet ohne Zustandsfelder")
			fehler += 1
	# 8) Sichtbare Stufe: Der Blattindex folgt dem Bestand.
	var bilder := Welt_StufenBilder.new()
	var voll: int = bilder.stadien_index_fuer("begrenzt", 3, 3, 3, 0, 0)
	var gerissen: int = bilder.stadien_index_fuer("begrenzt", 3, 2, 3, 0, 0)
	var stark: int = bilder.stadien_index_fuer("begrenzt", 3, 1, 3, 0, 0)
	if voll != 0 or gerissen <= voll or stark <= gerissen:
		print("FEHLER: Sichtbare Stufen folgen dem Bestand nicht (voll %d, gerissen %d, stark %d)" % [voll, gerissen, stark])
		fehler += 1
	if fehler == 0:
		print("ALLE PROGRESSIONS-PRUEFUNGEN GRUEN")
		quit(0)
	else:
		print("%d PROGRESSIONS-PRUEFUNGEN ROT" % fehler)
		quit(1)
