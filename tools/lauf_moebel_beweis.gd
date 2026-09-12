extends SceneTree
## Beweislauf: Katalog ladet Moebel, Platzierer setzt Bett (2x2) und Schrank (2x4), Kollision greift.

func _initialize() -> void:
	var fehler := 0
	var registry := Welt_Registry.new()
	var moebel_ids: Array[String] = []
	for m_objekt: Objekt_Basis in registry.moebel_sicht():
		moebel_ids.append(m_objekt.id)
	moebel_ids.sort()
	print("Moebel im Katalog: ", moebel_ids)
	if moebel_ids.size() != 5:
		print("FEHLER: erwartet 5 Moebel, gefunden ", moebel_ids.size())
		fehler += 1
	var fuss := registry.moebel().kachel_fuss("schrank")
	if fuss != Vector2i(2, 4):
		print("FEHLER: Schrank-Fuss sollte 2x4 sein, ist ", fuss)
		fehler += 1
	if registry.moebel().belegte_kacheln("schrank") != 8:
		print("FEHLER: Schrank muss 8 Kacheln belegen")
		fehler += 1
	var model := Welt_Model.new()
	var platzierer := Objekt_MoebelPlatzierer.new()
	platzierer.einrichten(model, registry)
	var eins := platzierer.platzieren("schrank", Vector2(100, 100))
	if not bool(eins.get("ok", false)):
		print("FEHLER: erste Schrank-Platzierung schlug fehl: ", eins)
		fehler += 1
	var zwei := platzierer.platzieren("schrank", Vector2(132, 132))
	if bool(zwei.get("ok", false)):
		print("FEHLER: ueberlappende Schrank-Platzierung wurde nicht blockiert")
		fehler += 1
	else:
		print("Blockierung ok: ", str(zwei.get("grund", "")))
	var drei := platzierer.platzieren("tisch", Vector2(1000, 1000))
	if not bool(drei.get("ok", false)):
		print("FEHLER: freier Tisch wurde abgelehnt: ", drei)
		fehler += 1
	var knoten_id := str(model.objekt_feld(int(eins.get("objekt_index", 0)), "moebel_id", ""))
	if knoten_id != "schrank":
		print("FEHLER: moebel_id Feld fehlt im Modell: ", knoten_id)
		fehler += 1
	if fehler == 0:
		print("MOEBEL-BEWEIS GRUEN: 5 Moebel, 8-Kachel-Schrank, Kollision blockiert, freier Platz geht.")
	else:
		print("MOEBEL-BEWEIS ROT: ", fehler, " Fehler")
	quit(1 if fehler > 0 else 0)
