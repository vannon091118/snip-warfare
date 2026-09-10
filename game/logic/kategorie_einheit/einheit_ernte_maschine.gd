extends RefCounted
class_name Einheit_ErnteMaschine
## Ernte- und Beute-Maschine der Einheiten: Sie verarbeitet den fertigen
## Arbeitsschritt, setzt die Ernte-Position am Ziel und leitet Holz, Stein
## und Fleisch an die Ressourcen-Verwaltung weiter. Jagdschläge verletzen
## das Tier erst schlagweise; beim Tod fällt die Beute an. Sie kennt keine
## Zustandsübergänge und vergibt keine Jobs — der Manager orchestriert.

## Kategorie ausgang: Beute gefallen, der Darsteller der Einheit braucht
## einen Animation-Refresh; der Manager besitzt die Darsteller.
signal beute_erlegt(status: Einheit_Status)

## Kategorie daten: die Quellen der Ernte.
var _ressourcen: Einheit_Ressourcen = null
var _model: Welt_Model = null
var _tiere: Tier_Manager = null

## Kategorie logik: Einrichten und Ernte-Verarbeitung.

func einrichten(ressourcen: Einheit_Ressourcen, model: Welt_Model, tiere: Tier_Manager) -> void:
	_ressourcen = ressourcen
	_model = model
	_tiere = tiere

func arbeitsschritt_verarbeiten(ressource: String, menge: int, status: Einheit_Status) -> void:
	# Ein Arbeitsschritt ist fertig; je nach Ziel-Typ wird geerntet oder
	# das Tier geschlagen. Ohne Ressourcen-Verwaltung keine Auswirkung.
	if _ressourcen == null or status == null:
		return
	if status.zustand != Einheit_Status.Zustand.ARBEITEN or status.ziel_ressource != ressource:
		return
	match status.aktuelles_ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			_ressourcen.ernte_position_setzen(_objekt_position(status.aktuelles_ziel_index))
			# Bäume und Steine liefern ihre Ernte ins nächste lokale Lager.
			_ressourcen.hinzufuegen(ressource, menge)
		Job_Basis.ZielTyp.TIER:
			# Jagen: erst mit jedem Schlag verletzen, ernten, wenn das Tier tot ist.
			_jagd_schlag(status, menge)

func _objekt_position(index: int) -> Vector2:
	if _model == null or index < 0 or index >= _model.objekt_anzahl():
		return Vector2.ZERO
	return _model.objekt_position(index)

func _jagd_schlag(status: Einheit_Status, schaden: int) -> void:
	# Jeder Schlag verletzt das Tier; erst beim Tod fällt die Beute an.
	if _tiere == null:
		return
	if _tiere.tier_angreifen(status.aktuelles_ziel_index, schaden):
		_tier_ernten(status)

func _tier_ernten(status: Einheit_Status) -> void:
	if _tiere == null or _ressourcen == null:
		return
	# Die Kadaver-Position wird vor der Entfernung gelesen: Nach tier_ernten
	# existiert das Tier nicht mehr und die Position waere ungueltig.
	var kadaver_position := _tiere.tier_position(status.aktuelles_ziel_index)
	var fleisch := _tiere.tier_ernten(status.aktuelles_ziel_index)
	if fleisch > 0:
		_ressourcen.ernte_position_setzen(kadaver_position)
		_ressourcen.hinzufuegen("fleisch", fleisch)
	# Erlegte Beute ist verbraucht: der Job endet, die Darstellung folgt.
	status.job_abbrechen()
	beute_erlegt.emit(status)
