extends RefCounted
class_name Objekt_MoebelPlatzierer
## Platzierer der Moebel-Domaene: Ein Moebel-Bauauftrag aus dem Bau-Panel
## landet direkt und kostenlos im Weltmodell. Der Moebel ist sofort da,
## weil er ein Raum-Objekt ist und keine Baustelle: Er vervollstaendigt
## Raeume, statt produziert zu werden. Er belegt seinen Kachel-Fuss aus
## dem Katalog (kachel_breite/kachel_hoehe) kachelgenau, damit kein
## zweites Moebel denselben Boden beansprucht.

signal moebel_platziert(objekt_index: int)

## Kategorie daten: Verbindungen zu Modell und Registry.
var _model: Welt_Model = null
var _registry: Welt_Registry = null

## Kategorie logik: Einrichten, Pruefen und Platzieren.

func einrichten(model: Welt_Model, registry: Welt_Registry) -> void:
	_model = model
	_registry = registry

func platzieren(moebel_id: String, fusspunkt: Vector2) -> Dictionary:
	## Platziert ein Moebel an seinem Kachel-Anker und liefert das Ergebnis
	## als Dictionary: ok, grund oder objekt_index.
	if _model == null or _registry == null:
		return {"ok": false, "grund": "nicht bereit"}
	var moebel := _registry.moebel().moebel(moebel_id)
	if moebel == null:
		return {"ok": false, "grund": "unbekanntes Moebel"}
	var fuss := _registry.moebel().kachel_fuss(moebel_id)
	var kante := maxi(_model.kachel_groesse, 1)
	var anker := _kachel_anker(fusspunkt, fuss, kante)
	if not _fuss_frei(anker, fuss, kante):
		return {"ok": false, "grund": "Kacheln bereits belegt"}
	var objekt_index := _model.objekt_hinzufuegen(moebel_id, anker)
	_model.objekt_feld_setzen(objekt_index, "moebel_id", moebel_id)
	_model.objekt_feld_setzen(objekt_index, "kachel_fuss", [fuss.x, fuss.y])
	moebel_platziert.emit(objekt_index)
	return {"ok": true, "objekt_index": objekt_index}

func _kachel_anker(wunsch: Vector2, fuss: Vector2i, kante: int) -> Vector2:
	## Der Wunschpunkt wird zur Kachel gerundet; der Anker liegt an der
	## linken oberen Kachel-Ecke des Fusses, damit Anzeige und Belegung
	## dieselbe Wahrheit teilen. Der Fuss wächst nach rechts und unten.
	var kachel_x := int(floor(wunsch.x / float(kante))) - (fuss.x - 1) / 2
	var kachel_y := int(floor(wunsch.y / float(kante))) - (fuss.y - 1) / 2
	return Vector2(float(kachel_x * kante), float(kachel_y * kante))

func _fuss_frei(anker: Vector2, fuss: Vector2i, kante: int) -> bool:
	## Jede Kachel des Fusses muss bodenfrei sein: Ein existierendes
	## Moebel-Objekt auf derselben Kachel blockiert die Platzierung.
	for dx in fuss.x:
		for dy in fuss.y:
			var kachel := Vector2(
				anker.x + float(dx * kante),
				anker.y + float(dy * kante)
			)
			if not _kachel_frei(kachel, kante):
				return false
	return true

func _kachel_frei(kachel_mitte: Vector2, kante: int) -> bool:
	for index in _model.objekt_anzahl():
		if str(_model.objekt_feld(index, "moebel_id", "")) == "":
			continue
		var andere := _model.objekt_position(index)
		if andere.distance_to(kachel_mitte) < float(kante) * 0.5:
			return false
	return true
