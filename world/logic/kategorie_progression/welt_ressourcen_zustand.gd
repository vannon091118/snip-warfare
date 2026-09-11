extends RefCounted
class_name Welt_RessourcenZustand
## State-Maschine des Zustands eines einzelnen Weltobjekts: Bestand, Schaden,
## Stadium und Wiederherstellung. Sie ist die einzige Rechenstelle, die aus
## einem Arbeitsschlag oder einem Wachstumstakt den neuen Zustand ableitet;
## das Ergebnis wohnt als Feld am Objekt des Welt_Models und versteht damit
## die Persistenz automatisch. Keine eigene Zeit, keine eigene Liste.

## Kategorie daten: die Feldnamen am Objekt und die Registry.
const FELD_BESTAND := "ressource_bestand"
const FELD_STAERKE := "ressource_staerke"
const FELD_STADIUM := "ressource_stadium"
const FELD_WACHSTUM := "ressource_wachstum"

var _registry: Welt_ProgressionsRegistry = null

## Kategorie logik: Lesen, Schlagen, Wachsen und Wiederherstellen.

func einrichten(registry: Welt_ProgressionsRegistry) -> void:
	_registry = registry

func zustand_erneuern(index: int, model: Welt_Model) -> void:
	# Sichert ab, dass jedes Registry-Objekt im Modell seine Felder traegt:
	# Alte Welten und frische Spawns starten hier ohne Code-Drift.
	if _registry == null or model == null or index < 0 or index >= model.objekt_anzahl():
		return
	var element_id := model.objekt_element_id(index)
	if not _registry.hat_definition(element_id):
		return
	if int(model.objekt_feld(index, FELD_STAERKE, 0)) <= 0:
		model.objekt_feld_setzen(index, FELD_STAERKE, _registry.staerke_fuer(element_id))
	if int(model.objekt_feld(index, FELD_BESTAND, -1)) < 0:
		model.objekt_feld_setzen(index, FELD_BESTAND, _registry.staerke_fuer(element_id))
	if str(model.objekt_feld(index, FELD_STADIUM, "")) == "":
		model.objekt_feld_setzen(index, FELD_STADIUM, _start_stadium_fuer(element_id))

func _start_stadium_fuer(element_id: String) -> String:
	var stadien := _registry.stadien_fuer(element_id)
	if _registry.kategorie_fuer(element_id) == "wachsend":
		return str(stadien[0]) if not stadien.is_empty() else ""
	return str(stadien.back()) if not stadien.is_empty() else ""

func bestand(index: int, model: Welt_Model) -> int:
	return int(model.objekt_feld(index, FELD_BESTAND, 0))

func stadium(index: int, model: Welt_Model) -> String:
	return str(model.objekt_feld(index, FELD_STADIUM, ""))

func schlag(index: int, model: Welt_Model) -> Dictionary:
	# Ein echter Treffer: Bestand sinkt um eins, das Stadium folgt dem
	# Restbestand. Liefert das Ereignis fuer Darsteller und Renderer.
	if _registry == null or model == null or index < 0 or index >= model.objekt_anzahl():
		return {}
	var element_id := model.objekt_element_id(index)
	if not _registry.hat_definition(element_id):
		return {}
	zustand_erneuern(index, model)
	var bestand_neu := maxi(bestand(index, model) - 1, 0)
	model.objekt_feld_setzen(index, FELD_BESTAND, bestand_neu)
	var ereignis := {"element_id": element_id, "index": index, "bestand": bestand_neu, "erschoepft": false, "position": model.objekt_position(index)}
	if bestand_neu <= 0:
		ereignis["erschoepft"] = true
		# Erschoepfte Objekte wechseln an derselben Stelle zu ihrem Rest-Objekt:
		# Die Identitaet folgt dem Datenpool, die Felder starten frisch.
		var folge_id := _registry.folge_objekt_fuer(element_id)
		if folge_id != "":
			model.objekt_feld_setzen(index, "element_id", folge_id)
			model.objekt_feld_setzen(index, FELD_STADIUM, "")
			model.objekt_feld_setzen(index, FELD_BESTAND, -1)
			model.objekt_feld_setzen(index, FELD_STAERKE, -1)
			model.objekt_feld_setzen(index, FELD_WACHSTUM, 0)
			model.objekt_feld_setzen(index, "regeneration_fortschritt", 0)
			zustand_erneuern(index, model)
			ereignis["element_id"] = folge_id
			ereignis["folge_objekt"] = folge_id
	else:
		model.objekt_feld_setzen(index, FELD_STADIUM, _stadium_fuer_bestand(element_id, bestand_neu, int(model.objekt_feld(index, FELD_STAERKE, 1))))
	return ereignis

