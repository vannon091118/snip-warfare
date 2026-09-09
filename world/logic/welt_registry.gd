extends Objekt_RegistryBasis
class_name Welt_Registry
## Fassade über die Fach-Registries Terrain, Natur und Gebäude.
## RT-Pyramide: Spitze fasst alle Untersysteme zusammen ohne deren
## Logik zu verdoppeln. Fachregistries sind nur gefilterte Sichten.
## Sie behält alle Katalog-Einträge zentral und delegiert nur die Sicht
## nach Kategorie; Aufrufer erhalten immer dieselben Objekt-Instanzen.
## Zentrale Erzeugung der Datenklassen in _objekt_klasse_fuer.

## Kategorie daten: getypte Fach-Sicht Caches fuer die Fassade.
var _natur_sicht: Array[Objekt_Basis] = []
var _gebaeude_sicht: Array[Objekt_Basis] = []
var _terrain_sicht: Array[Objekt_Basis] = []

## Kategorie logik: Aufbau und delegierende Zugriffe. Fach-Sichten sind
## keine eigenen Registry Instanzen, sondern nur getypte Filter über
## die zentrale Katalog Tabelle. Kein eigener Ladezyklus.

func registries_vorbereiten() -> void:
	# Fach-Sichten werden erst nach dem Laden gefüllt, hier nur leeren.
	_natur_sicht.clear()
	_gebaeude_sicht.clear()
	_terrain_sicht.clear()

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	var basis_registry: Welt_RegistryBasis = _registries_nach_kategorie.get(kategorie)
	if basis_registry != null:
		basis_registry.registrieren(element_id, objekt)
	match kategorie:
		"Terrain":
			_terrain_sicht.append(objekt)
		"Natur":
			_natur_sicht.append(objekt)
		"Gebäude":
			_gebaeude_sicht.append(objekt)

func _objekt_klasse_fuer(element_id: String) -> Objekt_Basis:
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
		"boden", "wiese":
			return Objekt_Kachel.new()
	return Objekt_Basis.new()

func natur_sicht() -> Array[Objekt_Basis]:
	return _natur_sicht

func gebaeude_sicht() -> Array[Objekt_Basis]:
	return _gebaeude_sicht

func terrain_sicht() -> Array[Objekt_Basis]:
	return _terrain_sicht

func natur() -> Welt_RegistryBasis:
	return _registries_nach_kategorie.get("Natur", null)

func gebaeude() -> Welt_RegistryBasis:
	return _registries_nach_kategorie.get("Gebäude", null)

func terrain() -> Welt_RegistryBasis:
	return _registries_nach_kategorie.get("Terrain", null)

func registry_nach_schema_name(schema_id: String) -> Welt_RegistryBasis:
	match schema_id:
		"Objekt_Registry", "Natur_Registry", "Gebaeude_Registry":
			return self
	return null

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachregistries"] = "Objekt_Registry, Natur_Registry, Gebaeude_Registry"
	return arten
