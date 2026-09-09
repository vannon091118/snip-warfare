extends RefCounted
class_name Objekt_RegistryBasis
## Gemeinsame Basis aller Katalog-Registries der Kategorie Objekt.
## Sie lädt den Element-Katalog, behält alle Einträge und verteilt sie in
## einem zweiten Durchgang an die Registries der Fachkategorien:
## Objekt_Registry (Terrain), Natur_Registry (Natur), Gebaeude_Registry
## (Gebäude). State Machines und Renderer lesen ihre Werte ausschließlich
## aus diesen Instanzen; nichts wird hart codiert.

## Kategorie daten: der komplette Katalog und die Fach-Registries.
var eintraege: Array[Objekt_Basis] = []
var _registries_nach_kategorie: Dictionary = {}

## Kategorie logik: Laden, Verteilen und Zuordnung der exakten Klassen.

const KATALOG_PFAD := "res://world/data/element_katalog.json"

func _init() -> void:
	laden()

func laden() -> bool:
	eintraege.clear()
	_registries_nach_kategorie.clear()
	registries_vorbereiten()
	if not FileAccess.file_exists(KATALOG_PFAD):
		push_warning("Element-Katalog nicht gefunden: %s" % KATALOG_PFAD)
		return false
	var datei := FileAccess.open(KATALOG_PFAD, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_ARRAY:
		push_warning("Element-Katalog hat ein ungültiges Format: %s" % KATALOG_PFAD)
		return false
	var warnungen := Kern_AssetPruefer.validiere_katalog_eintraege(gelesen as Array)
	for warnung: Dictionary in warnungen:
		push_warning("Katalog-Eintrag '%s': kein gültiges Asset; Platzhalter wird verwendet" % str(warnung.get("id", "?")))
	for eintrag: Variant in gelesen:
		if typeof(eintrag) != TYPE_DICTIONARY or not (eintrag as Dictionary).has("id"):
			continue
		var wort := eintrag as Dictionary
		var element_id := str(wort["id"])
		var kategorie := str(wort.get("kategorie", ""))
		if not Kern_AssetPruefer.eintrag_hat_asset(wort):
			var platzhalter := Kern_AssetPruefer.sichere_textur_pfad(wort, element_id)
			wort["textur_pfad"] = platzhalter
		var objekt := _objekt_klasse_fuer(element_id)
		objekt.aus_katalog_eintrag(wort)
		eintraege.append(objekt)
		_registrieren_in_kategorie(kategorie, element_id, objekt)
	return true

func registries_vorbereiten() -> void:
	# Unterklassen legen hier ihre Fach-Registries an.
	pass

func _objekt_klasse_fuer(_element_id: String) -> Objekt_Basis:
	# Unterklassen ordnen hier jede Objektart ihrer eigenen Datenklasse zu.
	return Objekt_Basis.new()

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	var registry: Welt_RegistryBasis = _registries_nach_kategorie.get(kategorie)
	if registry == null:
		return
	registry.registrieren(element_id, objekt)

func registry_nach_kategorie(kategorie: String) -> Welt_RegistryBasis:
	var registry: Welt_RegistryBasis = _registries_nach_kategorie.get(kategorie)
	return registry

func registries_namen() -> Array[String]:
	var namen: Array[String] = []
	for kategorie: String in _registries_nach_kategorie.keys():
		namen.append(kategorie)
	namen.sort()
	return namen

func finde_objekt(id: String) -> Objekt_Basis:
	for objekt: Objekt_Basis in eintraege:
		if objekt.id == id:
			return objekt
	return null

func hat_objekt(id: String) -> bool:
	return finde_objekt(id) != null

func kategorien() -> Array[String]:
	var gefundene: Array[String] = []
	for objekt: Objekt_Basis in eintraege:
		var kategorie := str(objekt.kategorie)
		if not gefundene.has(kategorie):
			gefundene.append(kategorie)
	gefundene.sort()
	return gefundene

func objekte_der_kategorie(kategorie: String) -> Array[Objekt_Basis]:
	var gefundene: Array[Objekt_Basis] = []
	for objekt: Objekt_Basis in eintraege:
		if str(objekt.kategorie) == kategorie:
			gefundene.append(objekt)
	return gefundene

func datenfeld_arten() -> Dictionary:
	return {"eintraege": "Array[Objekt_Basis]"}
