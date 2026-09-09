extends RefCounted
class_name Welt_GeneratorChunkPruefer
## Interne Boundary-Simulation des Generators. Sie sieht einen fertigen
## Welt-Chunk als Zustand, prüft ihn gegen die Mindest- und Maxwerte der
## Generator-Registry und entscheidet: annehmen oder verwerfen. Ein verworfener
## Chunk verlässt die Maschine nie; die Werte werden neu gewürfelt, bis der
## Chunk passt. Dadurch hält jede Welt den Spielfluss: genug Objekte zum Arbeiten,
## nicht genug Tiere um den Spieler zu erschlagen, genug freie Kacheln zum Bauen.

## Kategorie daten: die Grenzen aus der Generator-Registry.
var grenzen: Dictionary = {}

## Kategorie logik: Prüfung eines Chunks als Zustand.

func einrichten(registry: Welt_GeneratorRegistry) -> void:
	# Der Prüfer greift nicht in private Felder der Registry: Er fragt die
	# öffentliche Schnittstelle der Registry, denn die Grenzen sind ein
	# Eintrag wie jeder andere und die Registry bleibt ihre einzige Quelle.
	grenzen = registry.eintrag_wort_fuer("grenzen")

func chunk_pruefen(objekt_zahl: int, tier_zahl: int, freie_kacheln: int, kacheln_gesamt: int) -> Dictionary:
	# Liefert den Prüfzustand: angenommen true oder false plus Grund.
	var min_objekte := int(grenzen.get("min_objekte", 0))
	var max_objekte := int(grenzen.get("max_objekte", 999999))
	var min_tiere := int(grenzen.get("min_tiere", 0))
	var max_tiere := int(grenzen.get("max_tiere", 999999))
	var min_freie := float(grenzen.get("min_freie_kacheln_anteil", 0.0))
	var freier_anteil := 0.0
	if kacheln_gesamt > 0:
		freier_anteil = float(freie_kacheln) / float(kacheln_gesamt)
	if objekt_zahl < min_objekte:
		return {"angenommen": false, "grund": "zu_wenig_objekte"}
	if objekt_zahl > max_objekte:
		return {"angenommen": false, "grund": "zu_viele_objekte"}
	if tier_zahl < min_tiere:
		return {"angenommen": false, "grund": "zu_wenig_tiere"}
	if tier_zahl > max_tiere:
		return {"angenommen": false, "grund": "zu_viele_tiere"}
	if freier_anteil < min_freie:
		return {"angenommen": false, "grund": "zu_wenig_freie_kacheln"}
	return {"angenommen": true, "grund": "grenzen_gehalten", "freier_anteil": freier_anteil}
