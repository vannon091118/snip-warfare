extends Objekt_RegistryBasis
class_name Welt_Registry
## Fassade ueber Terrain, Natur, Gebaeude. Laedt den Katalog einmalig und reicht Instanzen weiter.
var _terrain: Objekt_Registry = null
var _natur: Natur_Registry = null
var _gebaeude: Gebaeude_Registry = null
var _moebel: Objekt_MoebelRegistry = null

func _init(quelle_pfad: String = KATALOG_PFAD) -> void:
	super(quelle_pfad)

func registries_vorbereiten() -> void:
	_terrain = Objekt_Registry.new()
	_natur = Natur_Registry.new()
	_gebaeude = Gebaeude_Registry.new()
	_moebel = Objekt_MoebelRegistry.new()
	_registries_nach_kategorie["Terrain"] = _terrain
	_registries_nach_kategorie["Natur"] = _natur
	_registries_nach_kategorie["Gebäude"] = _gebaeude
	_registries_nach_kategorie["Möbel"] = _moebel

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	super._registrieren_in_kategorie(kategorie, element_id, objekt)

func _zentrale_klasse_fuer(element_id: String) -> Objekt_Basis:
	## Die Zuordnung wohnt in der eigenen Tabelle; unbekannte IDs fallen
	## auf die Basis zurück, sofern ihr Katalog-Eintrag kein script trägt.
	var klassen_name := Welt_RegistryKlassenZuordnung.klasse_name_fuer(element_id)
	if klassen_name != "":
		var datei_name := _klasse_datei_name(klassen_name)
		var pfad := "res://world/logic/kategorie_objekt/%s.gd" % datei_name
		if ResourceLoader.exists(pfad):
			var geladen: Variant = load(pfad)
			if geladen != null:
				var instanz: Variant = (geladen as GDScript).new()
				if instanz is Objekt_Basis:
					return instanz as Objekt_Basis
			push_warning("Klassen-Zuordnung '%s' liess sich nicht laden (%s)" % [klassen_name, pfad])
		else:
			push_warning("Klassen-Zuordnung '%s' kennt keine Datei (%s)" % [klassen_name, pfad])
	return Objekt_Basis.new()

func _klasse_datei_name(klassen_name: String) -> String:
	## Objekt_KlassenWerkstatt -> objekt_klassenwerkstatt: Die Dateinamen
	## dieser Domäne verbinden die Wörter ohne Unterstrich.
	var teile := klassen_name.split("_")
	teile.remove_at(0)
	return "".join(teile).to_lower()

func ziel_tags_fuer(element_id: String) -> Array[String]:
	var objekt := finde_objekt(element_id)
	if objekt == null:
		return []
	return objekt.ziel_tags

func moebel_sicht() -> Array[Objekt_Basis]:
	return objekte_der_kategorie("Möbel")

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

func moebel() -> Objekt_MoebelRegistry:
	return _moebel

func registry_nach_schema_name(schema_id: String) -> Welt_RegistryBasis:
	match schema_id:
		"Objekt_Registry":
			return _terrain
		"Natur_Registry":
			return _natur
		"Gebaeude_Registry":
			return _gebaeude
		"Objekt_MoebelRegistry":
			return _moebel
	return null

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachregistries"] = "Objekt_Registry, Natur_Registry, Gebaeude_Registry, Objekt_MoebelRegistry"
	return arten
