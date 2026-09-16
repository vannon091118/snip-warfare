extends Welt_ModellObjekte
class_name Welt_ModellLeben
## Dritte Stufe der Kette: Tile-Leben fuer abbaubare Tiles. Die Fliesen-
## Entfernung der Basis wird hier um das Sterben des Lebens erweitert.

## Tile-Leben fuer abbaubare Tiles (Fels, Geroell). Keys "x:y:z" -> int (Leben).
## Wird bei Generierung aus Katalog initialisiert.
var tile_leben: Dictionary = {}

func fliese_entfernen(x: int, y: int, z_ebene: int = 0) -> void:
	# Erweitert die Basis-Entfernung: Tile-Leben stirbt mit der Fliese.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return
	super(x, y, z_ebene)
	tile_leben.erase("%d:%d:%d" % [x, y, z])

func tile_leben_initialisieren(x: int, y: int, z_ebene: int, leben: int) -> void:
	if not ist_in_raster(x, y, z_ebene):
		return
	tile_leben["%d:%d:%d" % [x, y, z_ebene]] = leben

func tile_leben_holen(x: int, y: int, z_ebene: int) -> int:
	if not ist_in_raster(x, y, z_ebene):
		return 0
	return int(tile_leben.get("%d:%d:%d" % [x, y, z_ebene], 0))

func tile_leben_setzen(x: int, y: int, z_ebene: int, leben: int) -> void:
	if not ist_in_raster(x, y, z_ebene):
		return
	tile_leben["%d:%d:%d" % [x, y, z_ebene]] = leben

func tile_leben_schaden(x: int, y: int, z_ebene: int, schaden: int) -> int:
	# Wendet Schaden an, gibt neues Leben zurueck. Bei <= 0 Tile entfernen.
	var aktuell := tile_leben_holen(x, y, z_ebene)
	var neu := aktuell - schaden
	if neu <= 0:
		fliese_entfernen(x, y, z_ebene)
		return 0
	tile_leben_setzen(x, y, z_ebene, neu)
	return neu
