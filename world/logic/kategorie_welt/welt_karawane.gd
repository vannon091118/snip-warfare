extends RefCounted
class_name Welt_Karawane
## Karawanen-Einheit: Repräsentiert eine Handels-Karawane, die zwischen Karten
## der World pendelt. Sie besitzt eine eigene State Machine für Reise, Ankunft
## und Entladung. Die Reisedauer wird aus dem Makro-Netzwerk (Welt_NetzwerkPlaner.wege)
## berechnet. Auf der Weltkarte sichtbar als bewegter Punkt.

## Kategorie daten: Identität, Route und Reisestatus.
var karawanen_id: String = ""
var von_map_id: String = ""
var nach_map_id: String = ""
var von_position: Vector2 = Vector2.ZERO
var nach_position: Vector2 = Vector2.ZERO
var reise_ticks: int = 0
var _verbleibende_ticks: int = 0
var _zustand: String = "wartend"  # wartend, unterwegs, angekommen, entladen, fertig
var _fraescht: Dictionary = {}  # ressource -> menge
var _aktueller_fortschritt: float = 0.0

## Kategorie logik: State Machine und Tick-Verarbeitung.

enum Zustand { WARTEND, UNTERWEGS, ANGEKOMMEN, ENTLADEN, FERTIG }

func _init(k_id: String = "", von: String = "", nach: String = "", v_pos: Vector2 = Vector2.ZERO, n_pos: Vector2 = Vector2.ZERO, ticks: int = 0, fracht_ladung: Dictionary = {}) -> void:
	karawanen_id = k_id
	von_map_id = von
	nach_map_id = nach
	von_position = v_pos
	nach_position = n_pos
	reise_ticks = maxi(ticks, 1)
	_verbleibende_ticks = reise_ticks
	_fraescht = fracht_ladung.duplicate(true)
	_zustand = "wartend"
	_aktueller_fortschritt = 0.0

func reise_starten() -> void:
	## Startet die Reise: Setzt den Zustand auf UNTERWEGS.
	if _zustand == "wartend":
		_zustand = "unterwegs"
		_verbleibende_ticks = reise_ticks
		_aktueller_fortschritt = 0.0

func als_fertig_markieren() -> void:
	## Markiert die Karawane als vollständig abgewickelt (nach erfolgreichem Entladen).
	_zustand = "fertig"
	_verbleibende_ticks = 0
	_aktueller_fortschritt = 1.0

func tick() -> bool:
	## Verarbeitet einen Tick der Reise. Gibt true zurück, wenn die Karawane
	## angekommen ist und entladen werden kann.
	if _zustand != "unterwegs":
		return false
	
	_verbleibende_ticks -= 1
	_aktueller_fortschritt = 1.0 - (float(_verbleibende_ticks) / float(reise_ticks))
	
	if _verbleibende_ticks <= 0:
		_zustand = "angekommen"
		_verbleibende_ticks = 0
		_aktueller_fortschritt = 1.0
		return true
	return false

func position_aktuel() -> Vector2:
	## Liefert die interpolierte Position auf der Weltkarte für die Anzeige.
	if _zustand == "wartend":
		return von_position
	if _zustand == "unterwegs":
		return von_position.lerp(nach_position, _aktueller_fortschritt)
	return nach_position

func ist_unterwegs() -> bool:
	return _zustand == "unterwegs"

func ist_angekommen() -> bool:
	return _zustand == "angekommen"

func ist_fertig() -> bool:
	return _zustand == "fertig"

func zustand() -> String:
	return _zustand

func fracht() -> Dictionary:
	return _fraescht.duplicate(true)

func fracht_hinzufuegen(ressource: String, menge: int) -> void:
	if menge <= 0:
		return
	_fraescht[ressource] = int(_fraescht.get(ressource, 0)) + menge

func fracht_entnehmen(ressource: String, menge: int) -> int:
	var vorhanden := int(_fraescht.get(ressource, 0))
	var entnommen := mini(vorhanden, menge)
	if entnommen > 0:
		_fraescht[ressource] = vorhanden - entnommen
		if _fraescht[ressource] <= 0:
			_fraescht.erase(ressource)
	return entnommen

func fracht_leer() -> bool:
	return _fraescht.is_empty()

func entladen(ziel_lager_manager: Object) -> bool:
	## Lädt die Fracht in das Ziel-Lager ein. Gibt true zurück, wenn alles
	## entladen wurde. Erwartet einen Lager_Manager mit einlagern()-Methode.
	if _zustand != "angekommen" and _zustand != "entladen":
		return false
	
	_zustand = "entladen"
	var alles_erfolgreich := true
	
	for ressource: String in _fraescht.keys():
		var menge := int(_fraescht[ressource])
		if menge <= 0:
			continue
		# Der Ziel-Lager-Manager muss die Methode naechstes_lager_fuer() und
		# einlagern() bereitstellen. Wir nutzen Position (0,0) als Fallback
		# für den Lager-Index, da die Karawane auf Kartenebene agiert.
		var lager_index := 0
		if ziel_lager_manager != null and ziel_lager_manager.has_method("naechstes_lager_fuer"):
			lager_index = ziel_lager_manager.naechstes_lager_fuer(nach_position)
		if lager_index < 0:
			lager_index = 0
		
		if ziel_lager_manager != null and ziel_lager_manager.has_method("einlagern"):
			var ok: bool = ziel_lager_manager.einlagern(ressource, menge, lager_index)
			if not ok:
				alles_erfolgreich = false
		else:
			alles_erfolgreich = false
	
	if alles_erfolgreich:
		_fraescht.clear()
		_zustand = "fertig"
	
	return alles_erfolgreich

func reise_dauer_text() -> String:
	## Formatierte Reisedauer für UI-Anzeige.
	var sekunden := Kern_Weltuhr.sekunden_aus_ticks(reise_ticks)
	if sekunden < 60:
		return "%ds" % int(sekunden)
	var minuten := int(sekunden / 60)
	var rest_sek := int(fmod(sekunden, 60.0))
	return "%dm %ds" % [minuten, rest_sek]

func nach_woerterbuch() -> Dictionary:
	return {
		"karawanen_id": karawanen_id,
		"von_map_id": von_map_id,
		"nach_map_id": nach_map_id,
		"von_position": [von_position.x, von_position.y],
		"nach_position": [nach_position.x, nach_position.y],
		"reise_ticks": reise_ticks,
		"verbleibende_ticks": _verbleibende_ticks,
		"zustand": _zustand,
		"fracht": _fraescht,
		"fortschritt": _aktueller_fortschritt
	}

func aus_woerterbuch(daten: Dictionary) -> bool:
	if daten.is_empty():
		return false
	karawanen_id = str(daten.get("karawanen_id", ""))
	von_map_id = str(daten.get("von_map_id", ""))
	nach_map_id = str(daten.get("nach_map_id", ""))
	var v_pos: Variant = daten.get("von_position", [0, 0])
	var n_pos: Variant = daten.get("nach_position", [0, 0])
	von_position = Vector2(v_pos[0], v_pos[1])
	nach_position = Vector2(n_pos[0], n_pos[1])
	reise_ticks = maxi(int(daten.get("reise_ticks", 0)), 1)
	_verbleibende_ticks = int(daten.get("verbleibende_ticks", reise_ticks))
	_zustand = str(daten.get("zustand", "wartend"))
	_fraescht = daten.get("fracht", {})
	_aktueller_fortschritt = float(daten.get("fortschritt", 0.0))
	return true