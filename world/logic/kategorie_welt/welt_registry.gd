extends Objekt_RegistryBasis
class_name Welt_Registry
## Fassade über die Fach-Registries Terrain, Natur und Gebäude.
## RT-Pyramide: Spitze fasst alle Untersysteme zusammen ohne deren
## Logik zu verdoppeln. Fachregistries sind gefilterte Sichten über
## denselben Katalog: Welt_Registry lädt den Element-Katalog einmalig
## als eigene Instanz und reicht dieselben Objekt-Instanzen an die drei
## Fach-Registries weiter; Aufrufer erhalten immer dieselben Objekte.
## Zentrale Erzeugung der Datenklassen in _objekt_klasse_fuer.

## Kategorie daten: die drei Fach-Registries als gefilterte Sichten.
var _terrain: Objekt_Registry = null
var _natur: Natur_Registry = null
var _gebaeude: Gebaeude_Registry = null

## Kategorie logik: Aufbau und delegierende Zugriffe. Die Fach-Registries
## werden ohne eigenen Katalog-Lauf aus derselben Katalog-Tabelle befüllt;
## es gibt keine zweite JSON-Ladung und keine zweite Klassen-Erzeugung.

func _init(quelle_pfad: String = KATALOG_PFAD) -> void:
	# Die Fassade ist die einzige Ladestelle des Element-Katalogs: Sie
	# übergibt den Pfad explizit an die Basis und verteilt die Instanzen
	# über _registrieren_in_kategorie an ihre Fach-Sichten.
	super(quelle_pfad)

func registries_vorbereiten() -> void:
	# Fach-Registries sind gefilterte Sichten: Sie laden den Katalog nicht
	# selbst (Default-Pfad leer), sondern werden ausschließlich hier befüllt.
	# Ein Aufruf, eine Ladung, keine doppelten IDs mehr.
	_terrain = Objekt_Registry.new()
	_natur = Natur_Registry.new()
	_gebaeude = Gebaeude_Registry.new()
	_registries_nach_kategorie["Terrain"] = _terrain
	_registries_nach_kategorie["Natur"] = _natur
	_registries_nach_kategorie["Gebäude"] = _gebaeude

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	super._registrieren_in_kategorie(kategorie, element_id, objekt)

func _zentrale_klasse_fuer(element_id: String) -> Objekt_Basis:
	# Übergangs-Fallback für Katalog-Einträge ohne script-Feld: Dieselbe
	# Zuordnung wie zuvor in _objekt_klasse_fuer. Die Plugin-Naht liegt in
	# Objekt_RegistryBasis und fragt zuerst das script-Feld des Eintrags.
	match element_id:
		"baum":
			return Objekt_Baum.new()
		"baum_stumpf":
			return Objekt_Baumstumpf.new()
		"stein":
			return Objekt_Stein.new()
		"steine_gruppe":
			return Objekt_Steingruppe.new()
		"haus":
			return Objekt_Haus.new()
		"haus_gross":
			return Objekt_Hausgross.new()
		"kadaver":
			return Objekt_Kadaver.new()
		"lagerfeuer":
			return Objekt_Lagerfeuer.new()
		"boden", "wiese":
			return Objekt_Kachel.new()
	return Objekt_Basis.new()

func ziel_tags_fuer(element_id: String) -> Array[String]:
	# Lesende Auskunft für das Kontextmenü: Welche Ziel-Tags trägt dieses
	# Element? Unbekannte Elemente haben keine Tags, das Menü zeigt dort nur
	# die globalen Aktionen. Keine zweite Tag-Tabelle im UI.
	var objekt := finde_objekt(element_id)
	if objekt == null:
		return []
	return objekt.ziel_tags

func natur_sicht() -> Array[Objekt_Basis]:
	return objekte_der_kategorie("Natur")

func gebaeude_sicht() -> Array[Objekt_Basis]:
	return objekte_der_kategorie("Gebäude")

func terrain_sicht() -> Array[Objekt_Basis]:
	return objekte_der_kategorie("Terrain")

func natur() -> Welt_RegistryBasis:
	return _natur

func gebaeude() -> Welt_RegistryBasis:
	return _gebaeude

func terrain() -> Welt_RegistryBasis:
	return _terrain

func registry_nach_schema_name(schema_id: String) -> Welt_RegistryBasis:
	match schema_id:
		"Objekt_Registry":
			return _terrain
		"Natur_Registry":
			return _natur
		"Gebaeude_Registry":
			return _gebaeude
	return null

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachregistries"] = "Objekt_Registry, Natur_Registry, Gebaeude_Registry"
	return arten
