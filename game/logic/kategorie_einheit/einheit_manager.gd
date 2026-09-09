extends Node2D
class_name Einheit_Manager
## Verwaltung aller Strichmännchen-Einheiten im Takt der globalen Weltuhr.
## Die Einheiten bewegen sich nie selbst: Positionen legt der Spieler fest.
## Der Manager setzt Jobs ein, prüft, ob das Ziel noch existiert, und leitet
## Ernteergebnisse an die Ressourcenverwaltung weiter.

## Kategorie daten: Einheiten-Liste mit Status, Darsteller und Position.
var _einheiten: Array[Dictionary] = []

## Kategorie logik: Registries und Verbindungen zu anderen Domänen.
var _job_registry := Job_Registry.new()
var _model: Welt_Model = null
var _tiere: Tier_Manager = null
var _ressourcen: Einheit_Ressourcen = null

func _enter_tree() -> void:
	Weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
	if Weltuhr.tick.is_connected(_auf_tick):
		Weltuhr.tick.disconnect(_auf_tick)

func einrichten(model: Welt_Model, tiere: Tier_Manager, ressourcen: Einheit_Ressourcen) -> void:
	_model = model
	_tiere = tiere
	_ressourcen = ressourcen

func einheit_hinzufuegen(position: Vector2) -> void:
	var status := Einheit_Status.new()
	var darsteller := Einheit_Darsteller.new()
	darsteller.einrichten(status)
	darsteller.position = position
	darsteller.animation_setzen(status.animation())
	add_child(darsteller)
	status.arbeitsschritt_erledigt.connect(_auf_arbeitsschritt)
	_einheiten.append({
		"status": status,
		"darsteller": darsteller,
		"position": position,
	})

func einheit_zahl() -> int:
	return _einheiten.size()

func einheit_position(index: int) -> Vector2:
	if index < 0 or index >= _einheiten.size():
		return Vector2.ZERO
	return _einheiten[index]["position"]

func einheit_position_setzen(index: int, position: Vector2) -> void:
	# Bewegung kommt ausschließlich vom Spieler, nie aus einer State Machine.
	if index < 0 or index >= _einheiten.size():
		return
	_einheiten[index]["position"] = position
	var darsteller: Einheit_Darsteller = _einheiten[index]["darsteller"]
	darsteller.position = position

func job_vergeben(einheit_index: int, job_id: String, ziel_typ: Job_Basis.ZielTyp, ziel_index: int, ziel_position: Vector2) -> bool:
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return false
	var job := _job_registry.job_erzeugen(job_id)
	if job == null:
		return false
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	var ressource := job.ressource()
	status.job_vergeben(job, ziel_typ, ziel_index, ressource)
	# Die Blickrichtung zeigt zum gewählten Job-Objekt.
	status.blick_richtung_setzen(ziel_position.x >= einheit_position(einheit_index).x)
	var darsteller: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())
	darsteller.flip_h = not status.blick_richtung_rechts()
	return true

func job_id_einheit(einheit_index: int) -> String:
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return ""
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	if status.job == null:
		return ""
	return status.job.job_id

func einheit_job_abbrechen(einheit_index: int) -> void:
	# Der Spieler bricht den Job ab; die Einheit fällt zurück in den Idle.
	if einheit_index < 0 or einheit_index >= _einheiten.size():
		return
	var status: Einheit_Status = _einheiten[einheit_index]["status"]
	status.job_abbrechen()
	var darsteller: Einheit_Darsteller = _einheiten[einheit_index]["darsteller"]
	darsteller.animation_setzen(status.animation())

func _auf_tick(_nummer: int, delta: float) -> void:
	for einheit: Dictionary in _einheiten:
		var status: Einheit_Status = einheit["status"]
		if status.zustand == Einheit_Status.Zustand.ARBEITEN and not _ziel_existiert(status):
			# Ziel wurde in der Zwischenzeit entfernt: Job endet.
			status.job_abbrechen()
			var darsteller: Einheit_Darsteller = einheit["darsteller"]
			darsteller.animation_setzen(status.animation())
			continue
		status.tick(delta)

func _ziel_existiert(status: Einheit_Status) -> bool:
	if status.job == null:
		return false
	match status.aktuelles_ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model == null:
				return false
			return status.aktuelles_ziel_index < _model.objekte.size()
		Job_Basis.ZielTyp.TIER:
			if _tiere == null:
				return false
			return _tiere.tier_position(status.aktuelles_ziel_index) != Vector2.INF
	return false

func _auf_arbeitsschritt(ressource: String, menge: int) -> void:
	# Ein Arbeitsschritt ist fertig; je nach Job-Typ wird geerntet.
	for einheit: Dictionary in _einheiten:
		var status: Einheit_Status = einheit["status"]
		if status.zustand != Einheit_Status.Zustand.ARBEITEN or status.ziel_ressource != ressource:
			continue
		match status.aktuelles_ziel_typ:
			Job_Basis.ZielTyp.OBJEKT:
				# Bäume und Steine liefern ihre Ernte direkt.
				_ressourcen.hinzufuegen(ressource, menge)
			Job_Basis.ZielTyp.TIER:
				# Jagen: erst mit jedem Schlag verletzen, ernten, wenn das Tier tot ist.
				_jagd_schlag(status, menge)

func _jagd_schlag(status: Einheit_Status, schaden: int) -> void:
	# Jeder Schlag verletzt das Tier; erst beim Tod fällt die Beute an.
	if _tiere == null or _ressourcen == null:
		return
	if _tiere.tier_angreifen(status.aktuelles_ziel_index, schaden):
		_tier_ernten(status)

func _tier_ernten(status: Einheit_Status) -> void:
	if _tiere == null or _ressourcen == null:
		return
	var fleisch := _tiere.tier_ernten(status.aktuelles_ziel_index)
	if fleisch > 0:
		_ressourcen.hinzufuegen("fleisch", fleisch)
	# Erlegte Beute ist verbraucht: der Job endet.
	status.job_abbrechen()
	for einheit: Dictionary in _einheiten:
		if einheit["status"] == status:
			(einheit["darsteller"] as Einheit_Darsteller).animation_setzen(status.animation())
