extends RefCounted
class_name Welt_GeneratorVerteilung
## Verteilungsmaschine des Generators. Sie zieht Einträge nach Gewicht, aber
## niemals frei: Jede Ziehung läuft über Kern_Zufall innerhalb eines Mutationsschemas,
## wird aus dem Seed-Zustand abgeleitet und als Zustand festgehalten. Gleicher
## Seed, gleiche Welt, an jedem Rechner.

## Kategorie daten: die gezogenen Einträge als Zustandsprotokoll.
var gezogen: Array[String] = []
var zufall: Kern_Zufall = Kern_Zufall.new()

## Kategorie logik: Gewichtete Ziehung aus der finalen Registry.

func start_zustand_setzen(seed_wert: int) -> void:
	zufall.start_zustand_setzen(seed_wert)
	gezogen.clear()

func ziehe_eintrag(registry: Welt_GeneratorRegistry, kategorie: String, biom_id: String) -> String:
	return ziehe_eintrag_mit(registry, kategorie, biom_id, zufall)

func ziehe_eintrag_mit(registry: Welt_GeneratorRegistry, kategorie: String, biom_id: String, quelle: Kern_Zufall, ebene: String = "") -> String:
	# Gewichtetes Los mit expliziter Zufallsquelle: Gleiche Quelle plus
	# gleiche Registry liefert immer dasselbe Los. Ohne Quelle keine Ziehung.
	# Die Ebene sondert Makro-Landschaften (Gebirge, Ozean) von der lokalen
	# Karte; leer heißt: alles ziehen (Makrokarte).
	if quelle == null:
		return ""
	var kandidaten := registry.ids_mit_gewicht(kategorie)
	if kandidaten.is_empty():
		return ""
	var summe := 0.0
	var effektive: Dictionary = {}
	for eintrag_id: String in kandidaten:
		if ebene != "" and str(registry.eintrag_wort_fuer(eintrag_id).get("ebene", "lokal")) != ebene:
			continue
		var gewicht := registry.gewicht_fuer(eintrag_id)
		if registry.biom_vorliebe_fuer(eintrag_id).has(biom_id):
			gewicht *= 2.0
		effektive[eintrag_id] = gewicht
		summe += gewicht
	if summe <= 0.0:
		return ""
	var wurf := quelle.naechste_zahl() % 1000000
	var schwelle := float(wurf) / 1000000.0 * summe
	var lauf := 0.0
	for eintrag_id: String in effektive.keys():
		lauf += float(effektive[eintrag_id])
		if schwelle < lauf:
			gezogen.append(eintrag_id)
			return eintrag_id
	return ""

func zustand_als_wort() -> String:
	return zufall.zustaende_als_wort()

func zustand_uebernehmen(wort: String) -> void:
	zufall.zustaende_uebernehmen(wort)
