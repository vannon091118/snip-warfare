extends RefCounted
class_name Ui_JobVergabeMaschine
## Job-Vergabe-Maschine der Eingabe-Domäne: Wählt passend zum Ziel den ersten
## passenden Job aus der Registry, vergibt ihn an die aktive Einheit, priorisiert
## Baustellen und schickt Marschbefehle. Kein Klick-Übersetzen: Nur die
## Vergabe-Rechnung wohnt hier.

## Kategorie daten: Ziel-Referenzen der beteiligten Domänen.
var _steuerung: Kern_SteuerungRegistry = null
var _model: Welt_Model = null
var _job_registry: Job_Registry = null
var _stockmaenner: Einheit_Manager = null
var _tiere: Tier_Manager = null
var _auswahl: Ui_AuswahlManager = null
var _hud: VBoxContainer = null

## Kategorie logik: Passenden Job finden und vergeben.

func einrichten(p: Dictionary) -> void:
	_steuerung = p.get("steuerung")
	_model = p.get("model")
	_job_registry = p.get("job_registry")
	_stockmaenner = p.get("stockmaenner")
	_tiere = p.get("tiere")
	_auswahl = p.get("auswahl")
	_hud = p.get("hud")

func modell_wechseln(neues_modell: Welt_Model) -> void:
	_model = neues_modell

func auswahl_radius() -> float:
	return _steuerung.steuerung.auswahl_radius if _steuerung != null and _steuerung.steuerung != null else 60.0

func job_fuer_tier_vergeben(tier_nummer: int, ziel_position: Vector2) -> void:
	if _tiere == null or _job_registry == null or _stockmaenner == null or _auswahl == null:
		return
	var tier_art := _tiere.tier_art(tier_nummer)
	if tier_art == "":
		return
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_tier(tier_art):
			continue
		# Direkte Auswirkung: Die Einheit läuft zum Ziel; zu weit entfernte
		# Ziele werden nicht mehr abgelehnt, sondern erst angelaufen.
		if _stockmaenner.job_vergeben(_auswahl.aktiver_einheit_index, job_id, Job_Basis.ZielTyp.TIER, tier_nummer, ziel_position):
			if _hud != null:
				(_hud as Variant).job_anzeigen(_job_registry.job_name(job_id))
			return

func job_fuer_objekt_vergeben(objekt_index: int, ziel_position: Vector2, element_id: String) -> void:
	if _job_registry == null or _stockmaenner == null or _auswahl == null:
		return
	for job_id: String in _job_registry.job_ids():
		var probe := _job_registry.job_erzeugen(job_id)
		if probe == null or not probe.passt_zu_objekt(element_id):
			continue
		# Direkte Auswirkung: Die Einheit läuft zum Zielobjekt und beginnt
		# dort mit der Arbeit; der Sammelradius bleibt die Job-Reichweite.
		if _stockmaenner.job_vergeben(_auswahl.aktiver_einheit_index, job_id, Job_Basis.ZielTyp.OBJEKT, objekt_index, ziel_position):
			if _hud != null:
				(_hud as Variant).job_anzeigen(_job_registry.job_name(job_id))
			return

func baustelle_priorisieren(objekt_index: int, pos: Vector2) -> void:
	if _stockmaenner == null or _auswahl == null or _hud == null:
		return
	var aktiv := _auswahl.aktiver_einheit_index
	if aktiv < 0 or aktiv >= _stockmaenner.einheit_zahl():
		(_hud as Variant).meldung_setzen("Zuerst eine Einheit auswaehlen.")
		return
	_stockmaenner.einheit_job_abbrechen(aktiv)
	_stockmaenner.job_vergeben(aktiv, "baustelle_beliefern", Job_Basis.ZielTyp.OBJEKT, objekt_index, pos)
	(_hud as Variant).meldung_setzen("Baustelle priorisiert: Belieferung vorgezogen.")

func marschieren_nach(welt_pos: Vector2) -> void:
	if _stockmaenner == null or _auswahl == null or _hud == null:
		return
	if _auswahl.aktiver_einheit_index < 0 or _auswahl.aktiver_einheit_index >= _stockmaenner.einheit_zahl():
		(_hud as Variant).meldung_setzen("Marschieren braucht eine gewaehlte Einheit.")
		return
	var einheiten_liste: Array[int] = _auswahl.auswahl_einheiten if not _auswahl.auswahl_einheiten.is_empty() else [_auswahl.aktiver_einheit_index]
	for einheit_index in einheiten_liste:
		_stockmaenner.einheit_bewegen_nach(einheit_index, welt_pos)
	(_hud as Variant).meldung_setzen("Marschieren nach (%.0f, %.0f)" % [welt_pos.x, welt_pos.y])

func ressource_aktion_ausfuehren(rechtsklick_welt_position: Vector2) -> void:
	# Sammeln/Abbauen aus dem Kontextmenü. Das Menü öffnet sich ohne aktive
	# Einheit; daher prüfen wir explizit und geben eine sprechende Meldung,
	# wenn noch keine Einheit gewählt ist.
	if _stockmaenner == null or _auswahl == null or _hud == null:
		return
	var idx := _auswahl.aktiver_einheit_index
	if idx < 0 or idx >= _stockmaenner.einheit_zahl():
		(_hud as Variant).meldung_setzen("Zuerst eine Einheit auswaehlen, dann Sammeln oder Abbauen waehlen.")
		return
	var radius := auswahl_radius()
	var objekt_index := _model.objekt_bei(rechtsklick_welt_position, radius) if _model != null else -1
	if objekt_index < 0:
		(_hud as Variant).meldung_setzen("Kein Zielobjekt in Reichweite.")
		return
	var element_id := _model.objekt_element_id(objekt_index)
	var element_pos := _model.objekt_position(objekt_index)
	job_fuer_objekt_vergeben(objekt_index, element_pos, element_id)
