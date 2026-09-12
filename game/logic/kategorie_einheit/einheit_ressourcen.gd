extends RefCounted
class_name Einheit_Ressourcen
## Verwaltung der Ressourcenbestände über das Domänen-Schema.
## Jede Änderung der Bestände ist eine Mutation: Das Schema liefert den
## neuen Zustand, die Bestände werden daraus gelesen. Varianz wird dabei
## aus dem Zustand abgeleitet und als Zustand festgehalten (deterministisch,
## wiederholbar, keine False Truth).

signal bestand_geaendert(ressource: String, neuer_bestand: int)

const KONFIG_PFAD := "res://game/data/ressourcen.json"
# Die Zustands-Timeline ist optional: Jede Buchung wird als Delta-Eintrag
# mit Quelle und Beschreibung protokolliert, damit der Zustand jederzeit
# rekonstruierbar und die Frage warum ist das so beantwortbar bleibt.
var _timeline: Kern_Timeline = null

## Kategorie daten: Instanzen der Ressourcen-Datenklassen und der aktuelle Zustand.
var ressourcen_objekte: Array[Ressource_Basis] = []
var aktueller_zustand: Dictionary = {}

## Kategorie logik: Zuordnungen, Schema-Ausführung und Signale.
var _objekte_nach_id: Dictionary = {}
var _schema := Einheit_RessourcenSchema.new()
var _lager: Lager_Manager = null
var _letzte_ernte_position: Vector2 = Vector2.INF

func _init() -> void:
	_lade_ressourcen()
	_startzustand_fahren()

