extends Welt_RegistryBasis
class_name Objekt_RegistryBasis
## Gemeinsame Basis aller Katalog-Registries der Kategorie Objekt: Sie lädt den
## Element-Katalog einmalig, verteilt die Objekte auf die Fach-Registries und
## reicht gefilterte Sichten weiter. Den Ladedurchlauf trägt der
## Objekt_KatalogLader, die Kategorie-Fragen die Objekt_KategorieSicht; hier
## bleibt nur die Naht zu den Unterklassen.

## Kategorie daten: Fach-Registries als gefilterte Sicht über den Katalog.
var _registries_nach_kategorie: Dictionary = {}
var kategorie_sicht := Objekt_KategorieSicht.new()

const KATALOG_PFAD := "res://world/data/element_katalog.json"

func _init(quelle_pfad: String = "") -> void:
	# Eine Fach-Registry ist eine gefilterte Sicht und lädt den Katalog nicht
	# selbst: Nur die Fassade Welt_Registry übergibt den KATALOG_PFAD.
	super(quelle_pfad)

func schema_name() -> String:
	return "Objekt_RegistryBasis"

func _eintraege_uebernehmen(gelesen: Variant) -> bool:
	return Objekt_KatalogLader.uebernehmen(self, gelesen)

func registries_vorbereiten() -> void:
	# Unterklassen legen hier ihre Fach-Registries an.
	pass

func _zentrale_klasse_fuer(_element_id: String) -> Objekt_Basis:
	# Übergangs-Fallback für Katalog-Einträge ohne script-Feld.
	return Objekt_Basis.new()

func _registrieren_in_kategorie(kategorie: String, element_id: String, objekt: Objekt_Basis) -> void:
	var registry: Welt_RegistryBasis = _registries_nach_kategorie.get(kategorie)
	if registry == null:
		return
	registry.registrieren(element_id, objekt)
	kategorie_sicht.merken(kategorie, objekt)

func registry_nach_kategorie(kategorie: String) -> Welt_RegistryBasis:
	var registry: Welt_RegistryBasis = _registries_nach_kategorie.get(kategorie)
	return registry

func registries_namen() -> Array[String]:
	var namen: Array[String] = []
	for kategorie: String in _registries_nach_kategorie.keys():
		namen.append(kategorie)
	namen.sort()
	return namen

func finde_objekt(id: String) -> Objekt_Basis:
	var treffer := finde_eintrag(id)
	return treffer as Objekt_Basis if treffer != null else null

func hat_objekt(id: String) -> bool:
	return hat_eintrag(id)

func kategorien() -> Array[String]:
	return kategorie_sicht.kategorien(eintraege)

func objekte_der_kategorie(kategorie: String) -> Array[Objekt_Basis]:
	return kategorie_sicht.der_kategorie(kategorie, eintraege)

func datenfeld_arten() -> Dictionary:
	var arten := super()
	arten["eintraege"] = "Array[Objekt_Basis]"
	return arten
