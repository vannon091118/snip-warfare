extends RefCounted
class_name Sonden_Cheat
## Einziges Cheat-Gate des Projekts. Kein Spielcode ruft diese Klasse je auf.
## Nur die beiden Läufer tools/sonden/lauf_sonde_*.gd instanziieren sie über
## ihren Dateipfad, deshalb greift die LOC-Ausnahme für tools/ und die
## Architekturregel „Szenen rechnen nicht" wird nie berührt. Ruft eine
## Sonden-Klasse ausserhalb eines Sonden-Laufs auf, meldet _bewacht einen
## E026-fähigen Vertragsfehler und bricht die Aktion ab.

var _sonde_aktiv: bool = false
var _frame_zahl: int = 0
## Kategorie daten: Die zuletzt gesetzte Einheit und ihr Startpunkt.
var _einheit_index: int = -1
var _einheit_start: Vector2 = Vector2.ZERO

func scharf_schalten(aktiv: bool) -> void:
	_sonde_aktiv = aktiv

func ist_scharf() -> bool:
	return _sonde_aktiv

func frame_setzen(nr: int) -> void:
	_frame_zahl = nr

func frame() -> int:
	return _frame_zahl

func _bewacht(quelle: String) -> bool:
	if not _sonde_aktiv:
		printerr("SONDE-FEHLER: Cheat verweigert ausserhalb Sonde: %s" % quelle)
		return false
	return true

func _welt() -> Node:
	var baum := Engine.get_main_loop() as SceneTree
	if baum == null or baum.root == null:
		return null
	for kind in baum.root.get_children():
		if kind.has_method("model_liefern"):
			return kind
	var found: Node = baum.root.find_child("Welt", true, false) if baum.root.has_method("find_child") else null
	return found

func _welt_modell() -> Welt_Model:
	var w := _welt()
	if w == null:
		return null
	if w.has_method("model_liefern"):
		return w.call("model_liefern")
	return null

func ding_platzieren(element_id: String, position: Vector2) -> int:
	if not _bewacht("ding_platzieren:%s" % element_id):
		return -1
	var m := _welt_modell()
	if m == null:
		printerr("SONDE-FEHLER: Kein Welt_Model für ding_platzieren")
		return -1
	var ort := _stelle(position)
	var idx := m.objekt_hinzufuegen(element_id, ort)
	print("SONDE-ZEILE: cheat=ding_platzieren id=%s idx=%d pos=%.0f,%.0f frame=%d" % [element_id, idx, ort.x, ort.y, _frame_zahl])
	return idx

func ding_entfernen_bei(position: Vector2, radius: float = 32.0) -> int:
	if not _bewacht("ding_entfernen_bei"):
		return -1
	var m := _welt_modell()
	if m == null:
		return -1
	var idx := m.objekt_bei(position, radius)
	if idx >= 0:
		var eid := m.objekt_element_id(idx)
		m.objekt_entfernen(idx)
		print("SONDE-ZEILE: cheat=ding_entfernen id=%s idx=%d frame=%d" % [eid, idx, _frame_zahl])
		return idx
	return -1

func speicherstand_speichern(slot_id: String) -> bool:
	if not _bewacht("speicherstand_speichern:%s" % slot_id):
		return false
	var m := _welt_modell()
	if m == null:
		return false
	var snap := m.nach_woerterbuch()
	var base := "user://sonden_snap_%s.json" % slot_id
	var f := FileAccess.open(base, FileAccess.WRITE)
	if f == null:
		printerr("SONDE-FEHLER: Save-Slot nicht schreibbar: %s" % base)
		return false
	f.store_string(JSON.stringify(snap))
	print("SONDE-ZEILE: cheat=snapshot_speichern slot=%s objekte=%d frame=%d" % [slot_id, m.objekt_anzahl(), _frame_zahl])
	return true

