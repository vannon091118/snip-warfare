extends RefCounted
class_name Einheit_ZielSuche
## Suche der Ziel-Wahrheit für Einheiten: Sie übersetzt Ziel-Typ und Index
## in Weltpositionen, prüft, ob ein Ziel noch existiert, und findet das
## nächste gültige Ziel desselben Typs. Sie besitzt nichts und tickt nichts;
## das Welt_Model und der Tier_Manager bleiben die einzigen Quellen.

## Kategorie daten: die zwei Zustandsquellen der Ziele.
var _model: Welt_Model = null
var _tiere: Tier_Manager = null

## Kategorie logik: Einrichten, Übersetzen, Prüfen, Suchen.

func einrichten(model: Welt_Model, tiere: Tier_Manager) -> void:
	_model = model
	_tiere = tiere

func ziel_position_fuer(ziel_typ: Job_Basis.ZielTyp, ziel_index: int) -> Vector2:
	# Zielposition für die Bewegung: Objekte liegen im Modell, Tiere im
	# Tier-Manager. Ohne Treffer bleibt der Nullpunkt.
	match ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model != null and ziel_index >= 0 and ziel_index < _model.objekt_anzahl():
				return _model.objekt_position(ziel_index)
		Job_Basis.ZielTyp.TIER:
			if _tiere != null:
				var tier_pos := _tiere.tier_position(ziel_index)
				if tier_pos != Vector2.INF:
					return tier_pos
	return Vector2.ZERO

## G1-Lesepfad: Der effektive Faktor des Ziels. Objekte über das Modell und
## die Welt-Registry, Tiere über den öffentlichen Leser des Tier-Managers;
## ohne Treffer neutral 1.0.
func ziel_faktor_fuer(ziel_typ: Job_Basis.ZielTyp, ziel_index: int) -> float:
	match ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model != null and ziel_index >= 0 and ziel_index < _model.objekt_anzahl():
				var eintrag: Objekt_Basis = Welt_Registry.new().finde_objekt(_model.objekt_element_id(ziel_index))
				return 1.0 if eintrag == null else eintrag.effektiver_faktor()
		Job_Basis.ZielTyp.TIER:
			if _tiere != null:
				return _tiere.tier_effektiver_faktor(ziel_index)
	return 1.0

func ziel_existiert(status: Einheit_Status) -> bool:
	if status.job == null:
		return false
	match status.aktuelles_ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			if _model == null:
				return false
			return status.aktuelles_ziel_index < _model.objekt_anzahl()
		Job_Basis.ZielTyp.TIER:
			if _tiere == null:
				return false
			return _tiere.tier_position(status.aktuelles_ziel_index) != Vector2.INF
	return false

func naechstes_objekt(status: Einheit_Status, alter_ziel_index: int) -> int:
	if _model == null or status.job == null:
		return -1
	var anzahl := _model.objekt_anzahl()
	if anzahl == 0:
		return -1
	for schritt in anzahl:
		var pruef_index := (alter_ziel_index + 1 + schritt) % anzahl
		if pruef_index == alter_ziel_index:
			continue
		var element_id := _model.objekt_element_id(pruef_index)
		if status.job.passt_zu_objekt(element_id):
			return pruef_index
	return -1

func naechstes_tier(status: Einheit_Status, alter_ziel_index: int) -> int:
	if _tiere == null or status.job == null:
		return -1
	var anzahl := _tiere.tier_zahl()
	if anzahl == 0:
		return -1
	for schritt in anzahl:
		var pruef_index := (alter_ziel_index + 1 + schritt) % anzahl
		if pruef_index == alter_ziel_index:
			continue
		if _tiere.tier_position(pruef_index) == Vector2.INF:
			continue
		var tier_art := _tiere.tier_art(pruef_index)
		if status.job.passt_zu_tier(tier_art):
			return pruef_index
	return -1
