extends Objekt_RegistryBasis
class_name Objekt_MoebelRegistry
## Registry der Möbel (Kategorie "Möbel"): Tische, Stühle, Betten, Schränke.
## Der Preflight zieht seine Referenzen für Möbel aus dieser Registry;
## es existiert keine zweite Quelle für Möbel-Definitionen.

func schema_name() -> String:
	return "Objekt_MoebelRegistry"

func registries_vorbereiten() -> void:
	_registries_nach_kategorie["Möbel"] = self

func moebel(id: String) -> Objekt_Basis:
	var objekt := finde_objekt(id)
	if objekt == null:
		return null
	if str(objekt.kategorie) == "Möbel":
		return objekt
	return null

func moebel_ids() -> Array[String]:
	var ids: Array[String] = []
	for objekt: Objekt_Basis in eintraege:
		if str(objekt.kategorie) == "Möbel":
			ids.append(objekt.id)
	ids.sort()
	return ids

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachkategorie"] = "Möbel"
	return arten