func speicherstand_laden(slot_id: String) -> bool:
	if not _bewacht("speicherstand_laden:%s" % slot_id):
		return false
	var m := _welt_modell()
	if m == null:
		return false
	var base := "user://sonden_snap_%s.json" % slot_id
	if not FileAccess.file_exists(base):
		printerr("SONDE-FEHLER: Save-Slot fehlt: %s" % base)
		return false
	var f := FileAccess.open(base, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data == null or typeof(data) != TYPE_DICTIONARY:
		printerr("SONDE-FEHLER: Snapshot unlesbar: %s" % base)
		return false
	var ok: bool = m.aus_woerterbuch(data)
	print("SONDE-ZEILE: cheat=snapshot_laden slot=%s ok=%s frame=%d" % [slot_id, str(ok), _frame_zahl])
	return ok

func lager_fuellen(ressource: String, menge: int, position: Vector2 = Vector2.ZERO) -> bool:
	if not _bewacht("lager_fuellen:%s" % ressource):
		return false
	position = _stelle(position)
	var w := _welt()
	if w == null or not w.has_method("lager_liefern"):
		printerr("SONDE-FEHLER: lager_fuellen braucht Welt.lager_liefern()")
		return false
	var lager: Variant = w.call("lager_liefern")
	if lager == null:
		printerr("SONDE-FEHLER: Kein Lager fuer lager_fuellen")
		return false
	var idx: int = int(lager.call("lager_zahl")) - 1
	if idx < 0:
		idx = int(lager.call("lager_anlegen", "kleines_lager", position))
	if idx < 0:
		printerr("SONDE-FEHLER: lager_fuellen kein Lager anlegbar")
		return false
	# Derselbe Buchungsweg wie im Spiel: Ernteposition setzen und ueber die
	# Ressourcen-Spitze einlagern. Ein direktes Setzen des Bestands waere
	# eine zweite Wahrheit und wuerde das Bau-Gate nicht bedienen.
	if w.has_method("ressourcen_liefern"):
		var ressourcen: Variant = w.call("ressourcen_liefern")
		if ressourcen != null:
			ressourcen.call("ernte_position_setzen", lager.call("lager_position", idx))
			ressourcen.call("hinzufuegen", ressource, menge)
	var bestaetigung: int = int(lager.call("bestand_im_lager", idx, ressource))
	var lager_pos: Vector2 = lager.call("lager_position", idx)
	print("SONDE-ZEILE: cheat=lager_fuellen ressource=%s menge=%d bestaetigt=%d idx=%d lager_pos=%.0f,%.0f frame=%d" % [ressource, menge, bestaetigung, idx, lager_pos.x, lager_pos.y, _frame_zahl])
	return bestaetigung == menge

func bauen_anfordern(gebaeude_id: String, position: Vector2) -> Dictionary:
	## Einzige Stelle, an der eine Sonde das Bau-Gate befragen darf. Die
	## Antwort wird immer als Vertragszeile gemeldet, auch die Ablehnung:
	## Genau die Ablehnung ist der Beweis, dass das Gate greift.
	if not _bewacht("bauen_anfordern:%s" % gebaeude_id):
		return {"ok": false, "grund": "Sonde nicht scharf"}
	var w := _welt()
	if w == null or not w.has_method("gebaeude_liefern"):
		printerr("SONDE-FEHLER: bauen_anfordern braucht Welt.gebaeude_liefern()")
		return {"ok": false, "grund": "kein Gebaeude_Manager"}
	var manager: Variant = w.call("gebaeude_liefern")
	if manager == null:
		printerr("SONDE-FEHLER: Kein Gebaeude_Manager fuer bauen_anfordern")
		return {"ok": false, "grund": "kein Gebaeude_Manager"}
	# Vorbedingung als Vertragszeile: Was im Lager liegt, steht VOR dem Bau
	# im Log. Damit ist ein "Kosten fehlen" ohne Nachfrage nachpruefbar.
	print(lager_bild())
	var ort := _stelle(position)
	var ergebnis: Dictionary = manager.call("bauen_anfordern", gebaeude_id, ort)
	print("SONDE-ZEILE: cheat=bauen_anfordern id=%s ok=%s grund=%s idx=%s pos=%.0f,%.0f frame=%d" % [
		gebaeude_id, str(ergebnis.get("ok", false)), str(ergebnis.get("grund", "-")),
		str(ergebnis.get("objekt_index", -1)), ort.x, ort.y, _frame_zahl])
	if not bool(ergebnis.get("ok", false)):
		# Ablehnungen duerfen nicht im Dunkeln bleiben: der Lagerzustand
		# wird mitgemeldet, damit der Grund nachpruefbar ist.
		print(lager_bild())
	return ergebnis

func lager_bild() -> String:
	## Beobachtbarer Lagerzustand als Vertragszeile: je Lager Position und
	## Bestaende. Nur die Sonde darf das fragen.
	if not _bewacht("lager_bild"):
		return ""
	var w := _welt()
	if w == null or not w.has_method("lager_liefern"):
		return "SONDE-ZEILE: lager nicht verfuegbar"
	var lager: Variant = w.call("lager_liefern")
	if lager == null:
		return "SONDE-ZEILE: lager nicht verfuegbar"
	var zahl: int = int(lager.call("lager_zahl"))
	var teile: Array[String] = []
	for i in zahl:
		var pos: Vector2 = lager.call("lager_position", i)
		teile.append("#%d pos=%.0f,%.0f typ=%s bestand=%s" % [
			i, pos.x, pos.y, str(lager.call("lager_typ_id", i)), str(lager.call("bestaende_im_lager", i))])
	return "SONDE-ZEILE: lager zahl=%d %s" % [zahl, " | ".join(teile)]

func _einheiten() -> Variant:
	var w := _welt()
	if w == null or not w.has_method("einheiten_liefern"):
		return null
	return w.call("einheiten_liefern")

func _stelle(position: Vector2) -> Vector2:
	## Ohne ausdruecklichen Ort handelt die Sonde dort, wo der Spieler
	## hinsieht: Das ist die ehrlichste Nachstellung eines Spieler-Klicks.
	if position == Vector2.INF:
		return _kamera_mitte()
	return position


func _kamera_mitte() -> Vector2:
	## Weltposition der Bildmitte: Die Kamera ist die einzige Wahrheit der
	## Sicht, deshalb wird hier kein Bildschirmpunkt umgerechnet.
	var w := _welt()
	if w == null:
		return Vector2.ZERO
	var kamera := w.find_child("Kamera", true, false) as Camera2D
	if kamera == null:
		return Vector2.ZERO
	return kamera.get_screen_center_position()

func einheit_im_blick(rasse_id: String = "") -> int:
	## Setzt eine Einheit genau in die Bildmitte. Damit liegt der Beweisbereich
	## fest bei der halben Viewportgroesse und die Sonde muss nichts umrechnen.
	if not _bewacht("einheit_im_blick"):
		return -1
	var mgr: Variant = _einheiten()
	if mgr == null:
		printerr("SONDE-FEHLER: einheit_im_blick braucht Welt.einheiten_liefern()")
		return -1
	var pos := _kamera_mitte()
	var idx: int = int(mgr.call("einheit_hinzufuegen", pos, rasse_id))
	if idx >= 0:
		mgr.call("einheit_bewegen_nach", idx, pos)
		_einheit_index = idx
		_einheit_start = pos
	print("SONDE-ZEILE: cheat=einheit_im_blick idx=%d rasse=%s pos=%.0f,%.0f blick=%.0f,%.0f frame=%d" % [
		idx, rasse_id, pos.x, pos.y, pos.x, pos.y, _frame_zahl])
	return idx

func einheit_marsch_delta(index: int, delta: Vector2) -> bool:
	## Marsch relativ zur eigenen Position: Ein Testziel muss nicht ausgerechnet
	## werden und liegt garantiert im Sichtfeld. Ohne Index befehligt die
	## Sonde die erste echte Spiel-Einheit — genau der Weg des Init-Spawns.
	var mgr: Variant = _einheiten()
	if mgr == null:
		return false
	var auftrag: int = index
	if auftrag < 0:
		if int(mgr.call("einheit_zahl")) < 1:
			print("SONDE-ZEILE: cheat=einheit_marsch_delta idx=-1 ohne Einheit frame=%d" % _frame_zahl)
			return false
		auftrag = 0
	var start: Vector2 = mgr.call("einheit_position", auftrag)
	return einheit_marsch(auftrag, start + delta)

func einheiten_verstecken(verstecken: bool) -> int:
	## Schaltet die Einheiten-Knoten aus und ein. Nur so laesst sich das
	## Bild mit und ohne Strichmaennchen vergleichen und die Frage "zeichnet
	## die Einheit ueberhaupt Pixel" hart beantworten.
	if not _bewacht("einheiten_verstecken"):
		return -1
	var mgr: Variant = _einheiten()
	if mgr == null:
		return -1
	var zahl := 0
	for kind in (mgr as Node).get_children():
		if kind is AnimatedSprite2D:
			(kind as AnimatedSprite2D).visible = not verstecken
			zahl += 1
	return zahl


func blasen_verstecken(verstecken: bool) -> int:
	## Schaltet nur die Blasen der Darsteller um. Damit wird messbar, welche
	## Pixel im Koerperbereich der Figur von einer Blase stammen.
	if not _bewacht("blasen_verstecken"):
		return -1
	var mgr: Variant = _einheiten()
	if mgr == null:
		return -1
	var zahl := 0
	for kind in (mgr as Node).get_children():
		if not (kind is AnimatedSprite2D):
			continue
		for teil in kind.get_children():
			# Die Blasen sind Node2D-Huellen mit PanelContainer darin; beide
			# sind CanvasItem und damit sichtbar schaltbar.
			if teil is CanvasItem:
				(teil as CanvasItem).visible = not verstecken
				zahl += 1
	return zahl


func einheiten_zahl() -> int:
	## Nur zaehlen, nicht erzeugen: Damit kann eine Sonde pruefen, ob das
	## Spiel selbst eine Einheit hervorbringt, ohne sie selbst zu setzen.
	return einheiten_zahl_gewacht()

var _bekannte_einheiten: int = 0

func einheiten_zahl_gewacht() -> int:
	## Die gewachte Zahl: Jede Erhoehung loest den Spawn-Watch aus und
	## meldet die Herkunft der neuen Einheit als Vertragszeile.
	var mgr: Variant = _einheiten()
	if mgr == null:
		return -1
	var zahl := int(mgr.call("einheit_zahl"))
	if zahl > _bekannte_einheiten:
		_spawn_watch(zahl)
	_bekannte_einheiten = zahl
	return zahl

func _spawn_watch(neue_zahl: int) -> void:
	## Herkunft statt Vermutung: Bei jeder Aenderung der Einheiten-Zahl
	## meldet die Sonde, wo die neue Einheit steht und welche Landmarken
	## (Kamera-Knoten, gezeichnete Mitte, Lager-Anker, naechstes Feuer)
	## daneben liegen. Die naechstgelegene Landmarke ist die wahrscheinliche
	## Spawn-Formel, messbar ohne Quelltext-Raetsel.
	var mgr: Variant = _einheiten()
	if mgr == null:
		return
	for i in range(_bekannte_einheiten, neue_zahl):
		var pos: Vector2 = mgr.call("einheit_position", i)
		var kandidaten: Array[String] = []
		var beste: String = ""
		var beste_distanz := INF
		for paar in _landmarken():
			var name: String = paar[0]
			var ort: Vector2 = paar[1]
			var d := pos.distance_to(ort)
			kandidaten.append("%s@%.0f,%.0f d=%.0f" % [name, ort.x, ort.y, d])
			if d < beste_distanz:
				beste_distanz = d
				beste = name
		print("SONDE-ZEILE: spawn_watch einheit#%d pos=%.0f,%.0f naechste=%s | %s" % [
			i, pos.x, pos.y, beste, " | ".join(kandidaten)])

func _landmarken() -> Array:
	## Alle Orte, an denen ein Spawner ueblicherweise absetzt. Jede spur
	## ist nachpruefbar; die naechste erklaert die Herkunft.
	var liste: Array = []
	liste.append(["kamera_knoten", _kamera_knoten_position()])
	liste.append(["kamera_mitte", _kamera_mitte()])
	var w := _welt()
	if w != null and w.has_method("einheiten_liefern"):
		var mgr: Variant = w.call("einheiten_liefern")
		if mgr != null and mgr.has_method("lager_anker_position"):
			liste.append(["lager_anker", (mgr.call("lager_anker_position") as Vector2) + Vector2(24, 20)])
	var m := _welt_modell()
	if m != null:
		var beste := Vector2.INF
		var beste_distanz := INF
		var mitte := _kamera_mitte()
		for index in m.objekt_anzahl():
			if str(m.objekt_feld(index, "gebaeude_id", "")) != "lagerfeuer":
				continue
			var pos: Vector2 = m.objekt_position(index)
			var d := pos.distance_to(mitte)
			if d < beste_distanz:
				beste_distanz = d
				beste = pos
		if beste != Vector2.INF:
			liste.append(["feuer", beste + Vector2(0, 48)])
	# Der Landeplatz ist ein primaerer Spawn-Kandidat: Er markiert die
	# Einstiegs-Stelle der ersten Einheit und liegt oft am Kartenrand.
	var w2 := _welt()
	if w2 != null:
		var lp := w2.find_child("Landeplatz", true, false)
		if lp is Node2D:
			liste.append(["landeplatz", (lp as Node2D).position])
	liste.append(["harter_punkt", Vector2(500, 300)])
	return liste

func _kamera_knoten_position() -> Vector2:
	var w := _welt()
	if w == null:
		return Vector2.INF
	var kamera := w.find_child("Kamera", true, false) as Camera2D
	if kamera == null:
		return Vector2.INF
	return kamera.position

func kamera_zeile() -> String:
	## Kamera-Wahrheit: Knoten-Position gegen gezeichnete Bildmitte. Weichen
	## beide ab, ist jede Spawn-Rechnung am Knoten eine Landung ausserhalb
	## des Bildes — das ist hier mechanisch ablesbar.
	var knoten := _kamera_knoten_position()
	var mitte := _kamera_mitte()
	var zeile := "SONDE-ZEILE: kamera knoten=%s mitte=%s abweichung=%.0f" % [
		"%.0f,%.0f" % [knoten.x, knoten.y] if knoten != Vector2.INF else "-",
		"%.0f,%.0f" % [mitte.x, mitte.y] if mitte != Vector2.INF else "-",
		knoten.distance_to(mitte) if knoten != Vector2.INF and mitte != Vector2.INF else -1.0]
	print(zeile)
	return zeile

func einheit_bildlage(index: int = -1) -> Vector2:
	## Wo die Einheit relativ zur Bildmitte steht. Ein Betrag groesser als die
	## halbe Viewportgroesse heisst: Der Spieler sieht sie nicht.
	if not _bewacht("einheit_bildlage"):
		return Vector2.INF
	var mgr: Variant = _einheiten()
	if mgr == null:
		return Vector2.INF
	var idx: int = index if index >= 0 else _einheit_index
	if idx < 0 or idx >= int(mgr.call("einheit_zahl")):
		return Vector2.INF
	return (mgr.call("einheit_position", idx) as Vector2) - _kamera_mitte()

func einheit_wanderung() -> float:
	## Zurueckgelegte Strecke der zuletzt gesetzten Einheit seit dem Setzen.
	## Nur so wird ein angenommener Befehl von einer echten Bewegung trennbar.
	if not _bewacht("einheit_wanderung"):
		return 0.0
	if _einheit_index < 0:
		return 0.0
	var mgr: Variant = _einheiten()
	if mgr == null:
		return 0.0
	var jetzt: Vector2 = mgr.call("einheit_position", _einheit_index)
	return jetzt.distance_to(_einheit_start)

func einheit_marsch(index: int, ziel: Vector2) -> bool:
	## Spieler-Befehl an eine echte Einheit: derselbe Weg wie ein Klick.
	## Ohne Index gilt die erste Einheit der Welt; der Befehl merkt sich
	## seinen Startpunkt, damit die Wanderung ab Befehl gemessen wird.
	if not _bewacht("einheit_marsch"):
		return false
	var mgr: Variant = _einheiten()
	if mgr == null:
		return false
	var auftrag: int = index
	if auftrag < 0:
		auftrag = 0 if int(mgr.call("einheit_zahl")) > 0 else -1
	if auftrag >= 0:
		_einheit_index = auftrag
		_einheit_start = mgr.call("einheit_position", auftrag)
	var ok: bool = bool(mgr.call("einheit_bewegen_nach", auftrag, ziel))
	print("SONDE-ZEILE: cheat=einheit_marsch idx=%d ziel=%.0f,%.0f ok=%s frame=%d" % [
		auftrag, ziel.x, ziel.y, str(ok), _frame_zahl])
	return ok

func darstellung_zeile() -> String:
	## Was der Einheiten-Baum wirklich zeichnet: Knoten, Sichtbarkeit,
	## Animation, Frame-Zahl und Position. Ohne diese Zeile bleibt die Frage
	## "warum sieht man kein Strichmaennchen" reine Vermutung.
	if not _bewacht("darstellung_zeile"):
		return ""
	var mgr: Variant = _einheiten()
	if mgr == null:
		return "SONDE-ZEILE: darstellung kein Einheiten-Manager"
	var teile: Array[String] = []
	for kind in (mgr as Node).get_children():
		if kind is AnimatedSprite2D:
			var s := kind as AnimatedSprite2D
			var frames := 0
			if s.sprite_frames != null:
				frames = s.sprite_frames.get_frame_count(s.animation)
			teile.append("%s sichtbar=%s anim=%s bild=%d/%d pos=%.0f,%.0f z=%d masse=%s farbe=%s %s" % [
				s.name, str(s.visible), s.animation, s.frame, frames, s.position.x, s.position.y, s.z_index,
				str(s.scale), str(s.modulate), _textur_bild(s)])
	var zeile := "SONDE-ZEILE: darstellung knoten=%d %s" % [teile.size(), " | ".join(teile)]
	print(zeile)
	return zeile


func lagerfeuer_bild() -> String:
	## Alle Feuer der Welt mit Position und Abstand zur Bildmitte: Damit sind
	## die Kandidaten des Ankunftsortes nachpruefbar statt vermutet.
	if not _bewacht("lagerfeuer_bild"):
		return ""
	var m := _welt_modell()
	if m == null:
		return ""
	var mitte := _kamera_mitte()
	var teile: Array[String] = []
	for index in m.objekt_anzahl():
		if str(m.objekt_feld(index, "gebaeude_id", "")) != "lagerfeuer":
			continue
		var pos: Vector2 = m.objekt_position(index)
		teile.append("#%d pos=%.0f,%.0f abstand=%.0f" % [index, pos.x, pos.y, pos.distance_to(mitte)])
	var zeile := "SONDE-ZEILE: feuer zahl=%d bildmitte=%.0f,%.0f %s" % [teile.size(), mitte.x, mitte.y, " | ".join(teile)]
	print(zeile)
	return zeile


func _textur_bild(s: AnimatedSprite2D) -> String:
	## Groesse von Atlas und Ausschnitt: Nur so ist beweisbar, ob der Frame
	## ueberhaupt Flaeche hat oder als Splitter gezeichnet wird.
	if s.sprite_frames == null:
		return "ohne Frames"
	var tex: Texture2D = s.sprite_frames.get_frame_texture(s.animation, s.frame)
	if tex == null:
		return "ohne Textur"
	if tex is AtlasTexture:
		var at := tex as AtlasTexture
		var atlas_groesse := Vector2.ZERO
		if at.atlas != null:
			atlas_groesse = Vector2(at.atlas.get_width(), at.atlas.get_height())
		return "atlas=%.0fx%.0f ausschnitt=%.0fx%.0f bei %.0f,%.0f" % [
			atlas_groesse.x, atlas_groesse.y, at.region.size.x, at.region.size.y, at.region.position.x, at.region.position.y]
	return "textur=%.0fx%.0f" % [float(tex.get_width()), float(tex.get_height())]


func zustands_zeile() -> String:
	## Beobachtbarer Bauzustand als Vertragszeile: je Bauobjekt Phase,
	## Fortschritt und Element. Damit wird der Asset-Uebergang mechanisch
	## belegt statt behauptet.
	if not _bewacht("zustands_zeile"):
		return ""
	var m := _welt_modell()
	if m == null:
		return ""
	var teile: Array[String] = []
	for index in m.objekt_anzahl():
		var gid := str(m.objekt_feld(index, "gebaeude_id", ""))
		if gid == "":
			continue
		teile.append("%s#%d phase=%d fortschritt=%d element=%s" % [
			gid, index, int(m.objekt_feld(index, "bau_phase", 0)),
			int(m.objekt_feld(index, "bau_fortschritt", 0)), m.objekt_element_id(index)])
	var mgr: Variant = _einheiten()
	var einheiten_teil: Array[String] = []
	var einheiten_zahl := 0
	if mgr != null:
		# Ueber die gewachte Zahl gehen: Jede Aenderung loest den Spawn-Watch
		# aus und erklaert die Herkunft der neuen Einheit statt sie zu raten.
		einheiten_zahl = einheiten_zahl_gewacht()
		for i in einheiten_zahl:
			var epos: Vector2 = mgr.call("einheit_position", i)
			einheiten_teil.append("einheit#%d rasse=%s pos=%.0f,%.0f" % [
				i, str(mgr.call("einheit_rasse", i)), epos.x, epos.y])
	darstellung_zeile()
	lagerfeuer_bild()
	kamera_zeile()
	var kamera := _kamera_mitte()
	var zeile := "SONDE-ZEILE: zustand frame=%d kamera=%.0f,%.0f objekte=%d bauten=%d einheiten=%d %s %s" % [
		_frame_zahl, kamera.x, kamera.y, m.objekt_anzahl(), teile.size(), einheiten_zahl,
		" | ".join(teile), " | ".join(einheiten_teil)]
	print(zeile)
	return zeile
