extends RefCounted
class_name Welt_ModellBasis
## Unteres Fundament der Welt-Modell-Kette: reine Raster-Daten und
## Raster-Operationen. Die Kette laeuft Basis, Objekte, Regionen, Biom,
## Migration, Speicher und endet in der Fassade Welt_Model; jede Stufe
## traegt genau eine Verantwortung und ruft nur eigene oder ererbte Teile.

## KACHEL_GROESSE ist nur der RUECKFALL fuer Testlaeufe ohne Definitions-Registry;
## im Spiel setzt der Generator den Wert aus world/data/welt_definition.json
## ueber kachel_groesse_setzen. Es gibt damit genau eine Quelle je Lauf.
## Z-Ebene: Standard 0, negativ = Untergrund.
const KACHEL_GROESSE := 512
const RASTER_BREITE := 32
const RASTER_HOEHE := 24
const RASTER_MIN := 4
const RASTER_MAX := 128
const MAX_Z_EBENEN := 5 ## 0 (Oberfläche) bis -4 (Tiefster Untergrund)
var aktive_z_ebene: int = 0
var raster_breite: int = RASTER_BREITE
var raster_hoehe: int = RASTER_HOEHE
## raster: Dictionary mit Key "x:y:z" -> element_id fuer jede Z-Ebene.
var raster: Dictionary = {}
## Raster biom_ids (separates Dictionary parallel zum raster). Keys "x:y:z".
var biom_raster: Dictionary = {}
var biom_id: String = "gemaaessigt"
## Kantenlaenge einer Rasterkachel in Pixeln; aus der Definitions-Registry.
var kachel_groesse: int = KACHEL_GROESSE
## Chunk-Kante aus welt_definition.json; nie doppelt im Code.
var chunk_groesse: int = 8

func _init() -> void:
	ueberziehe_fliesen("boden")

func _raster_anlegen(element_id: String) -> void:
	raster.clear()
	biom_raster.clear()
	for z in range(MAX_Z_EBENEN):
		var z_ebene := -z
		for y in range(raster_hoehe):
			for x in range(raster_breite):
				raster["%d:%d:%d" % [x, y, z_ebene]] = element_id
				biom_raster["%d:%d:%d" % [x, y, z_ebene]] = "gemaaessigt"

func karte_erzeugen(breite: int, hoehe: int, element_id: String) -> void:
	raster_breite = clampi(breite, RASTER_MIN, RASTER_MAX)
	raster_hoehe = clampi(hoehe, RASTER_MIN, RASTER_MAX)
	ueberziehe_fliesen(element_id)

func groesse() -> Vector2i:
	return Vector2i(raster_breite, raster_hoehe)

func kachel_groesse_setzen(neue_groesse: int) -> void:
	# Einzige Schreibstelle der Kachelgroesse: Der Generator ruft sie mit dem
	# Wert aus der Definitions-Registry; alles andere liest nur.
	kachel_groesse = maxi(neue_groesse, 1)

func chunk_groesse_setzen(neue_groesse: int) -> void:
	chunk_groesse = maxi(neue_groesse, 1)

func ueberziehe_fliesen(element_id: String) -> void:
	# Einzige Fliesen-Rueckfallquelle: Das Fundament wird komplett neu belegt.
	_raster_anlegen(element_id)

func z_ebene_setzen(z_ebene: int) -> void:
	aktive_z_ebene = clampi(z_ebene, -MAX_Z_EBENEN + 1, 0)

func ist_in_raster(x: int, y: int, z_ebene: int = 0) -> bool:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	return x >= 0 and y >= 0 and x < raster_breite and y < raster_hoehe and z >= -MAX_Z_EBENEN + 1 and z <= 0

func fliese_setzen(x: int, y: int, element_id: String, z_ebene: int = 0) -> void:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return
	raster["%d:%d:%d" % [x, y, z]] = element_id
	# Die sichtbare Folgenmeldung gehört zum Schreiben: Jede Kachel-Änderung
	# wird am Bus gemeldet, damit der Renderer genau diese eine Kachel
	# nachziehen kann. Ohne Autoload (Prüfläufe) bleibt die Meldung stumm,
	# und der Generator schreibt beim Aufbau, bevor Zuhörer existieren.
	var bus := Kern_SignalBus.bus()
	if bus != null:
		bus._emit_kachel_geaendert(x, y, element_id, z)

func fliese(x: int, y: int, z_ebene: int = 0) -> String:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return ""
	return str(raster.get("%d:%d:%d" % [x, y, z], ""))

func fliese_entfernen(x: int, y: int, z_ebene: int = 0) -> void:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(x, y, z):
		return
	raster.erase("%d:%d:%d" % [x, y, z])

func fliese_unterhalb(x: int, y: int, z_ebene: int = 0) -> String:
	# Liefert die Fliese genau eine Ebene tiefer (z-1)
	var z_ziel := (z_ebene if z_ebene != 0 else aktive_z_ebene) - 1
	if z_ziel < -MAX_Z_EBENEN + 1:
		return ""
	return fliese(x, y, z_ziel)

func ziel_ebene_unterhalb(z_ebene: int = 0) -> int:
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	var z_ziel := z - 1
	return z_ziel if z_ziel >= -MAX_Z_EBENEN + 1 else z

func biom_raster_holen(kachel_x: int, kachel_y: int, z_ebene: int = 0) -> String:
	# Liefert das biom_id einer Kachel aus dem separaten biom_raster.
	# Gibt "gemaaessigt" zurueck, wenn out of bounds.
	var z := z_ebene if z_ebene != 0 else aktive_z_ebene
	if not ist_in_raster(kachel_x, kachel_y, z):
		return "gemaaessigt"
	return str(biom_raster.get("%d:%d:%d" % [kachel_x, kachel_y, z], "gemaaessigt"))
