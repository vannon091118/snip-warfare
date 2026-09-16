extends Welt_ModellBiom
class_name Welt_ModellMigration
## Sechste Stufe der Kette: Die Speicher-Eskalation. Alte Spielstaende
## bleiben lesbar und werden deterministisch auf das aktuelle Format gehoben.

const SPEICHER_VERSION := 6
const MIN_KOMPATIBLE_VERSION := 2

func _eskalation_anwenden(geladene_version: int) -> void:
	# Abwaertskompatibel: Neue Systeme ab Update in neu generierten Chunks,
	# alte Saves bleiben lesbar. Version 5 fuehrt welt_seed und erweiterte
	# Regionen ein; fehlende Felder werden deterministisch ergaenzt.
	# Version 6 fuehrt Z-Ebenen und biom_raster als Dictionary mit "x:y:z" Keys ein.
	if geladene_version >= SPEICHER_VERSION:
		return
	if geladene_version < 5:
		# Version 4 hatte region_kante als 4, Chunk-Kante war 2 — ab 5
		# ist die Generator-Konvention Chunk 8, Region 4 bindend.
		if regionen.is_empty() and welt_seed == 0:
			# Alter Save ohne Seed: deterministisch aus biom_id ableiten,
			# damit gleiche alte Welt nicht zufaellig neu wuerfelt.
			welt_seed = int(Kern_Hash.wort(biom_id) & 0x7FFFFFFF)
		for region in regionen:
			if int(region.get("chunk_kante", 0)) == 2:
				region["chunk_kante"] = Welt_Generator.CHUNK_GROESSE
	if geladene_version < 6:
		# Version 5 hatte biom_raster als Array oder Dictionary ohne Z-Ebene —
		# ab 6 ist es Dictionary mit "x:y:z" Keys.
		_biom_raster_migrieren()
		_raster_migrieren()

func _biom_raster_migrieren() -> void:
	# Migration: alten Array/Dict in neues Format mit Z=0 konvertieren.
	var alt_biom_raster := biom_raster.duplicate()
	biom_raster.clear()
	if typeof(alt_biom_raster) == TYPE_ARRAY:
		for i in range(alt_biom_raster.size()):
			var biom_spalte := int(i / float(raster_breite))
			var biom_zeile := i % raster_breite
			biom_raster["%d:%d:0" % [biom_zeile, biom_spalte]] = str(alt_biom_raster[i])
	elif typeof(alt_biom_raster) == TYPE_DICTIONARY:
		for schluessel: String in alt_biom_raster:
			# Alte Keys ohne Z: "x:y" -> "x:y:0"
			var biom_teile := schluessel.split(":")
			if biom_teile.size() == 2:
				biom_raster["%s:0" % [schluessel]] = str(alt_biom_raster[schluessel])
			else:
				biom_raster[schluessel] = str(alt_biom_raster[schluessel])

func _raster_migrieren() -> void:
	# Raster migrieren falls altes Format.
	var alt_raster := raster.duplicate()
	raster.clear()
	if typeof(alt_raster) == TYPE_ARRAY:
		for i in range(alt_raster.size()):
			var raster_spalte := int(i / float(raster_breite))
			var raster_zeile := i % raster_breite
			raster["%d:%d:0" % [raster_zeile, raster_spalte]] = str(alt_raster[i])
	elif typeof(alt_raster) == TYPE_DICTIONARY:
		for schluessel: String in alt_raster:
			var raster_teile := schluessel.split(":")
			if raster_teile.size() == 2:
				raster["%s:0" % [schluessel]] = str(alt_raster[schluessel])
			else:
				raster[schluessel] = str(alt_raster[schluessel])
