extends RefCounted
class_name Einheit_AutonomieMaschine
## Autonomie der Idle-Einheiten (CP-6.4): Wenn kein Job und kein Notfall
## ansteht, liest diese Maschine die Prioritaeten aus game/data/autonomie.json
## und vergibt den ersten erfuellten Auftrag. Reihenfolge und Suchradius
## stehen allein im Datenpool; diese Maschine rechnet keine Ordnung selbst.
## Die Ausfuehrung bleibt in der Job-Architektur: Sie vergibt ueber denselben
## Manager-Ruf wie der Spieler, nur ohne Maus.

const QUELLE := "res://game/data/autonomie.json"

## Kategorie daten: Die Prioritaeten aus dem Pool und die Zustandsquellen.
var _schritte: Array[Dictionary] = []
var _manager: Einheit_Manager = null
var _model: Welt_Model = null

## Kategorie logik: Laden, Prioritaet pruefen, Auftrag vergeben.

func _init() -> void:
	laden()

func laden() -> void:
	_schritte.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Autonomie-Konfiguration nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Autonomie-Konfiguration ungueltiges Format: %s" % QUELLE)
		return
	for eintrag: Variant in (gelesen as Dictionary).get("schritte", []):
		if eintrag is Dictionary:
			_schritte.append((eintrag as Dictionary).duplicate(true))

func einrichten(p: Dictionary) -> void:
	_manager = p.get("manager")
	_model = p.get("model")

func modell_setzen(neues_modell: Welt_Model) -> void:
	_model = neues_modell

func autonom_fuer(einheit_index: int) -> void:
	## Erstes erfuelltes Prioritaetsschritt-Kriterium gewinnt; ohne Treffer
	## bleibt die Einheit im Idle und kostet nichts.
	for schritt: Dictionary in _schritte:
		var ziel := _ziel_fuer_schritt(schritt)
		if ziel.is_empty():
			continue
		_manager.job_vergeben(einheit_index, str(schritt.get("job_id", "")),
			Job_Basis.ZielTyp.OBJEKT, int(ziel.get("index", -1)),
			ziel.get("position", Vector2.ZERO))
		return

func _ziel_fuer_schritt(schritt: Dictionary) -> Dictionary:
	## Suchradius und Ziel-Objekte aus dem Schritt; die naechste erfuellende
	## Position gewinnt. Ohne Modell oder Treffer bleibt es leer.
	if _model == null or _manager == null:
		return {}
	var reichweite := float(schritt.get("suchradius", 10.0)) * float(_model.kachel_groesse)
	var anker: Vector2 = _manager.ankunftsort()
	var beste_distanz := INF
	var bester := {}
	for index in _model.objekt_anzahl():
		if not _passt_zu_schritt(index, schritt):
			continue
		var position := _model.objekt_position(index)
		var distanz := position.distance_to(anker)
		if distanz > reichweite:
			continue
		if distanz < beste_distanz:
			beste_distanz = distanz
			bester = {"index": index, "position": position}
	return bester

func _passt_zu_schritt(index: int, schritt: Dictionary) -> bool:
	## Zwei Kriterien aus Daten: Element-Objekte ueber die Katalog-Id,
	## Baustellen ueber ihre Bau-Phase (Bauplan oder angefordert).
	var element_id := _model.objekt_element_id(index)
	if (schritt.get("ziel_objekte", []) as Array).has(element_id):
		return true
	var phasen: Variant = schritt.get("baustellen_phasen", [])
	if phasen is Array and not (phasen as Array).is_empty():
		var phase := int(_model.objekt_feld(index, "bau_phase", 0))
		return (phasen as Array).has(phase)
	return false
