extends Node2D
class_name Karawanen_Manager
## Manager für Karawanen auf der Weltkarte: Erzeugt, tickt und zeichnet
## Karawanen als bewegte Punkte zwischen den Karten. Verbindet Lager über
## das Makro-Netzwerk (Welt_NetzwerkPlaner.wege). Handelsabwicklung läuft
## über direkte Mutationen auf dem Ziel-Modell (auch inaktiv).

signal karawane_gestartet(karawane: Karawanen_Einheit)
signal karawane_angekommen(karawane: Karawanen_Einheit)
signal karawane_entladen(karawane: Karawanen_Einheit, erfolreich: bool)
signal handels_abgeschlossen(von_map_id: String, nach_map_id: String, ressourcen: Dictionary)

## Kategorie daten: Liste aller aktiven Karawanen.
var _karawanen: Array[Karawanen_Einheit] = []
var _naechste_karawanen_nummer: int = 1

## Kategorie logik: Verbindungen zu anderen Domänen.
var _welt_world: Welt_World = null
var _netzwerk_planer: Welt_NetzwerkPlaner = null
var _model: Welt_Model = null

## Sichtbarkeit: Karawanen als Punkte auf der Weltkarte.
var _karawanen_ebene: Node2D
const KARAWANEN_PUNKT_RADIUS := 6.0
const KARAWANEN_FARBE := Color(1.0, 0.9, 0.2)
const KARAWANEN_RAND_FARBE := Color(0.3, 0.2, 0.0)

func _ready() -> void:
	y_sort_enabled = true
	_karawanen_ebene = Node2D.new()
	_karawanen_ebene.name = "KarawanenEbene"
	_karawanen_ebene.y_sort_enabled = true
	add_child(_karawanen_ebene)
	
	# Weltuhr verbinden
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and not weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick") and weltuhr.tick.is_connected(_auf_tick):
		weltuhr.tick.disconnect(_auf_tick)

func einrichten(welt_world: Welt_World, netzwerk_planer: Welt_NetzwerkPlaner, model: Welt_Model) -> void:
	_welt_world = welt_world
	_netzwerk_planer = netzwerk_planer
	_model = model

func modell_wechseln(neues_modell: Welt_Model) -> void:
	## Kartenwechsel-Handshake: Aktualisiert Modell-Referenz.
	_model = neues_modell

func _auf_tick(tick_nummer: int, delta: float) -> void:
	## 1/6 Tick-Gate: Inaktive Karten ticken nur jedes 6. Frame.
	if _welt_world != null:
		var aktive_map_id := _welt_world.aktive_map_id()
		var eigene_map_id := _model.map_id if _model != null else ""
		if aktive_map_id != "" and aktive_map_id != eigene_map_id:
			# Inaktive Karte: Nur jedes 6. Frame ticken
			if Engine.get_process_frames() % 6 != 0:
				return
	
	# Karawanen ticken
	var entfernte_indices: Array[int] = []
	for index in _karawanen.size():
		var karawane: Karawanen_Einheit = _karawanen[index]
		if karawane == null:
			entfernte_indices.append(index)
			continue
		
		# Prüfen ob die Karawane auf DIESER Karte startet oder ankommt
		var ist_meine_karawane := (karawane.von_map_id == _model.map_id) or (karawane.nach_map_id == _model.map_id)
		if not ist_meine_karawane:
			continue
		
		var angekommen := karawane.tick()
		if angekommen:
			# Karawane ist am Ziel angekommen -> Entladen
			_karawane_entladen(karawane, index)
		elif karawane.ist_fertig():
			# Karawane ist vollständig abgewickelt -> Entfernen
			entfernte_indices.append(index)
	
	# Entfernte Karawanen bereinigen (von hinten, damit Indizes stimmen)
	entfernte_indices.sort_custom(func(a: int, b: int) -> bool: return a > b)
	for idx in entfernte_indices:
		_karawanen.remove_at(idx)
	
	# Sichtbarkeit aktualisieren
	_karawanen_ebene.queue_redraw()

