extends SceneTree
## Lauf-Sonde mit Fenster — der sichtbare Standard. Sie spielt eine echte
## Szenario-Sequenz in der echten Welt-Szene ab, greift an jeder Frame-Marke
## ein eigenes Bild, laesst sich je Marke den Bauzustand ausgeben und
## vergleicht die Bilder mechanisch gegen einander. Kein Spielcode kennt
## diese Datei; beobachtet wird nur ueber bestehende Flaechen.
##
## Reihenfolge: Szenario lesen, Szene laden, Ladekette abwarten, Setup-
## Schritte, dann je Frame-Marke Schritte ausfuehren, Bild greifen, Zustand
## melden, Delta zum Vorgaenger rechnen. Erst danach Urteil und Signatur.

const CHEAT := "res://tools/sonden/sonden_cheat.gd"
const STEPPER := "res://tools/sonden/sonden_frame_stepper.gd"
const EINGABE := "res://tools/sonden/sonden_eingabe.gd"
const VERGLEICH := "res://tools/sonden/sonden_bild_vergleich.gd"


static func _vektor(paar: Variant, notwert: Vector2) -> Vector2:
	if typeof(paar) != TYPE_ARRAY or (paar as Array).size() < 2:
		return notwert
	var a: Array = paar
	return Vector2(float(a[0]), float(a[1]))


var _letzte_einheit: int = -1
## Kategorie logik: Zeitbudget. Ein Sonden-Lauf darf nie stillstehen — er
## meldet sich rechtzeitig, bevor der Laeufer ihn hart abschneidet.
var _start_ms: int = 0
var _frist_ms: int = 75000


func _ueber_budget() -> bool:
	return Time.get_ticks_msec() - _start_ms > _frist_ms


func _ausschnitt(bild: Image, halb: int, versatz: Vector2 = Vector2.ZERO) -> Image:
	## Blick-Ausschnitt um einen Punkt: der Sichtbeweis am Objekt statt am
	## ganzen Bild. Der Punkt darf nicht aus dem Bild fallen.
	var breite := bild.get_width()
	var hoehe := bild.get_height()
	var h := mini(halb, mini(breite, hoehe) / 2)
	var mitte := Vector2(breite / 2.0, hoehe / 2.0) + versatz
	var links := clampi(int(mitte.x) - h, 0, maxi(breite - h * 2, 0))
	var oben := clampi(int(mitte.y) - h, 0, maxi(hoehe - h * 2, 0))
	return bild.get_region(Rect2i(links, oben, h * 2, h * 2))


func _cheat_schritt(cheat: RefCounted, d: Dictionary, stepper: RefCounted, eingabe: RefCounted) -> Dictionary:
	## Fuehrt einen Schritt aus und gibt das Ergebnis zurueck, wenn der Schritt
	## eines hat. Nur das Bau-Gate hat eines: ok oder Ablehnung mit Grund.
	var ergebnis: Dictionary = {}
	var art: String = str(d.get("art", ""))
	if art == "ding_platzieren":
		if cheat != null:
			cheat.call("ding_platzieren", str(d.get("element_id", "baum")), _vektor(d.get("pos", null), Vector2.INF))
	elif art == "ding_entfernen_bei":
		if cheat != null:
			cheat.call("ding_entfernen_bei", _vektor(d.get("pos", null), Vector2(512, 512)), float(d.get("radius", 32.0)))
	elif art == "bauen_anfordern":
		if cheat != null:
			ergebnis = cheat.call("bauen_anfordern", str(d.get("gebaeude_id", "lagerfeuer")), _vektor(d.get("pos", null), Vector2.INF))
	elif art == "lager_fuellen":
		if cheat != null:
			cheat.call("lager_fuellen", str(d.get("ressource", "holz")), int(d.get("menge", 0)), _vektor(d.get("pos", null), Vector2.INF))
	elif art == "einheit_im_blick":
		if cheat != null:
			_letzte_einheit = int(cheat.call("einheit_im_blick", str(d.get("rasse_id", ""))))
	elif art == "einheit_marsch":
		if cheat != null:
			cheat.call("einheit_marsch", int(d.get("index", _letzte_einheit)), _vektor(d.get("ziel", null), Vector2.ZERO))
	elif art == "einheit_marsch_delta":
		if cheat != null:
			cheat.call("einheit_marsch_delta", int(d.get("index", _letzte_einheit)), _vektor(d.get("delta", null), Vector2(160, 0)))
	elif art == "snapshot_speichern":
		if cheat != null:
			cheat.call("speicherstand_speichern", str(d.get("slot", "ab")))
	elif art == "snapshot_laden":
		if cheat != null:
			cheat.call("speicherstand_laden", str(d.get("slot", "ab")))
	elif art == "klick_links":
		if eingabe != null:
			eingabe.call("klick_links", _vektor(d.get("pos", null), Vector2(640, 360)))
	elif art == "klick_rechts":
		if eingabe != null:
			eingabe.call("klick_rechts", _vektor(d.get("pos", null), Vector2(640, 360)))
	elif art == "drag":
		if eingabe != null:
			eingabe.call("drag_links", _vektor(d.get("von", null), Vector2(100, 360)), _vektor(d.get("nach", null), Vector2(1100, 360)))
	elif art == "maus_bewegen":
		if eingabe != null:
			eingabe.call("maus_bewegen", _vektor(d.get("pos", null), Vector2(640, 360)))
	elif art == "ticks_pumpen":
		if stepper != null:
			stepper.call("ticks_pumpen", int(d.get("n", 24)))
	return ergebnis