func _lade_ressourcen() -> void:
	if not FileAccess.file_exists(KONFIG_PFAD):
		push_warning("Ressourcen-Konfiguration nicht gefunden: %s" % KONFIG_PFAD)
		return
	var datei := FileAccess.open(KONFIG_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Ressourcen-Konfiguration hat ein ungültiges Format: %s" % KONFIG_PFAD)
		return
	for ressourcen_id: String in gelesen.keys():
		var eintrag: Dictionary = gelesen[ressourcen_id]
		eintrag["id"] = ressourcen_id
		var objekt := _ressourcen_klasse_fuer(ressourcen_id, eintrag)
		objekt.aus_konfig_eintrag(eintrag)
		ressourcen_objekte.append(objekt)
		_objekte_nach_id[ressourcen_id] = objekt

func _ressourcen_klasse_fuer(ressourcen_id: String, eintrag: Dictionary = {}) -> Ressource_Basis:
	# Plugin-Naht: Das script-Feld aus dem Pool bestimmt die Datenklasse;
	# eine neue Ressource braucht künftig nur Pool-Eintrag plus Icon, ohne
	# dass diese Klasse angefasst wird. ResourceLoader.exists verhindert
	# Halluzinationen bei Tippfehlern, die Typprüfung hält fremde Skripte raus.
	# Einträge ohne script-Feld fallen auf die zentrale Zuordnung zurück.
	var skript_pfad := str(eintrag.get("script", ""))
	if skript_pfad != "":
		if not ResourceLoader.exists(skript_pfad):
			push_warning("Ressourcen-Skript fehlt: %s (Eintrag %s)" % [skript_pfad, ressourcen_id])
			return _zentrale_klasse_fuer(ressourcen_id)
		var skript: GDScript = load(skript_pfad)
		if skript != null:
			var instanz: Variant = skript.new()
			if instanz is Ressource_Basis:
				return instanz as Ressource_Basis
			push_warning("Ressourcen-Skript ist kein Ressource_Basis: %s" % skript_pfad)
	return _zentrale_klasse_fuer(ressourcen_id)

func _zentrale_klasse_fuer(ressourcen_id: String) -> Ressource_Basis:
	# Übergangs-Fallback für Pool-Einträge ohne script-Feld.
	match ressourcen_id:
		"holz":
			return Ressource_Holz.new()
		"stein":
			return Ressource_Stein.new()
		"fleisch":
			return Ressource_Fleisch.new()
		"werkzeug":
			return Ressource_Werkzeug.new()
		"raeuchelfleisch":
			return Ressource_Raeuchelfleisch.new()
		"beeren":
			return Ressource_Beeren.new()
	return Ressource_Basis.new()

func _startzustand_fahren() -> void:
	# Startzustand aus dem Schema fahren, damit die Bestände von Anfang an
	# über die Mutationen führen.
	aktueller_zustand = _schema.ausfuehren({})

func _bestaende_lesen() -> Dictionary:
	return aktueller_zustand.get("bestaende", {})

func ressource_ids() -> Array[String]:
	var ids: Array[String] = []
	for objekt: Ressource_Basis in ressourcen_objekte:
		ids.append(objekt.ressourcen_id)
	return ids

func icon_pfad(ressource: String) -> String:
	if not _objekte_nach_id.has(ressource):
		return ""
	return _objekte_nach_id[ressource].icon_pfad

func ressource_name(ressource: String) -> String:
	if not _objekte_nach_id.has(ressource):
		return ressource
	return _objekte_nach_id[ressource].ressourcen_name

func lager_setzen(lager: Lager_Manager) -> void:
	_lager = lager

func timeline_setzen(timeline: Kern_Timeline) -> void:
	# Die Timeline ist eine reine Beobachtungsstelle: Sie bekommt den
	# Ursprungs-Snapshot der Bestaende und dann jede Buchung als Delta.
	# Der Ursprung ist flach (ressource -> menge), damit die Rekonstruktion
	# die Delta-Eintraege direkt anwenden kann.
	_timeline = timeline
	if _timeline != null:
		var ursprung := _bestaende_lesen().duplicate(true)
		if _lager != null and _lager.lager_zahl() > 0:
			ursprung = _lager.gesamt_bestand_alle()
		_timeline.ursprung_festlegen(ursprung)

func timeline_holen() -> Kern_Timeline:
	return _timeline

func _timeline_buchung(quelle: String, beschreibung: String, ressource: String, alte_menge: int, neue_menge: int) -> void:
	if _timeline == null:
		return
	var tick := 0
	var baum := Engine.get_main_loop() as SceneTree
	if baum != null:
		var weltuhr := baum.root.get_node_or_null("/root/Weltuhr")
		if weltuhr != null and weltuhr.has_method("tick_nummer"):
			tick = int(weltuhr.tick_nummer())
	_timeline.eintrag_anhaengen(tick, "ressourcen", quelle, beschreibung,
		{ressource: alte_menge}, {ressource: neue_menge})

func ernte_position_setzen(welt_position: Vector2) -> void:
	_letzte_ernte_position = welt_position

func bestand(ressource: String) -> int:
	if _lager != null and _lager.lager_zahl() > 0:
		return _lager.gesamt_bestand(ressource)
	return int(_bestaende_lesen().get(ressource, 0))

func bestand_lokal(ressource: String, lager_index: int) -> int:
	if _lager == null:
		return bestand(ressource)
	return _lager.bestand_im_lager(lager_index, ressource)

func kann_entnehmen(ressource: String, menge: int, lager_index: int) -> bool:
	if _lager == null:
		return bestand(ressource) >= menge
	return _lager.bestand_im_lager(lager_index, ressource) >= menge

func hinzufuegen(ressource: String, menge: int) -> void:
	# Die Ernte geht als Erntebuchung in das Schema ein; das Ergebnis ist
	# der neue Zustand, aus dem der Bestand gelesen wird.
	# Mit gesetztem Lager wird die finale Menge ins naechste lokale Lager
	# geschrieben; der globale Bestand ist nur die Summe fuer die UX.
	if menge <= 0:
		return
	var start := {"erntebuchung": {"ressource": ressource, "menge": menge}}
	var ergebnis_zustand := start
	ergebnis_zustand["bestaende"] = _bestaende_lesen().duplicate(true)
	ergebnis_zustand["letzter_zufallswurf"] = aktueller_zustand.get("letzter_zufallswurf", 0)
	var zustand := _schema.ausfuehren(ergebnis_zustand)
	var alte_summe := bestand(ressource)
	_zustand_uebernehmen(zustand)
	if _lager != null and _lager.lager_zahl() > 0:
		var final_menge := int(zustand.get("letzte_buchung", {}).get("menge", menge))
		var lager_index := _lager.naechstes_lager_fuer(_letzte_ernte_position)
		if lager_index >= 0:
			_lager.einlagern(ressource, final_menge, lager_index)
		var neue_summe := _lager.gesamt_bestand(ressource)
		if alte_summe != neue_summe:
			bestand_geaendert.emit(ressource, neue_summe)
		_timeline_buchung("einlagern", "%s eingelagert" % ressource, ressource, alte_summe, neue_summe)
		return
	_timeline_buchung("einlagern", "%s eingelagert" % ressource, ressource, alte_summe, bestand(ressource))

func kann_mehrfach_entnehmen(paare: Array[Dictionary], lager_index: int = -1) -> bool:
	# Kumulative Pruefung: Gleiche Ressourcen werden summiert und erst die
	# Summe wird gegen den Bestand geprueft. Ein Rezept mit zweimal derselben
	# Ressource kann damit nicht an der Pruefung vorbei teilweise entnehmen.
	var summen := {}
	for paar: Dictionary in paare:
		var ressource := str(paar.get("ressource", ""))
		summen[ressource] = int(summen.get(ressource, 0)) + int(paar.get("menge", 0))
	for ressource: String in summen:
		if not kann_entnehmen(ressource, int(summen[ressource]), lager_index):
			return false
	return true

func mehrfach_entnehmen(paare: Array[Dictionary], lager_index: int = -1) -> bool:
	# Atomare Buchung: Die kumulative Pruefung garantiert, dass alle Mengen
	# zusammen gedeckt sind; erst dann wird je Paar entnommen. Scheitert eine
	# Entnahme dennoch, werden die bereits entnommenen Mengen in dasselbe
	# Lager zurueckgebucht, damit nie eine Teilbuchung stehen bleibt.
	if not kann_mehrfach_entnehmen(paare, lager_index):
		return false
	var gebucht: Array[Dictionary] = []
	for paar: Dictionary in paare:
		var ressource := str(paar.get("ressource", ""))
		var menge := int(paar.get("menge", 0))
		if menge <= 0:
			continue
		if not entnehmen(ressource, menge, lager_index):
			for zurueck: Dictionary in gebucht:
				_rueckbuchung(str(zurueck.get("ressource", "")), int(zurueck.get("menge", 0)), lager_index)
			return false
		gebucht.append({"ressource": ressource, "menge": menge})
	return true

func _rueckbuchung(ressource: String, menge: int, lager_index: int) -> void:
	# Gibt eine bereits entnommene Menge in dasselbe Lager zurueck, damit
	# eine gescheiterte Mehrfach-Entnahme keinen Teilbestand verliert.
	var alte_summe := bestand(ressource)
	if _lager != null and _lager.lager_zahl() > 0 and lager_index >= 0:
		_lager.einlagern(ressource, menge, lager_index)
		_timeline_buchung("rueckbuchung", "Rueckbuchung %s" % ressource, ressource, alte_summe, bestand(ressource))
		return
	var bestaende := _bestaende_lesen().duplicate(true)
	bestaende[ressource] = int(bestaende.get(ressource, 0)) + menge
	_zustand_uebernehmen({"bestaende": bestaende, "letzter_zufallswurf": aktueller_zustand.get("letzter_zufallswurf", 0)})
	_timeline_buchung("rueckbuchung", "Rueckbuchung %s" % ressource, ressource, alte_summe, bestand(ressource))

func entnehmen(ressource: String, menge: int, lager_index: int = -1) -> bool:
	if menge <= 0:
		return false
	var alte_summe := bestand(ressource)
	if _lager != null and _lager.lager_zahl() > 0:
		var ziel_index := lager_index
		if ziel_index < 0:
			ziel_index = _lager.naechstes_lager_fuer(_letzte_ernte_position)
		if ziel_index < 0 or not _lager.entnehmen(ressource, menge, ziel_index):
			return false
		bestand_geaendert.emit(ressource, _lager.gesamt_bestand(ressource))
		_timeline_buchung("entnehmen", "%s entnommen" % ressource, ressource, alte_summe, bestand(ressource))
		return true
	var aktueller := int(_bestaende_lesen().get(ressource, 0))
	if aktueller < menge:
		return false
	var bestaende := _bestaende_lesen().duplicate(true)
	bestaende[ressource] = aktueller - menge
	var zustand := {"bestaende": bestaende, "letzter_zufallswurf": aktueller_zustand.get("letzter_zufallswurf", 0)}
	_zustand_uebernehmen(zustand)
	_timeline_buchung("entnehmen", "%s entnommen" % ressource, ressource, aktueller, bestand(ressource))
	return true

func _zustand_uebernehmen(zustand: Dictionary) -> void:
	# Vergleicht den neuen Bestand mit dem alten und meldet Änderungen.
	var alte_bestaende := _bestaende_lesen()
	aktueller_zustand = zustand
	var neue_bestaende := _bestaende_lesen()
	for ressource: String in neue_bestaende.keys():
		var neuer_bestand := int(neue_bestaende[ressource])
		if int(alte_bestaende.get(ressource, 0)) != neuer_bestand:
			bestand_geaendert.emit(ressource, neuer_bestand)

func schema_zustand() -> Dictionary:
	# Der vollständige Zustand inklusive Zufallsständen; für Spielstand und Tests.
	return aktueller_zustand.duplicate(true)