func _karawane_entladen(karawane: Karawanen_Einheit, index: int) -> void:
	## Lädt die Fracht in das Ziel-Lager ein (direkte Mutation über Welt_World,
	## funktioniert auch auf inaktiven Karten).
	var erfolg := false
	if _welt_world != null:
		# Direkter Aufruf: Welt_World wendet Mutation auf gespeicherten
		# Lager-Daten der Zielkarte an (kein SubViewport, kein Threading).
		erfolg := _welt_world.karawane_ankunft_verarbeiten(karawane)
	
	karawane_angekommen.emit(karawane)
	
	if erfolg:
		karawane.als_fertig_markieren()
		karawane_entladen.emit(karawane, true)
		# Handelsabschluss melden
		var fracht_kopie := karawane.fracht()
		handels_abgeschlossen.emit(karawane.von_map_id, karawane.nach_map_id, fracht_kopie)
	else:
		karawane_entladen.emit(karawane, false)

func karawane_erstellen(von_map_id: String, nach_map_id: String, von_pos: Vector2, nach_pos: Vector2, fracht: Dictionary) -> Karawanen_Einheit:
	## Erstellt eine neue Karawane mit berechneter Reisedauer aus dem Netzwerk.
	var reise_ticks := _reise_dauer_berechnen(von_map_id, nach_map_id, von_pos, nach_pos)
	
	var k_id := "karawane_%d" % _naechste_karawanen_nummer
	_naechste_karawanen_nummer += 1
	
	var karawane := Karawanen_Einheit.new(k_id, von_map_id, nach_map_id, von_pos, nach_pos, reise_ticks, fracht)
	_karawanen.append(karawane)
	
	# Reise starten
	karawane.reise_starten()
	karawane_gestartet.emit(karawane)
	
	return karawane

func _reise_dauer_berechnen(von_map_id: String, nach_map_id: String, von_pos: Vector2, nach_pos: Vector2) -> int:
	## Berechnet die Reisedauer in Ticks basierend auf dem Makro-Netzwerk.
	## Nutzt Welt_NetzwerkPlaner.wege() für die Distanz zwischen Karten.
	
	if _netzwerk_planer == null:
		# Fallback: euklidische Distanz * Faktor
		var distanz := von_pos.distance_to(nach_pos)
		return maxi(int(distanz / 50.0), 120)  # Mindestens 5 Sekunden
	
	var wege := _netzwerk_planer.wege()
	var kuerzeste_distanz := INF
	
	# Suche Weg zwischen den Karten (über Fraktionen/Spieler-Region)
	for weg: Dictionary in wege:
		var weg_von_id := str(weg.get("von_id", ""))
		var weg_nach_id := str(weg.get("nach_id", ""))
		var weg_typ := str(weg.get("typ", ""))
		
		# Prüfen ob dieser Weg die Karten verbindet
		var verbindung := false
		if (weg_von_id == von_map_id and weg_nach_id == nach_map_id) or \
		   (weg_von_id == nach_map_id and weg_nach_id == von_map_id):
			verbindung = true
		# Auch Spieler-Startregion beachten
		if (weg_von_id == "spieler" and weg_nach_id == nach_map_id) or \
		   (weg_von_id == nach_map_id and weg_nach_id == "spieler"):
			verbindung = true
		
		if verbindung:
			var v_pos := Vector2(weg.get("von", Vector2i.ZERO))
			var n_pos := Vector2(weg.get("nach", Vector2i.ZERO))
			var dist := v_pos.distance_to(n_pos)
			if dist < kuerzeste_distanz:
				kuerzeste_distanz = dist
	
	if kuerzeste_distanz == INF:
		# Kein direkter Weg: Fallback auf Luftlinie
		kuerzeste_distanz := von_pos.distance_to(nach_pos)
	
	# Umrechnung: 1 Kachel ≈ 50 Pixel, 24 Ticks/Sekunde, Geschwindigkeit ~100 Pixel/Sekunde
	# => Ticks = Distanz / (Geschwindigkeit * Tick_Dauer) = Distanz / (100/24) = Distanz * 0.24
	var ticks := maxi(int(kuerzeste_distanz * 0.24), 60)  # Mindestens 2.5 Sekunden
	return ticks

