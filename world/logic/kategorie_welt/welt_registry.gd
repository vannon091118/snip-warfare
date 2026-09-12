extends Objekt_RegistryBasis
class_name Welt_Registry
## Fassade ueber Terrain, Natur, Gebaeude. Laedt den Katalog einmalig und reicht Instanzen weiter.
var _terrain: Objekt_Registry = null
var _natur: Natur_Registry = null
var _gebaeude: Gebaeude_Registry = null

func _init(quelle_pfad: String = KATALOG_PFAD) -> void:
	super(quelle_pfad)

func registries_vorbereiten() -> void:
	_terrain = Objekt_Registry.new()
	_natur = Natur_Registry.new()
	_gebaeude = Gebaeude_Registry.new()
	_registries_nach_kategorie["Terrain"] = _terrain
	_registries_nach_kategorie["Natur"] = _natur
	_registries_nach_kategorie["Gebäude"] = _gebaeude

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	super._registrieren_in_kategorie(kategorie, element_id, objekt)

func _zentrale_klasse_fuer(element_id: String) -> Objekt_Basis:
	match element_id:
		"baum":
			return Objekt_Baum.new()
		"baum_stumpf":
			return Objekt_Baumstumpf.new()
		"stein":
			return Objekt_Stein.new()
		"steine_gruppe":
			return Objekt_Steingruppe.new()
		"berg":
			return Objekt_Berg.new()
		"felswand":
			return Objekt_Felswand.new()
		"erzader":
			return Objekt_Erzader.new()
		"ruine":
			return Objekt_Ruine.new()
		"steinkreis":
			return Objekt_Steinkreis.new()
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