func _stadium_fuer_bestand(element_id: String, aktueller_bestand: int, staerke: int) -> String:
	# Schadensstadien fuellen sich von voll Richtung Rest: Der Anteil waehlt
	# die Stufe, damit jede sichtbare Stufe dem echten Restbestand folgt.
	var stadien := _registry.stadien_fuer(element_id)
	if stadien.is_empty() or staerke <= 0:
		return ""
	var anteil := clampf(float(aktueller_bestand) / float(staerke), 0.0, 1.0)
	if _registry.kategorie_fuer(element_id) == "wachsend":
		# Wachsende Objekte zeigen ihr Wachstumsstadium, nicht den Schaden.
		return str(model_stadium_fuer(element_id, aktueller_bestand))
	var stufe := clampi(int(round(anteil * float(stadien.size() - 1))), 0, stadien.size() - 1)
	return str(stadien[stufe])

func model_stadium_fuer(element_id: String, wachstum: int) -> String:
	# Wachstumsstadium aus dem Fortschritt: Der Anteil 0..1 waehlt zwischen
	# Keimling und voll entwickelt; die Registry liefert nur die Namen.
	var stadien := _registry.stadien_fuer(element_id)
	if stadien.is_empty():
		return ""
	var dauer := _registry.wachstums_ticks_fuer(element_id)
	if dauer <= 0:
		return str(stadien.back())
	var anteil := clampf(float(wachstum) / float(dauer), 0.0, 1.0)
	var stufe := clampi(int(anteil * float(stadien.size())), 0, stadien.size() - 1)
	return str(stadien[stufe])

func wachstum_ticken(index: int, model: Welt_Model, waerme_faktor: float) -> Dictionary:
	# Ein Wachstumstakt an einem wachsenden Objekt: Der Fortschritt zaehlt
	# mit dem Warmefaktor, das Stadium folgt. Liefert das Stadium-Ereignis,
	# wenn eine sichtbare Stufe erreicht wird, sonst leer.
	if _registry == null or model == null or index < 0 or index >= model.objekt_anzahl():
		return {}
	var element_id := model.objekt_element_id(index)
	if _registry.kategorie_fuer(element_id) != "wachsend":
		return {}
	if _registry.kategorie_fuer(element_id) == "rest":
		return {}
	zustand_erneuern(index, model)
	var dauer := _registry.wachstums_ticks_fuer(element_id)
	if dauer <= 0:
		return {}
	var alt := int(model.objekt_feld(index, FELD_WACHSTUM, 0))
	var bestand_aktuell := bestand(index, model)
	var staerke := int(model.objekt_feld(index, FELD_STAERKE, 1))
	if bestand_aktuell < staerke:
		# Beschädigte wachsende Objekte heilen zuerst ihren Bestand wieder.
		model.objekt_feld_setzen(index, FELD_BESTAND, bestand_aktuell + 1)
		return {}
	if alt >= dauer:
		return {}
	var neu := mini(alt + maxi(int(round(waerme_faktor)), 1), dauer)
	model.objekt_feld_setzen(index, FELD_WACHSTUM, neu)
	var stadium_alt := str(model.objekt_feld(index, FELD_STADIUM, ""))
	var stadium_neu := model_stadium_fuer(element_id, neu)
	if stadium_neu != stadium_alt:
		model.objekt_feld_setzen(index, FELD_STADIUM, stadium_neu)
		return {"element_id": element_id, "index": index, "stadium": stadium_neu, "position": model.objekt_position(index)}
	return {}

func ist_erschoepft(index: int, model: Welt_Model) -> bool:
	return bestand(index, model) <= 0 and model != null and index >= 0 and index < model.objekt_anzahl()

func regeneration_ticken(index: int, model: Welt_Model) -> String:
	# Rest-Objekte kehren als neuer Keimling desselben Typs zurueck, wenn
	# ihre Regenerationszeit um ist; der Fortschritt wohnt am Objekt selbst.
	if _registry == null or model == null or index < 0 or index >= model.objekt_anzahl():
		return ""
	var element_id := model.objekt_element_id(index)
	var definition := _registry.definition_fuer(element_id)
	if definition.is_empty() or str(definition.get("kategorie", "")) != "rest":
		return ""
	var folge_id := str(definition.get("folge_objekt", ""))
	if folge_id == "":
		# Ein Rest ohne Folgeobjekt wächst sich selbst als Keimling nach.
		folge_id = element_id
	var dauer := maxi(int(definition.get("regenerations_ticks", 0)), 1)
	var alt := int(model.objekt_feld(index, "regeneration_fortschritt", 0))
	var neu := alt + 1
	if neu < dauer:
		model.objekt_feld_setzen(index, "regeneration_fortschritt", neu)
		return ""
	# Wiedergeburt: Dieselbe Objektstelle wechselt ihre Identität, die
	# Position bleibt unverändert und die Felder starten frisch.
	model.objekt_feld_setzen(index, "element_id", folge_id)
	model.objekt_feld_setzen(index, "ressource_stadium", "")
	model.objekt_feld_setzen(index, "ressource_bestand", -1)
	model.objekt_feld_setzen(index, "ressource_staerke", -1)
	model.objekt_feld_setzen(index, "ressource_wachstum", 0)
	model.objekt_feld_setzen(index, "regeneration_fortschritt", 0)
	zustand_erneuern(index, model)
	return folge_id
