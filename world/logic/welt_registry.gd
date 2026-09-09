extends Objekt_RegistryBasis
class_name Welt_Registry
## Fassade über die Fach-Registries Terrain, Natur und Gebäude.
## Sie behält alle Katalog-Einträge und delegiert nach Kategorie; Aufrufer
## erhalten immer dieselben Objekt-Instanzen, egal ob sie über die Fassade
## oder die Fach-Registry gehen. Zentrale Erzeugung der Datenklassen in
## _objekt_klasse_fuer; neue Objektarten werden nur hier registriert.

## Kategorie daten: die Fach-Registries dieser Fassade.
var _natur: Natur_Registry
var _gebaeude: Gebaeude_Registry
var _terrain: Objekt_Registry

## Kategorie logik: Aufbau und delegierende Zugriffe.

func registries_vorbereiten() -> void:
	_terrain = Objekt_Registry.new()
	_natur = Natur_Registry.new()
	_gebaeude = Gebaeude_Registry.new()
	_registries_nach_kategorie["Terrain"] = _terrain
	_registries_nach_kategorie["Natur"] = _natur
	_registries_nach_kategorie["Gebäude"] = _gebaeude

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
		"boden", "wiese":
			return Objekt_Kachel.new()
	return Objekt_Basis.new()

func natur() -> Natur_Registry:
	return _natur

func gebaeude() -> Gebaeude_Registry:
	return _gebaeude

func terrain() -> Objekt_Registry:
	return _terrain

func registry_nach_schema_name(schema_name: String) -> Welt_RegistryBasis:
	match schema_name:
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
