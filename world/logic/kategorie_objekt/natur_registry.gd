extends Objekt_RegistryBasis
class_name Natur_Registry
## Registry der Natur-Objekte (Kategorie "Natur"): Baum, Baumstumpf, Stein
## und Steingruppe. Der Preflight zieht seine Referenzen für die Natur-Objekte
## aus dieser Registry; es existiert keine zweite Quelle für Natur-Definitionen.

func schema_name() -> String:
	return "Natur_Registry"

func registries_vorbereiten() -> void:
	_registries_nach_kategorie["Natur"] = self

func baum(id: String) -> Objekt_Baum:
	var objekt := finde_objekt(id)
	if objekt is Objekt_Baum:
		return objekt as Objekt_Baum
	return null

func erntbare_natur() -> Array[Objekt_Basis]:
	# Natur-Objekte, an denen ein Job arbeiten kann (arbeits_ressource gesetzt).
	var erntbare: Array[Objekt_Basis] = []
	for objekt: Objekt_Basis in eintraege:
		if objekt.arbeits_ressource != "":
			erntbare.append(objekt)
	return erntbare

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachkategorie"] = "Natur"
	return arten
