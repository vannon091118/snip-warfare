extends RefCounted
class_name Ui_BaufensterFilter
## Pure Datenreduktion für das Baufenster: Aus einer sortierten Liste von
## UI-Einträgen (id, name, kategorie, ...) liefert sie die eingeschränkte
## Sicht nach Kategoriefilter und Suchstring. Keine Szene, kein Gating.

func filtern(eintraege: Array[Dictionary], suchbegriff: String, kategorie: String) -> Array[Dictionary]:
	var suche := suchbegriff.strip_edges().to_lower()
	var ergebnis: Array[Dictionary] = []
	for eintrag in eintraege:
		var kat := str(eintrag.get("kategorie", ""))
		if kategorie != "" and kategorie != "Alle" and kat != kategorie:
			continue
		if suche != "":
			var name_str := str(eintrag.get("name", "")).to_lower()
			var id_str := str(eintrag.get("id", "")).to_lower()
			var kat_str := kat.to_lower()
			if not name_str.contains(suche) and not id_str.contains(suche) and not kat_str.contains(suche):
				continue
		ergebnis.append(eintrag)
	return ergebnis

func kategorien_aus(eintraege: Array[Dictionary]) -> Array[String]:
	var verfuegbar: Array[String] = ["Alle"]
	for eintrag: Dictionary in eintraege:
		var kategorie := str(eintrag.get("kategorie", ""))
		if kategorie != "" and not verfuegbar.has(kategorie):
			verfuegbar.append(kategorie)
	verfuegbar.sort_custom(func(a: String, b: String) -> bool:
		if a == "Alle":
			return true
		if b == "Alle":
			return false
		return a < b)
	return verfuegbar
