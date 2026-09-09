extends Objekt_RegistryBasis
class_name Objekt_Registry
## Registry der Terrain-Kacheln (Kategorie "Terrain"): Boden und Wiese.
## Der Preflight zieht seine Referenzen für die Terrainkacheln aus dieser
## Registry; es existiert keine zweite Quelle für Kachel-Definitionen.

func schema_name() -> String:
	return "Objekt_Registry"

func registries_vorbereiten() -> void:
	_registries_nach_kategorie["Terrain"] = self

func kachel(id: String) -> Objekt_Kachel:
	var objekt := finde_objekt(id)
	if objekt is Objekt_Kachel:
		return objekt as Objekt_Kachel
	return null

func kachel_ids() -> Array[String]:
	var ids: Array[String] = []
	for objekt: Objekt_Basis in eintraege:
		if objekt is Objekt_Kachel:
			ids.append(objekt.id)
	ids.sort()
	return ids

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachkategorie"] = "Terrain"
	return arten
