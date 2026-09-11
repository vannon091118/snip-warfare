extends Welt_RegistryBasis
class_name Objekt_RegistryBasis
## Gemeinsame Basis aller Katalog-Registries der Kategorie Objekt.
## RT-Pyramide: Diese Basis ist eine echte Registry Erweiterung, kein
## Schattenläufer. Sie lädt den Element-Katalog einmalig, hält die
## exakten Datenklassen zentral und reicht gefilterte Sichten als
## Welt_RegistryBasis Instanzen weiter. Keine doppelte JSON Ladung.
## State Machines und Renderer lesen ausschließlich aus Instanzen.

## Kategorie daten: Fach-Registries als gefilterte Sicht über die zentrale Katalog Tabelle.
var _registries_nach_kategorie: Dictionary = {}
var _objekte_nach_kategorie_cache: Dictionary = {}

## Kategorie logik: Laden, Verteilen und Zuordnung der exakten Klassen.

const KATALOG_PFAD := "res://world/data/element_katalog.json"

func _init(quelle_pfad: String = "") -> void:
	# Eine Fach-Registry ist eine gefilterte Sicht und laedt den Katalog
	# nicht selbst: Nur die Fassade Welt_Registry übergibt den KATALOG_PFAD
	# und verteilt die Objekt-Instanzen über _registrieren_in_kategorie.
	# Ohne Pfad bleibt die Sicht leer und wird von der Fassade befüllt.
	super(quelle_pfad)

func schema_name() -> String:
	return "Objekt_RegistryBasis"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_ARRAY:
		push_warning("Element-Katalog hat ein ungültiges Format: %s" % _quelle_pfad)
		return false
	var warnungen := Kern_AssetPruefer.validiere_katalog_eintraege(gelesen as Array)
	for warnung: Dictionary in warnungen:
		push_warning("Katalog-Eintrag '%s': kein gültiges Asset; Platzhalter wird verwendet" % str(warnung.get("id", "?")))
	eintraege.clear()
	eintraege_nach_id.clear()
	_registries_nach_kategorie.clear()
	_objekte_nach_kategorie_cache.clear()
	registries_vorbereiten()
	for eintrag: Variant in gelesen:
		if typeof(eintrag) != TYPE_DICTIONARY or not (eintrag as Dictionary).has("id"):
			continue
		var wort := eintrag as Dictionary
		var element_id := str(wort["id"])
		var kategorie := str(wort.get("kategorie", ""))
		if not Kern_AssetPruefer.eintrag_hat_asset(wort):
			var platzhalter := Kern_AssetPruefer.sichere_textur_pfad(wort, element_id)
			wort["textur_pfad"] = platzhalter
		var objekt := _objekt_klasse_fuer(element_id, wort)
		objekt.aus_katalog_eintrag(wort)
		registrieren(element_id, objekt)
		_registrieren_in_kategorie(kategorie, element_id, objekt)
	return true

func registries_vorbereiten() -> void:
	# Unterklassen legen hier ihre Fach-Registries an.
	pass

func _objekt_klasse_fuer(element_id: String, eintrag: Dictionary = {}) -> Objekt_Basis:
	# Plugin-Naht: Das script-Feld des Katalog-Eintrags bestimmt die Datenklasse;
	# ein neues Objekt braucht künftig nur Katalog-Eintrag plus SVG, ohne dass
	# eine Registry-Klasse angefasst wird. ResourceLoader.exists verhindert
	# Halluzinationen bei Tippfehlern, die Typprüfung hält fremde Skripte raus.
	# Einträge ohne script-Feld (oder mit ungültigem) fallen auf die zentrale
	# Zuordnung der Unterklasse zurück (Übergangs-Fallback).
	var skript_pfad := str(eintrag.get("script", ""))
	if skript_pfad != "":
		if not ResourceLoader.exists(skript_pfad):
			push_warning("Objekt-Skript fehlt: %s (Eintrag %s)" % [skript_pfad, element_id])
			return _zentrale_klasse_fuer(element_id)
		var skript: GDScript = load(skript_pfad)
		if skript != null:
			var instanz: Variant = skript.new()
			if instanz is Objekt_Basis:
				return instanz as Objekt_Basis
			push_warning("Objekt-Skript ist kein Objekt_Basis: %s" % skript_pfad)
	return _zentrale_klasse_fuer(element_id)

func _zentrale_klasse_fuer(_element_id: String) -> Objekt_Basis:
	# Übergangs-Fallback für Katalog-Einträge ohne script-Feld.
	return Objekt_Basis.new()

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	var registry: Welt_RegistryBasis = _registries_nach_kategorie.get(kategorie)
	if registry == null:
		return
	registry.registrieren(element_id, objekt)
	if not _objekte_nach_kategorie_cache.has(kategorie):
		_objekte_nach_kategorie_cache[kategorie] = []
	(_objekte_nach_kategorie_cache[kategorie] as Array).append(objekt)

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
	var treffer := finde_eintrag(id)
	return treffer as Objekt_Basis if treffer != null else null

func hat_objekt(id: String) -> bool:
	return hat_eintrag(id)

func kategorien() -> Array[String]:
	var gefundene: Array[String] = []
	for objekt_ref: RefCounted in eintraege:
		var objekt := objekt_ref as Objekt_Basis
		if objekt == null:
			continue
		var kategorie := str(objekt.kategorie)
		if not gefundene.has(kategorie):
			gefundene.append(kategorie)
	gefundene.sort()
	return gefundene

func objekte_der_kategorie(kategorie: String) -> Array[Objekt_Basis]:
	if _objekte_nach_kategorie_cache.has(kategorie):
		var cache: Array = _objekte_nach_kategorie_cache[kategorie]
		var typisiert: Array[Objekt_Basis] = []
		for eintrag in cache:
			typisiert.append(eintrag as Objekt_Basis)
		return typisiert
	var gefundene: Array[Objekt_Basis] = []
	for objekt_ref: RefCounted in eintraege:
		var objekt := objekt_ref as Objekt_Basis
		if objekt != null and str(objekt.kategorie) == kategorie:
			gefundene.append(objekt)
	return gefundene

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["eintraege"] = "Array[Objekt_Basis]"
	return arten
