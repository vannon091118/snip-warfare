extends Label
class_name Ui_WeltInfo
## Welt-Info Observer: zeigt technische Laufzeit-Informationen aus dem echten
## Weltzustand (Seed, Region, Chunk, Biom, Objekte, Tiere, Generator).
## Er berechnet nichts selbst: Jede Zeile ist ein Lesezugriff auf das Modell
## und die Zähler, die die Szene durchreicht. Keine statischen Demo-Werte.

## Kategorie logik: Zustand lesen und als Text zeigen.

func zustand_zeigen(model: Welt_Model, tier_zahl: int, blick_position: Vector2, generator_name: String, verworfene_chunks: int) -> void:
	if model == null:
		text = "Keine Welt geladen"
		return
	var kachel := Vector2i(blick_position / Welt_Model.KACHEL_GROESSE)
	var region := model.region_an_kachel(kachel.x, kachel.y)
	var region_text := "-"
	var biom_text := model.biom_id
	if not region.is_empty():
		region_text = "%d/%d" % [int(region.get("region_x", 0)), int(region.get("region_y", 0))]
		biom_text = str(region.get("biom_id", biom_text))
	var zeilen := [
		"Seed: %d" % model.welt_seed,
		"Region: %s" % region_text,
		"Chunk: %d/%d" % [int(floor(float(kachel.x) / float(Welt_Generator.CHUNK_GROESSE))), int(floor(float(kachel.y) / float(Welt_Generator.CHUNK_GROESSE)))],
		"Biom: %s" % biom_text,
		"Objekte: %d" % model.objekt_anzahl(),
		"Tiere: %d" % tier_zahl,
		"Generator: %s (verworfene Chunks: %d)" % [generator_name, verworfene_chunks],
		"Weltgröße: %dx%d" % [model.raster_breite, model.raster_hoehe],
	]
	text = "\n".join(zeilen)
