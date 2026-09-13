extends RefCounted
class_name Objekt_KatalogLader
## Der eine Ladedurchlauf des Element-Katalogs in die Objekt-Registry: Er prüft
## die Assets, setzt den Platzhalter für fehlende Bilder und holt je Eintrag
## die Datenklasse über die Plugin-Naht. Er besitzt keinen Zustand; die
## Registry bleibt die Instanz, die er befüllt.

static func uebernehmen(basis: Objekt_RegistryBasis, gelesen: Variant) -> bool:
	if typeof(gelesen) != TYPE_ARRAY:
		push_warning("Element-Katalog hat ein ungültiges Format: %s" % basis._quelle_pfad)
		return false
	var warnungen := Kern_AssetPruefer.validiere_katalog_eintraege(gelesen as Array)
	for warnung: Dictionary in warnungen:
		push_warning("Katalog-Eintrag '%s': kein gültiges Asset; Platzhalter wird verwendet" % str(warnung.get("id", "?")))
	basis.eintraege.clear()
	basis.eintraege_nach_id.clear()
	basis.kategorie_sicht.leeren()
	basis.registries_vorbereiten()
	for eintrag: Variant in gelesen:
		if typeof(eintrag) != TYPE_DICTIONARY or not (eintrag as Dictionary).has("id"):
			continue
		var wort := eintrag as Dictionary
		var element_id := str(wort["id"])
		var kategorie := str(wort.get("kategorie", ""))
		if not Kern_AssetPruefer.eintrag_hat_asset(wort):
			wort["textur_pfad"] = Kern_AssetPruefer.sichere_textur_pfad(wort, element_id)
		var objekt := klasse_fuer(basis, element_id, wort)
		objekt.aus_katalog_eintrag(wort)
		basis.registrieren(element_id, objekt)
		basis._registrieren_in_kategorie(kategorie, element_id, objekt)
	return true

static func klasse_fuer(basis: Objekt_RegistryBasis, element_id: String, eintrag: Dictionary = {}) -> Objekt_Basis:
	# Plugin-Naht: Das script-Feld des Katalog-Eintrags bestimmt die Datenklasse;
	# ein neues Objekt braucht künftig nur Katalog-Eintrag plus SVG, ohne dass
	# eine Registry-Klasse angefasst wird. ResourceLoader.exists verhindert
	# Halluzinationen bei Tippfehlern, die Typprüfung hält fremde Skripte raus.
	var skript_pfad := str(eintrag.get("script", ""))
	if skript_pfad != "":
		if not ResourceLoader.exists(skript_pfad):
			push_warning("Objekt-Skript fehlt: %s (Eintrag %s)" % [skript_pfad, element_id])
			return basis._zentrale_klasse_fuer(element_id)
		var skript: GDScript = load(skript_pfad)
		if skript != null:
			var instanz: Variant = skript.new()
			if instanz is Objekt_Basis:
				return instanz as Objekt_Basis
			push_warning("Objekt-Skript ist kein Objekt_Basis: %s" % skript_pfad)
	return basis._zentrale_klasse_fuer(element_id)
