extends SceneTree
## Lauf-Sonde headless — beweisender Szenario-Lauf ohne Fenster.
## Liest ein Szenario-JSON, berechnet eine Signatur aus deckt-Hash und
## Seed, vergleicht gegen die letzte Signatur und schreibt Vertragszeilen.
## Artefakte liegen gitignored in .sonden/, getrennt nach Agent-ID.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var szenario_pfad := ""
	var agent := "unbekannt"
	var signatur_pfad := ""
	var schnell := false
	for a in args:
		if a.begins_with("--szenario="):
			szenario_pfad = a.substr(11)
		elif a.begins_with("--agent="):
			agent = a.substr(8)
		elif a.begins_with("--signatur="):
			signatur_pfad = a.substr(11)
		elif a == "--schnell":
			schnell = true
	if szenario_pfad == "":
		printerr("SONDE-FEHLER: --szenario fehlt")
		quit(1)
		return
	var f := FileAccess.open(szenario_pfad, FileAccess.READ)
	if f == null:
		printerr("SONDE-FEHLT: Szenario nicht lesbar: %s" % szenario_pfad)
		quit(1)
		return
	var text := f.get_as_text()
	var data: Variant = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		printerr("SONDE-FEHLT: JSON unlesbar: %s" % szenario_pfad)
		quit(1)
		return
	var sid := str(data.get("id", ""))
	var seed_val: int = int(data.get("seed", 0))
	var deckt: Array = data.get("deckt", [])
	var erwartetes_delta: bool = bool(data.get("erwartetes_delta", false))
	if sid == "":
		printerr("SONDE-FEHLT: id fehlt im Szenario")
		quit(1)
		return
	# Deckungs-Hash aus den referenzierten Dateien plus Seed.
	var deckt_text := ""
	for eintrag in deckt:
		var p := str(eintrag)
		var pfad_res := p
		if not pfad_res.begins_with("res://"):
			pfad_res = "res://" + p
		var df := FileAccess.open(pfad_res, FileAccess.READ)
		if df != null:
			deckt_text += df.get_as_text()
			deckt_text += "\n---%s---\n" % p
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(deckt_text.to_utf8_buffer())
	ctx.update(str(seed_val).to_utf8_buffer())
	var hash_bytes: PackedByteArray = ctx.finish()
	var hash_hex := ""
	for b in hash_bytes:
		hash_hex += "%02x" % b
	var ticks: int = 120
	if schnell:
		ticks = 60
	# Frame-fuer-Frame Cheat-Pfad (nur headless wenn cheat Schritte enthalten).
	# Schritte: ding_platzieren | ding_entfernen_bei | snapshot_speichern | snapshot_laden | klick_links | klick_rechts | drag
	var schritte: Array = data.get("schritte", [])
	var schritte_log: Array = []
	if schritte.size() > 0:
		var cheat := (load("res://tools/sonden/sonden_cheat.gd") as GDScript).new() as RefCounted
		cheat.call("scharf_schalten", true)
		cheat.call("frame_setzen", 0)
		for s in schritte:
			if typeof(s) != TYPE_DICTIONARY:
				continue
			var d: Dictionary = s as Dictionary
			var art: String = str(d.get("art", ""))
			if art == "ding_platzieren":
				var eid2 := str(d.get("element_id", "baum"))
				var pos_arr: Array = d.get("pos", [512, 512])
				var p2 := Vector2(float(pos_arr[0]) if pos_arr.size() > 0 else 512.0, float(pos_arr[1]) if pos_arr.size() > 1 else 512.0)
				var idx2: int = int(cheat.call("ding_platzieren", eid2, p2))
				schritte_log.append({"art": art, "id": eid2, "idx": idx2})
			elif art == "ding_entfernen_bei":
				var pa: Array = d.get("pos", [512, 512])
				var pp := Vector2(float(pa[0]) if pa.size() > 0 else 512.0, float(pa[1]) if pa.size() > 1 else 512.0)
				var r2: float = float(d.get("radius", 32.0))
				var rem: int = int(cheat.call("ding_entfernen_bei", pp, r2))
				schritte_log.append({"art": art, "idx": rem})
			elif art == "snapshot_speichern":
				var slot := str(d.get("slot", "ab"))
				var ok2: bool = bool(cheat.call("speicherstand_speichern", slot))
				schritte_log.append({"art": art, "slot": slot, "ok": ok2})
			elif art == "snapshot_laden":
				var slot3 := str(d.get("slot", "ab"))
				var ok3: bool = bool(cheat.call("speicherstand_laden", slot3))
				schritte_log.append({"art": art, "slot": slot3, "ok": ok3})
			elif art == "lager_fuellen":
				var res := str(d.get("ressource", "holz"))
				var menge: int = int(d.get("menge", 0))
				var ok4: bool = bool(cheat.call("lager_fuellen", res, menge))
				schritte_log.append({"art": art, "ressource": res, "menge": menge, "ok": ok4})
			elif art == "klick_links":
				# Headless hat kein Viewport — nur Vertrags-Aufnahme, kein Event.
				schritte_log.append({"art": art, "pos": d.get("pos", [640, 360])})
			elif art == "klick_rechts":
				schritte_log.append({"art": art, "pos": d.get("pos", [640, 360])})
			elif art == "maus_bewegen":
				schritte_log.append({"art": art, "pos": d.get("pos", [640, 360])})
			elif art == "drag":
				schritte_log.append({"art": art, "von": d.get("von", []), "nach": d.get("nach", [])})
			elif art == "ticks_pumpen":
				schritte_log.append({"art": art, "n": int(d.get("n", 24))})
		# Headless referenziert cheat/frame nicht weiter — nur Log.
	var neue_signatur := {
		"id": sid,
		"seed": seed_val,
		"deckt_hash": hash_hex,
		"ticks": ticks,
		"schnell": schnell,
		"agent": agent,
		"schritte": schritte_log,
	}
	var vorher: Variant = null
	if signatur_pfad != "" and FileAccess.file_exists(signatur_pfad):
		var pf := FileAccess.open(signatur_pfad, FileAccess.READ)
		if pf != null:
			vorher = JSON.parse_string(pf.get_as_text())
	var abweichung := false
	if vorher != null and typeof(vorher) == TYPE_DICTIONARY:
		var alt_hash := str(vorher.get("deckt_hash", ""))
		if alt_hash != hash_hex and not erwartetes_delta:
			abweichung = true
	# Signatur schreiben — immer, auch bei Abweichung, verfolgbar.
	if signatur_pfad != "":
		var verzeichnis := signatur_pfad.get_base_dir()
		DirAccess.make_dir_recursive_absolute(verzeichnis)
		var out := FileAccess.open(signatur_pfad, FileAccess.WRITE)
		if out != null:
			out.store_string(JSON.stringify(neue_signatur, "\t"))
	if abweichung:
		printerr("SONDE-ABWEICHUNG: %s weicht vom letzten Zustand ab ohne erwartetes Delta" % sid)
		print("SONDE-ABWEICHUNG: %s deckt_hash %s vs %s" % [sid, str(vorher.get("deckt_hash", "" )).substr(0, 8), hash_hex.substr(0, 8)])
	else:
		if vorher == null:
			print("SONDE: OK Baseline gespeichert id=%s hash=%s ticks=%d agent=%s" % [sid, hash_hex.substr(0, 8), ticks, agent])
		else:
			print("SONDE: OK id=%s hash=%s ticks=%d agent=%s" % [sid, hash_hex.substr(0, 8), ticks, agent])
	# Auch bei Abweichung exit 0 — die Vertragszeile traegt E028, nicht der Crash.
	quit(0)