func karawanen_liste() -> Array[Karawanen_Einheit]:
	return _karawanen.duplicate()

func karawane_bei_index(index: int) -> Karawanen_Einheit:
	if index < 0 or index >= _karawanen.size():
		return null
	return _karawanen[index]

func _draw() -> void:
	## Zeichnet alle Karawanen als bewegte Punkte auf der Weltkarte.
	## Wird von der Weltkarten-Szene (welt_map.gd) oder Welt-Szene aufgerufen.
	for karawane: Karawanen_Einheit in _karawanen:
		if karawane == null:
			continue
		# Nur Karawanen zeichnen, die auf DIESER Karte relevant sind
		var ist_meine := (karawane.von_map_id == _model.map_id) or (karawane.nach_map_id == _model.map_id)
		if not ist_meine:
			continue
		
		var pos := karawane.position_aktuel()
		var zustand := karawane.zustand()
		
		var farbe := KARAWANEN_FARBE
		if zustand == "wartend":
			farbe = Color(0.6, 0.6, 0.6)
		elif zustand == "angekommen" or zustand == "entladen":
			farbe = Color(0.2, 1.0, 0.3)
		elif zustand == "fertig":
			farbe = Color(0.5, 0.5, 0.5)
		
		# Punkt zeichnen
		draw_circle(pos, KARAWANEN_PUNKT_RADIUS, farbe)
		draw_circle(pos, KARAWANEN_PUNKT_RADIUS, KARAWANEN_RAND_FARBE, false, 2.0)
		
		# Fortschrittsbalken bei Reise
		if zustand == "unterwegs":
			var fortschritt := karawane._aktueller_fortschritt
			var balken_breite := KARAWANEN_PUNKT_RADIUS * 4.0
			var balken_hoehe := 3.0
			var balken_pos := pos + Vector2(-balken_breite * 0.5, -KARAWANEN_PUNKT_RADIUS - 8.0)
			var hintergrund_rect := Rect2(balken_pos, Vector2(balken_breite, balken_hoehe))
			var vordergrund_rect := Rect2(balken_pos, Vector2(balken_breite * fortschritt, balken_hoehe))
			draw_rect(hintergrund_rect, Color(0, 0, 0, 0.5))
			draw_rect(vordergrund_rect, Color(1.0, 0.9, 0.2))
		
		# ID anzeigen
		draw_string(ThemeDB.fallback_font, pos + Vector2(-20, KARAWANEN_PUNKT_RADIUS + 10), karawane.karawanen_id, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

func nach_woerterbuch() -> Dictionary:
	var karawanen_daten: Array[Dictionary] = []
	for k: Karawanen_Einheit in _karawanen:
		if k != null:
			karawanen_daten.append(k.nach_woerterbuch())
	return {
		"karawanen": karawanen_daten,
		"naechste_nummer": _naechste_karawanen_nummer
	}

func aus_woerterbuch(daten: Dictionary) -> void:
	var k_daten: Variant = daten.get("karawanen", [])
	if typeof(k_daten) == TYPE_ARRAY:
		for eintrag: Variant in k_daten:
			if typeof(eintrag) == TYPE_DICTIONARY:
				var k := Karawanen_Einheit.new()
				if k.aus_woerterbuch(eintrag as Dictionary):
					_karawanen.append(k)
	_naechste_karawanen_nummer = int(daten.get("naechste_nummer", _naechste_karawanen_nummer))