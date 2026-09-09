extends Objekt_RegistryBasis
class_name Gebaeude_Registry
## Registry der Gebäude (Kategorie "Gebäude"): Haus und Großes Haus.
## Der Preflight zieht seine Referenzen für die Gebäude aus dieser Registry;
## es existiert keine zweite Quelle für Gebäude-Definitionen.

func schema_name() -> String:
	return "Gebaeude_Registry"

func registries_vorbereiten() -> void:
	_registries_nach_kategorie["Gebäude"] = self

func gebaeude(id: String) -> Objekt_Basis:
	var objekt := finde_objekt(id)
	if objekt == null:
		return null
	if str(objekt.kategorie) == "Gebäude":
		return objekt
	return null

func gebaeude_ids() -> Array[String]:
	var ids: Array[String] = []
	for objekt: Objekt_Basis in eintraege:
		if str(objekt.kategorie) == "Gebäude":
			ids.append(objekt.id)
	ids.sort()
	return ids

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachkategorie"] = "Gebäude"
	return arten
