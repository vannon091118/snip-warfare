extends RefCounted
class_name Welt_FortschrittsMaschine
## Onboarding-Maschine der Siedlung: Sie liest genau eine aktive Stufe aus der
## Welt_FortschrittsRegistry, beantwortet Auftrags-Ereignisse (Gebäude fertig,
## Einwanderer angekommen, Ressource eingelagert, Raum entstanden, Lagerzone
## registriert) und fortschaltet. Gating über stufe_frei; Bus-Brücke, Spawn
## und Persistenz wohnen in eigenen Klassen dieser Domäne.

signal stufe_erreicht(stufe: Dictionary)
signal ziel_erreicht(stufe: Dictionary)
## Vertrags-Signal: Die Verdrahtung emittiert es beim Vorarbeiter-Spawn
## (bewusst von außen gesetzt, hier nur deklariert).
signal orchestrator_gespawnt(position: Vector2)

## Kategorie daten: Stufen-Zeiger, Abschluss-Buch und Modell-Felder.

var stufe_index: int = 0
var abgeschlossen: Dictionary = {}
var _model: Welt_Model = null
var _registry: Welt_FortschrittsRegistry = null
var _persistenz := Welt_FortschrittPersistenz.new()

## Kategorie logik: Stufen lesen, Aufträge deuten, fortschalten, freigeben.

func registry_setzen(registry: Welt_FortschrittsRegistry) -> void:
	_registry = registry

func model_setzen(model: Welt_Model) -> void:
	_model = model
	_persistenz.laden(model)
	stufe_index = _persistenz.stufe_index
	abgeschlossen = _persistenz.abgeschlossen

func aktive_stufe() -> Dictionary:
	if _registry == null:
		return {}
	return _registry.stufe_an(stufe_index)

func ziel_zeile() -> String:
	if aktive_stufe().is_empty():
		return "Alle Ziele erreicht."
	return "Ziel: %s" % str(aktive_stufe().get("beschreibung", ""))

func gebaeude_fertiggestellt(gebaeude_id: String) -> void:
	var stufe := _stufe_fuer("gebaeude_bauen")
	if stufe.is_empty() or str(stufe.get("gebaeude_id", "")) != gebaeude_id:
		return
	fortschalten()

func einwanderer_angekommen() -> void:
	if not _stufe_fuer("einwanderung").is_empty():
		fortschalten()

func ressource_eingelagert(ressource: String) -> void:
	var stufe := _stufe_fuer("ressource_einlagern")
	if stufe.is_empty() or ressource != str(stufe.get("ressource", "")):
		return
	fortschalten()

func raum_entstanden(_raum_id: String, innen_flaeche: int, hat_tuer: bool, geschlossen: bool) -> void:
	var stufe := _stufe_fuer("raum")
	if stufe.is_empty():
		return
	var braucht_tuer := bool(stufe.get("braucht_tuer", true))
	var mindest := int(stufe.get("innen_mindest_flaeche", 16))
	if innen_flaeche >= mindest and (not braucht_tuer or hat_tuer) and geschlossen:
		fortschalten()

func lagerzone_registriert() -> void:
	if not _stufe_fuer("lagerzone").is_empty():
		fortschalten()

func freigeschaltete_gebaeude() -> Array[String]:
	return _freigeschaltete("gebaeude")

func freigeschaltete_kategorien() -> Array[String]:
	return _freigeschaltete("kategorien")

func stufe_frei(gesperrt_ab_stufe: int) -> bool:
	return stufe_index >= gesperrt_ab_stufe

## Nur die aktive Stufe, wenn ihr Zieltyp zum Auftrag passt; sonst leer.
func _stufe_fuer(ziel_typ: String) -> Dictionary:
	var stufe := aktive_stufe()
	if stufe.is_empty() or str(stufe.get("ziel_typ", "")) != ziel_typ:
		return {}
	return stufe

func fortschalten() -> void:
	var stufe := aktive_stufe()
	if stufe.is_empty():
		return
	var stufe_id := str(stufe.get("id", ""))
	abgeschlossen[stufe_id] = true
	ziel_erreicht.emit(stufe)
	if stufe_id == "rathaus_bauen":
		# Rathaus fertig = Vorarbeiter-Spawn; die Aufstellung trägt die Verdrahtung.
		var verdrahtung := Welt_FortschrittVerdrahtung.aktive()
		if verdrahtung != null:
			verdrahtung.vorarbeiter_aufstellen()
	if stufe_index + 1 < _registry.stufen_zahl():
		stufe_index += 1
		stufe_erreicht.emit(aktive_stufe())
	_persistenz.speichern(_model, stufe_index, abgeschlossen)

func _freigeschaltete(schluessel: String) -> Array[String]:
	var frei: Array[String] = []
	if _registry == null:
		return frei
	for i in stufe_index + 1:
		for eintrag: Variant in (_registry.stufe_an(i).get("schaltet_frei", {}).get(schluessel, []) as Array):
			var k := str(eintrag)
			if not frei.has(k):
				frei.append(k)
	return frei
