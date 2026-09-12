extends Objekt_RegistryBasis
class_name Objekt_MoebelRegistry
## Registry der Moebel (Kategorie "Möbel"): Tische, Stühle, Betten, Schränke.
## Der Preflight zieht seine Referenzen für Möbel aus dieser Registry;
## es existiert keine zweite Quelle für Möbel-Definitionen. Die Daten
## stehen im zentralen element_katalog.json; Moebel tragen dort ihre
## Kachel-Belegung als kachel_breite/kachel_hoehe (1/4/6/8-Kachel-Fuss).

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

func moebel_sicht() -> Array[Objekt_Basis]:
	## Gesamte Sicht der Moebel-Kategorie; die Fassade reicht nichts mehr
	## durch, das Bau-Panel liest hier direkt.
	return objekte_der_kategorie("Möbel")

func kachel_fuss(id: String) -> Vector2i:
	## Kachel-Belegung eines Moebels: 1x1, 2x2, 2x3 oder 2x4.
	## Die Zahlen stehen als kachel_breite/kachel_hoehe im Katalog.
	var objekt := moebel(id)
	if objekt == null:
		return Vector2i.ONE
	var daten := objekt.schluessel_daten
	return Vector2i(maxi(int(daten.get("kachel_breite", 1)), 1), maxi(int(daten.get("kachel_hoehe", 1)), 1))

func belegte_kacheln(id: String) -> int:
	var fuss := kachel_fuss(id)
	return fuss.x * fuss.y

func _zentrale_klasse_fuer(element_id: String) -> Objekt_Basis:
	## Fallback der Moebel-Naht: Katalog-Eintraege der eigenen Kategorie
	## ohne script-Feld landen bei ihrer Moebel-Klasse. Dieses Wissen
	## wohnt hier, nicht in der Fassade; ein neuer Moebel-Typ erweitert
	## nur noch diesen Match.
	match element_id:
		"tisch":
			return Objekt_Tisch.new()
		"stuhl":
			return Objekt_Stuhl.new()
		"betten":
			return Objekt_Bett.new()
		"schrank":
			return Objekt_Schrank.new()
		"tisch_stahl":
			return Objekt_TischStahl.new()
	return Objekt_Basis.new()

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["fachkategorie"] = "Möbel"
	return arten
