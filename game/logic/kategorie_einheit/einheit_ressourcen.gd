extends RefCounted
class_name Einheit_Ressourcen
## Verwaltung der Ressourcenbestände über das Domänen-Schema.
## Jede Änderung der Bestände ist eine Mutation: Das Schema liefert den
## neuen Zustand, die Bestände werden daraus gelesen. Varianz wird dabei
## aus dem Zustand abgeleitet und als Zustand festgehalten (deterministisch,
## wiederholbar, keine False Truth).

signal bestand_geaendert(ressource: String, neuer_bestand: int)

const KONFIG_PFAD := "res://game/data/ressourcen.json"

## Kategorie daten: Instanzen der Ressourcen-Datenklassen und der aktuelle Zustand.
var ressourcen_objekte: Array[Resource_Basis] = []
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
		var objekt := _ressourcen_klasse_fuer(ressourcen_id)
		objekt.aus_konfig_eintrag(eintrag)
		ressourcen_objekte.append(objekt)
		_objekte_nach_id[ressourcen_id] = objekt

func _ressourcen_klasse_fuer(ressourcen_id: String) -> Resource_Basis:
	# Zentrale Zuordnung: jede Ressource erhält ihre eigene Datenklasse.
	match ressourcen_id:
		"holz":
			return Resources_Wood.new()
		"stein":
			return Resources_Stone.new()
		"fleisch":
			return Resources_Meat.new()
		"werkzeug":
			return Resources_Werkzeug.new()
	return Resource_Basis.new()

func _startzustand_fahren() -> void:
	# Startzustand aus dem Schema fahren, damit die Bestände von Anfang an
	# über die Mutationen führen.
	aktueller_zustand = _schema.ausfuehren({})

func _bestaende_lesen() -> Dictionary:
	return aktueller_zustand.get("bestaende", {})

func ressource_ids() -> Array[String]:
	var ids: Array[String] = []
	for objekt: Resource_Basis in ressourcen_objekte:
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
		return

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
	if _lager != null and _lager.lager_zahl() > 0 and lager_index >= 0:
		_lager.einlagern(ressource, menge, lager_index)
		return
	var bestaende := _bestaende_lesen().duplicate(true)
	bestaende[ressource] = int(bestaende.get(ressource, 0)) + menge
	_zustand_uebernehmen({"bestaende": bestaende, "letzter_zufallswurf": aktueller_zustand.get("letzter_zufallswurf", 0)})

func entnehmen(ressource: String, menge: int, lager_index: int = -1) -> bool:
	if menge <= 0:
		return false
	if _lager != null and _lager.lager_zahl() > 0:
		var ziel_index := lager_index
		if ziel_index < 0:
			ziel_index = _lager.naechstes_lager_fuer(_letzte_ernte_position)
		if ziel_index < 0 or not _lager.entnehmen(ressource, menge, ziel_index):
			return false
		bestand_geaendert.emit(ressource, _lager.gesamt_bestand(ressource))
		return true
	var aktueller := int(_bestaende_lesen().get(ressource, 0))
	if aktueller < menge:
		return false
	var bestaende := _bestaende_lesen().duplicate(true)
	bestaende[ressource] = aktueller - menge
	var zustand := {"bestaende": bestaende, "letzter_zufallswurf": aktueller_zustand.get("letzter_zufallswurf", 0)}
	_zustand_uebernehmen(zustand)
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
