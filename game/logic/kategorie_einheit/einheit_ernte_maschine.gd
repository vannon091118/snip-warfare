extends RefCounted
class_name Einheit_ErnteMaschine
## Ernte- und Beute-Maschine der Einheiten: Sie verarbeitet den fertigen
## Arbeitsschritt, setzt die Ernte-Position am Ziel und bucht die Ernte
## in das physische Inventar der Einheit (Einheit_Inventar). Jagdschläge
## verletzen das Tier erst schlagweise; beim Tod fällt die Beute an.
## Sie kennt keine Zustandsübergänge und vergibt keine Jobs — der Manager orchestriert.
##
## Kategorie ausgang: Beute gefallen, der Darsteller der Einheit braucht
## einen Animation-Refresh; der Manager besitzt die Darsteller.
signal beute_erlegt(status: Einheit_Status)
## Darstellungs-Anschluss: Der Ort des Schlages wird gemeldet, damit die
## Atmosphaeren-Domaene dort Staub zeigt. Rein optisch, keine Spiellogik.
signal schlag_ort_gemeldet(welt_position: Vector2)
## Zustands-Anschluss: Der Objekt-Index jedes Objekt-Schlages wird gemeldet,
## damit die Progressions-Domäne den echten Bestand am Modell senkt.
signal schlag_objekt_gemeldet(ziel_index: int)
## Inventar-Voll: Wird ausgestoßen, wenn das Inventar der Einheit voll ist.
## Der Manager reagiert darauf mit einem Transport-Job.
signal inventar_voll(einheit_index: int)

## Kategorie daten: die Quellen der Ernte.
var _inventar: Einheit_Inventar = null
var _ressourcen: Einheit_Ressourcen = null
var _model: Welt_Model = null
var _tiere: Tier_Manager = null
var _zufall: Kern_Zufall = null
var _manager: Einheit_Manager = null
var _aktueller_einheit_index: int = -1
var _inventare: Dictionary = {}  # einheit_index -> Einheit_Inventar

## Kategorie logik: Einrichten und Ernte-Verarbeitung.

func einrichten(inventar: Einheit_Inventar, ressourcen: Einheit_Ressourcen, model: Welt_Model, tiere: Tier_Manager) -> void:
	_inventar = inventar
	_ressourcen = ressourcen
	_model = model
	_tiere = tiere

func inventar_fuer_einheit_setzen(einheit_index: int, inventar: Einheit_Inventar) -> void:
	_inventare[einheit_index] = inventar

func _inventar_fuer_einheit(einheit_index: int) -> Einheit_Inventar:
	return _inventare.get(einheit_index, _inventar)

func zufall_setzen(zufall: Kern_Zufall) -> void:
	# Der zentrale Zufallszustand bleibt die einzige Quelle; der Kannibalen-
	# schlag würfelt seine Folgen darüber wie jeder andere Schaden auch.
	_zufall = zufall

func manager_setzen(manager: Einheit_Manager) -> void:
	# Schwache Rückreferenz auf den besitzenden Manager: Nur über sie
	# adressiert der Kannibalen-Schlag das Opfer, ohne private Felder zu
	# berühren.
	_manager = manager

func arbeitsschritt_verarbeiten(ressource: String, menge: int, status: Einheit_Status, einheit_index: int = -1) -> void:
	# Ein Arbeitsschritt ist fertig; je nach Ziel-Typ wird geerntet oder
	# das Tier geschlagen. Ohne Inventar keine Auswirkung.
	if _ressourcen == null or status == null:
		return
	if status.zustand != Einheit_Status.Zustand.ARBEITEN or status.ziel_ressource != ressource:
		return
	_aktueller_einheit_index = einheit_index
	var inventar := _inventar_fuer_einheit(einheit_index)
	if inventar == null:
		return
	match status.aktuelles_ziel_typ:
		Job_Basis.ZielTyp.OBJEKT:
			_ressourcen.ernte_position_setzen(_objekt_position(status.aktuelles_ziel_index))
			schlag_ort_gemeldet.emit(_objekt_position(status.aktuelles_ziel_index))
			schlag_objekt_gemeldet.emit(status.aktuelles_ziel_index)
			# Bäume und Steine liefern ihre Ernte in das Inventar der Einheit.
			var ok := inventar.aufnahme(ressource, menge)
			if not ok and inventar.ist_voll():
				inventar_voll.emit(einheit_index)
		Job_Basis.ZielTyp.TIER:
			# Jagen: erst mit jedem Schlag verletzen, ernten, wenn das Tier tot ist.
			_jagd_schlag(status, menge)
		Job_Basis.ZielTyp.OWN:
			# Autonomer Kannibalismus: Dieselbe Schlagkette wie bei der Tier-
			# jagd, nur gegen einen Artgenossen-Knoten; der Schaden läuft über
			# den einzigen Vital-Pfad (Bus, Modifikatoren, Tod).
			_kannibale_schlag(status, menge)

func _objekt_position(index: int) -> Vector2:
	if _model == null or index < 0 or index >= _model.objekt_anzahl():
		return Vector2.ZERO
	return _model.objekt_position(index)

func _kannibale_schlag(status: Einheit_Status, schaden: int) -> void:
	if _zufall == null:
		_zufall = Kern_Zufall.new()
	var opfer := status.aktuelles_ziel_index
	if opfer < 0:
		return
	# Das Opfer wird über den Manager adressiert, bleibt aber ein normaler
	# Vital-Treffer: schaden_nehmen bucht Bus, Modifikatoren und Tod.
	var manager := _manager_des_opfers()
	if manager == null:
		return
	var vital := manager.einheit_vital(opfer)
	if vital == null or vital.hp <= 0:
		status.job_abbrechen()
		return
	vital.schaden_nehmen(schaden, _zufall, "kampf")
	if vital.hp <= 0:
		status.job_abbrechen()
		beute_erlegt.emit(status)
		# Die Tat wird sichtbar: Der Bus trägt den Tatort an alle Zeugen,
		# die Wahrnehmung und Lernen gehört dem Manager der Zeugen.
		var bus := Kern_SignalBus.bus()
		if bus != null:
			bus._emit_kannibalismus(manager.einheit_position(opfer))

func _manager_des_opfers() -> Einheit_Manager:
	return _manager

func _jagd_schlag(status: Einheit_Status, schaden: int) -> void:
	# Jeder Schlag verletzt das Tier; erst beim Tod fällt die Beute an.
	if _tiere == null:
		return
	if _tiere.tier_angreifen(status.aktuelles_ziel_index, schaden):
		_tier_ernten(status)

func _tier_ernten(status: Einheit_Status) -> void:
	if _tiere == null or _ressourcen == null:
		return
	var inventar := _inventar_fuer_einheit(_aktueller_einheit_index)
	if inventar == null:
		return
	# Die Kadaver-Position wird vor der Entfernung gelesen: Nach tier_ernten
	# existiert das Tier nicht mehr und die Position waere ungueltig.
	var kadaver_position := _tiere.tier_position(status.aktuelles_ziel_index)
	var fleisch := _tiere.tier_ernten(status.aktuelles_ziel_index)
	if fleisch > 0:
		_ressourcen.ernte_position_setzen(kadaver_position)
		schlag_ort_gemeldet.emit(kadaver_position)
		var ok := inventar.aufnahme("fleisch", fleisch)
		if not ok and inventar.ist_voll():
			inventar_voll.emit(_aktueller_einheit_index)
	# Erlegte Beute ist verbraucht: der Job endet, die Darstellung folgt.
	status.job_abbrechen()
	beute_erlegt.emit(status)
