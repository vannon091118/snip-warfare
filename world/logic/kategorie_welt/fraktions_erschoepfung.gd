extends RefCounted
class_name Welt_FraktionsErschoepfung
## Erschöpfungs-Saat einer frisch expandierten Fraktionskarte: Sie legt je
## Chunk und Ressourcentyp den Startwert null an. Nur neue Chunkgenerierung
## hebt die Erschöpfung wieder an, deshalb ist Expansion der einzige Weg zu
## mehr Vorrat.

const NULL_JE_RESSOURCE := {
	"holz": 0, "stein": 0, "erz": 0, "beeren": 0, "wasser": 0,
	"fisch": 0, "wild": 0, "kraut": 0, "eis": 0, "pilz": 0,
}

static func saeen(karte: Welt_Model) -> void:
	if karte == null:
		return
	var chunk_kante := maxi(karte.chunk_groesse, 1)
	var chunk_x_max := ceili(float(karte.raster_breite) / float(chunk_kante))
	var chunk_y_max := ceili(float(karte.raster_hoehe) / float(chunk_kante))
	var daten: Dictionary = {}
	for cx in range(chunk_x_max):
		for cy in range(chunk_y_max):
			daten["%d_%d" % [cx, cy]] = NULL_JE_RESSOURCE.duplicate(true)
	karte.objekt_feld_setzen(-1, "erschoepfung_pro_chunk", daten)