func _argumente() -> Dictionary:
	var aus := {"szenario": "", "agent": "unbekannt", "signatur": "", "schnell": false, "ab_heiz": ""}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--szenario="):
			aus["szenario"] = a.substr(11)
		elif a.begins_with("--agent="):
			aus["agent"] = a.substr(8)
		elif a.begins_with("--signatur="):
			aus["signatur"] = a.substr(11)
		elif a.begins_with("--ab-heiz="):
			aus["ab_heiz"] = a.substr(10)
		elif a == "--schnell":
			aus["schnell"] = true
	return aus


func _ist_setup(d: Dictionary) -> bool:
	var wann := str(d.get("wann", "frame"))
	return wann == "vor_grab" or wann == "setup"


func _ist_bei_marke(d: Dictionary, marke: int) -> bool:
	if _ist_setup(d):
		return false
	return int(d.get("frame", -1)) == marke


func _bild_speichern(bild: Image, ordner: String, bild_name: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ordner))
	var ziel := ProjectSettings.globalize_path("%s/%s.png" % [ordner, bild_name])
	bild.save_png(ziel)
	return "%s/%s.png" % [ordner, bild_name]


func _initialize() -> void:
	var args := _argumente()
	if args["szenario"] == "":
		printerr("SONDE-FEHLER: --szenario fehlt")
		quit(1)
		return
	var f := FileAccess.open(str(args["szenario"]), FileAccess.READ)
	if f == null:
		printerr("SONDE-FEHLT: Szenario nicht lesbar: %s" % args["szenario"])
		quit(1)
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data == null or typeof(data) != TYPE_DICTIONARY:
		printerr("SONDE-FEHLT: JSON unlesbar")
		quit(1)
		return
	var szenario: Dictionary = data
	_start_ms = Time.get_ticks_msec()
	_frist_ms = int(szenario.get("frist_ms", 75000))
	var sid := str(szenario.get("id", ""))
	var agent := str(args["agent"])
	var deckt: Array = szenario.get("deckt", [])
	var erwartet: Dictionary = szenario.get("erwartet", {})
	var marken: Array = szenario.get("marken", [0, 3, 60, 120])
	var schritte: Array = szenario.get("schritte", [])
	var warte := 120 if bool(args["schnell"]) else 200
	await process_frame
	await process_frame
	# Fail-closed: Laedt die Welt nicht, wird kein Urteil erfunden. Ein
	# Kompilierfehler im Spielcode haelt damit die Sonde nicht 120 Sekunden
	# still, sondern meldet sich sofort als Vertragszeile.
	var paket := load("res://world/scenes/welt.tscn") as PackedScene
	if paket == null:
		printerr("SONDE-FEHLER: welt.tscn nicht ladbar (Kompilierung des Spielcodes)")
		quit(1)
		return
	var szene: Node = paket.instantiate()
	if szene == null:
		printerr("SONDE-FEHLER: welt.tscn nicht instanziierbar")
		quit(1)
		return
	root.add_child(szene)
	var cheat: RefCounted = null
	if not schritte.is_empty():
		cheat = (load(CHEAT) as GDScript).new() as RefCounted
		cheat.call("scharf_schalten", true)
	var stepper: RefCounted = (load(STEPPER) as GDScript).new(self) as RefCounted
	var eingabe: RefCounted = (load(EINGABE) as GDScript).new(self) as RefCounted
	var vergleich: GDScript = load(VERGLEICH) as GDScript
	var ordner := "res://tools/logs/sonden_bilder/%s" % agent
	# Ladekette zuerst: Welt, Speicherstand und Rueckkehrer sind erst danach
	# fertig. Ein Setup davor wuerde durch das Laden ueberschrieben.
	for i in warte:
		await process_frame
	# Setup-Schritte: nur ausdruecklich markierte, nie ein Schritt mit frame.
	for s in schritte:
		if typeof(s) == TYPE_DICTIONARY and _ist_setup(s as Dictionary):
			_cheat_schritt(cheat, s as Dictionary, stepper, eingabe)
	if cheat != null:
		# Nach dem Setup wird der Zustand gemeldet: Das Szenario belegt seine
		# eigene Ausgangslage, statt sie zu behaupten.
		print(cheat.call("lager_bild"))
	var vorher_bild: Image = null
	var vorher_marke := -1
	var deltas: Array[float] = []
	var bewegung := 0.0
	var bau_ergebnisse: Array[bool] = []
	var vorher_blick: Image = null
	for marke in marken:
		var ziel := int(marke)
		print("SONDE-ZEILE: marke=%d betreten frame=%d t=%dms" % [
			ziel, int(stepper.call("frame_nr")), Time.get_ticks_msec() - _start_ms])
		while int(stepper.call("frame_nr")) < ziel:
			if _ueber_budget():
				printerr("SONDE-FEHLER: %s Zeitbudget %d ms erschöpft beim Warten auf Marke %d" % [sid, _frist_ms, ziel])
				quit(1)
				return
			await process_frame
			var naechste := int(stepper.call("frame_nr")) + 1
			stepper.call("frame_setzen", naechste)
			if cheat != null:
				cheat.call("frame_setzen", naechste)
		if _ueber_budget():
			printerr("SONDE-FEHLER: %s Zeitbudget %d ms erschöpft vor Marke %d" % [sid, _frist_ms, ziel])
			quit(1)
			return
		for s in schritte:
			if typeof(s) == TYPE_DICTIONARY and _ist_bei_marke(s as Dictionary, ziel):
				var teil := _cheat_schritt(cheat, s as Dictionary, stepper, eingabe)
				if not teil.is_empty():
					bau_ergebnisse.append(bool(teil.get("ok", false)))
		# Erst den gezeichneten Frame abwarten: Sonst zeigt das Bild den Stand
		# von vor der Aktion und der Beweis hinkt eine Marke nach.
		await RenderingServer.frame_post_draw
		var bild: Image = root.get_texture().get_image()
		var datei := str(_bild_speichern(bild, ordner, "%s_f%03d" % [sid, ziel]))
		var frame_jetzt := int(stepper.call("frame_nr"))
		print("SONDE-ZEILE: bild=%s marke=%d frame=%d weiss=%.3f" % [
			datei, ziel, frame_jetzt, vergleich.call("weiss_anteil", bild)])
		if bool(szenario.get("blick", false)):
			var versatz := Vector2.ZERO
			if bool(szenario.get("blick_objekt", false)) and cheat != null:
				versatz = cheat.call("einheit_bildlage", 0)
			var ausschnitt := _ausschnitt(bild, int(szenario.get("blick_halb", 110)), versatz)
			_bild_speichern(ausschnitt, ordner, "%s_f%03d_einheit" % [sid, ziel])
			if vorher_blick != null:
				print("SONDE-ZEILE: einheit_region von=%d nach=%d delta=%.4f" % [
					vorher_marke, ziel, float(vergleich.call("gesamt", vorher_blick, ausschnitt))])
			vorher_blick = ausschnitt
		if cheat != null:
			cheat.call("zustands_zeile")
		if vorher_bild != null:
			var felder: Array = vergleich.call("regionen", vorher_bild, bild)
			var gesamt: float = float(vergleich.call("gesamt", vorher_bild, bild))
			bewegung = maxf(bewegung, gesamt)
			deltas.append(gesamt)
			print("SONDE-ZEILE: delta von=%d nach=%d gesamt=%.4f regionen=%s" % [
				vorher_marke, ziel, gesamt, str(felder)])
		vorher_bild = bild
		vorher_marke = ziel
	var letztes: Image = vorher_bild
	if letztes == null:
		printerr("SONDE-FEHLER: %s kein Bild gegriffen" % sid)
		quit(1)
		return
	_bild_speichern(letztes, ordner, sid)
	if str(args["ab_heiz"]) != "" and FileAccess.file_exists(str(args["ab_heiz"])):
		var alt := Image.load_from_file(str(args["ab_heiz"]))
		if alt != null:
			var heiz: Image = vergleich.call("heizbild", alt, letztes)
			_bild_speichern(heiz, ordner, "%s_heiz" % sid)
			print("SONDE-ZEILE: heizbild=res://tools/logs/sonden_bilder/%s/%s_heiz.png" % [agent, sid])
	var karte: Node = szene.get_node_or_null("%Karte")
	var kacheln_zahl := 0
	var mit_textur := 0
	if karte != null:
		var ebenen: Node = karte.get_node_or_null("Fliesen_Z0")
		if ebenen != null:
			for kind in ebenen.get_children():
				if kind is Sprite2D:
					kacheln_zahl += 1
					if (kind as Sprite2D).texture != null:
						mit_textur += 1
	var weiss_anteil: float = float(vergleich.call("weiss_anteil", letztes))
	print("SONDE-ZEILE: cursor=%d frame=%d" % [DisplayServer.cursor_get_shape(), int(stepper.call("frame_nr"))])
	print("SONDE-ZEILE: frames=%d marken=%s deltas=%s" % [deltas.size() + 1, str(marken), str(deltas)])
	var letzte_sig := {
		"id": sid, "deckt_hash": _deckungs_hash(deckt), "kacheln": kacheln_zahl, "mit_textur": mit_textur,
		"weiss_anteil": weiss_anteil, "breite": letztes.get_width(), "hoehe": letztes.get_height(),
		"agent": agent, "frames": deltas.size() + 1, "bewegung": bewegung, "marken": marken,
	}
	var vorher: Variant = null
	var sig_pfad := str(args["signatur"])
	if sig_pfad != "" and FileAccess.file_exists(sig_pfad):
		var pf := FileAccess.open(sig_pfad, FileAccess.READ)
		if pf != null:
			vorher = JSON.parse_string(pf.get_as_text())
	if sig_pfad != "":
		DirAccess.make_dir_recursive_absolute(sig_pfad.get_base_dir())
		var out := FileAccess.open(sig_pfad, FileAccess.WRITE)
		if out != null:
			out.store_string(JSON.stringify(letzte_sig, "\t"))
	if kacheln_zahl == 0:
		printerr("SONDE-FEHLER: %s keine Kacheln im Baum" % sid)
		quit(1)
		return
	if bool(szenario.get("sichtprobe", false)) and cheat != null:
		# Sichtprobe: Dasselbe Bild einmal mit und einmal ohne den Einheiten-
		# Knoten. Die Differenz ist genau das Strichmaennchen — oder sie ist
		# null, und dann zeichnet die Einheit schlicht nichts.
		var anzahl: int = int(cheat.call("einheiten_verstecken", true))
		await RenderingServer.frame_post_draw
		var ohne: Image = root.get_texture().get_image()
		cheat.call("einheiten_verstecken", false)
		await RenderingServer.frame_post_draw
		var mit: Image = root.get_texture().get_image()
		var felder_sicht: Array = vergleich.call("regionen", ohne, mit)
		var pixel_delta: float = float(vergleich.call("gesamt", ohne, mit))
		var eigener := 0
		var w := mit.get_width()
		var h := mit.get_height()
		for y in range(0, h, 2):
			for x in range(0, w, 2):
				var ca := ohne.get_pixel(x, y)
				var cb := mit.get_pixel(x, y)
				if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.08:
					eigener += 1
		_bild_speichern(mit, ordner, "%s_sicht_mit" % sid)
		_bild_speichern(ohne, ordner, "%s_sicht_ohne" % sid)
		# Koerperprobe: Nur die Blasen aus, und zwar nur im Rechteck der Figur
		# gezaehlt. Damit ist "eine Blase verdeckt den Strichmann" messbar.
		var blasen: int = int(cheat.call("blasen_verstecken", true))
		await RenderingServer.frame_post_draw
		var ohne_blasen: Image = root.get_texture().get_image()
		cheat.call("blasen_verstecken", false)
		# Koerperprobe am echten Bildort: Die Figur steht bei ihrer Bildlage,
		# nicht zwangsweise in der Bildmitte. Dort kann das Lagerfeuer
		# flackern und wuerde als Verdeckung gezaehlt, obwohl nur die
		# Flamme zwischen zwei Griffen zuckt.
		var figur_lage := Vector2.ZERO
		if cheat != null:
			figur_lage = cheat.call("einheit_bildlage", 0)
		var figur_mitte := Vector2(mit.get_width(), mit.get_height()) * 0.5 + figur_lage
		var x0 := maxi(int(figur_mitte.x) - 24, 0)
		var y0 := maxi(int(figur_mitte.y) - 64, 0)
		var verdeckt := 0
		for y in range(y0, mini(y0 + 64, h)):
			for x in range(x0, mini(x0 + 48, w)):
				var cp := ohne_blasen.get_pixel(x, y)
				var cq := mit.get_pixel(x, y)
				if absf(cp.r - cq.r) + absf(cp.g - cq.g) + absf(cp.b - cq.b) > 0.08:
					verdeckt += 1
		print("SONDE-ZEILE: sichtprobe knoten=%d blasen=%d eigene_pixel=%d koerper_verdeckt=%d delta=%.4f regionen=%s" % [
			anzahl, blasen, eigener, verdeckt, pixel_delta, str(felder_sicht)])
		# Rauschgrenze: Zwischen den beiden Griffen kann sich die Atmosphäre
		# leicht verschieben. Eine echte Blase verdeckt hunderte Pixel, deshalb
		# liegt die Schwelle bewusst bei 60.
		if blasen > 0 and verdeckt > 60:
			printerr("SONDE-WIDERSPRUCH: %s die Blasen verdecken den Koerper des Strichmaennchens (%d Pixel im Umriss)" % [sid, verdeckt])
			quit(0)
			return
		if anzahl > 0 and eigener == 0:
			printerr("SONDE-WIDERSPRUCH: %s der Einheiten-Knoten existiert, zeichnet aber kein einziges Pixel" % sid)
			quit(0)
			return
	if bool(erwartet.get("einheit_im_bild", false)) and cheat != null:
		# Sichtbarkeits-Regel: Eine "sichtbare" Einheit muss im Sichtfeld
		# liegen. Ein Modellwert allein ist kein Beweis fuer den Spieler.
		var bildlage: Vector2 = cheat.call("einheit_bildlage", 0)
		var halb := Vector2(float(letztes.get_width()), float(letztes.get_height())) * 0.5
		print("SONDE-ZEILE: einheit_bildlage=%.0f,%.0f halbbild=%.0f,%.0f" % [bildlage.x, bildlage.y, halb.x, halb.y])
		if absf(bildlage.x) > halb.x or absf(bildlage.y) > halb.y:
			printerr("SONDE-WIDERSPRUCH: %s die Einheit liegt ausserhalb des Sichtfelds (%.0f,%.0f) — ein Spieler sieht sie nicht" % [sid, bildlage.x, bildlage.y])
			quit(0)
			return
	if erwartet.has("einheiten_min") and cheat != null:
		# Der Init-Spawn des Spiels wird geprueft, nicht herbeigefuehrt: Diese
		# Sonde darf keine Einheit setzen, sie darf nur zaehlen.
		var ist_zahl: int = int(cheat.call("einheiten_zahl"))
		var soll_zahl: int = int(erwartet.get("einheiten_min", 0))
		print("SONDE-ZEILE: einheiten_zahl ist=%d soll_min=%d" % [ist_zahl, soll_zahl])
		if ist_zahl < soll_zahl:
			printerr("SONDE-WIDERSPRUCH: %s das Spiel bringt keine Einheit hervor (ist=%d, erwartet mindestens %d)" % [sid, ist_zahl, soll_zahl])
			quit(0)
			return
	if bool(erwartet.get("einheit_bewegt", false)) and cheat != null:
		# Widerspruchs-Pruefung: Ein angenommener Marschbefehl ohne
		# Positionsaenderung ist ein bewiesener Logikfehler, keine Meinung.
		var wanderung: float = float(cheat.call("einheit_wanderung"))
		print("SONDE-ZEILE: einheit_wanderung=%.1f" % wanderung)
		if wanderung < 8.0:
			printerr("SONDE-WIDERSPRUCH: %s Marschbefehl wurde angenommen, die Einheit steht aber still (%.1f px)" % [sid, wanderung])
			quit(0)
			return
	var erwartete_folge: Array = erwartet.get("bau_ok_folge", [])
	if not erwartete_folge.is_empty():
		var soll := ""
		for w: Variant in erwartete_folge:
			soll += "1" if bool(w) else "0"
		var ist := ""
		for w: Variant in bau_ergebnisse:
			ist += "1" if bool(w) else "0"
		print("SONDE-ZEILE: bau_gate soll=%s ist=%s" % [soll, ist])
		if ist != soll:
			printerr("SONDE-WIDERSPRUCH: %s Bau-Gate lieferte %s, erwartet war %s" % [sid, ist, soll])
			quit(0)
			return
	if bool(erwartet.get("bewegung", false)) and bewegung < 0.002:
		printerr("SONDE-WIDERSPRUCH: %s erwartet Bewegung, aber alle Regionen bleiben still (max %.4f)" % [sid, bewegung])
		quit(0)
		return
	var dunkel_anteil: float = float(vergleich.call("dunkel_anteil", letztes))
	print("SONDE-ZEILE: schwärze=%.3f (Anteil fast schwarzer Pixel)" % dunkel_anteil)
	if dunkel_anteil > 0.6 and not bool(szenario.get("dunkel_erlaubt", false)):
		printerr("SONDE-ABWEICHUNG: %s ist zu %.0f Prozent schwarz — ein Spieler sieht hier nichts" % [sid, dunkel_anteil * 100.0])
		quit(0)
		return
	if weiss_anteil > 0.8 and not bool(szenario.get("erwartetes_delta", false)):
		printerr("SONDE-ABWEICHUNG: %s weiss_anteil %.2f ohne erwartetes Delta" % [sid, weiss_anteil])
		quit(0)
		return
	if vorher != null and typeof(vorher) == TYPE_DICTIONARY and not bool(szenario.get("erwartetes_delta", false)):
		if str((vorher as Dictionary).get("deckt_hash", "")) != str(letzte_sig["deckt_hash"]):
			printerr("SONDE-ABWEICHUNG: %s weicht vom letzten Zustand ab" % sid)
			quit(0)
			return
	print("SONDE: OK id=%s kacheln=%d weiss=%.2f bewegung=%.4f frames=%d agent=%s" % [
		sid, kacheln_zahl, weiss_anteil, bewegung, deltas.size() + 1, agent])
	quit(0)


func _deckungs_hash(deckt: Array) -> String:
	## Deckungs-Hash: nur aus gedeckten Dateien — stabil gegen Messwerte.
	var text := ""
	for eintrag in deckt:
		var p := str(eintrag)
		var pfad := p if p.begins_with("res://") else "res://" + p
		var df := FileAccess.open(pfad, FileAccess.READ)
		if df != null:
			text += df.get_as_text()
			text += "\n---%s---\n" % p
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(text.to_utf8_buffer())
	var roh: PackedByteArray = ctx.finish()
	var hex := ""
	for b in roh:
		hex += "%02x" % b
	return hex
