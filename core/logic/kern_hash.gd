extends RefCounted
class_name Kern_Hash
## Deterministische Referenz-Hashes fuer Seed-Ableitung und Identitaet.
## Der eingebaute Godot hash() ist nur pro Engine-Version stabil; seine Werte
## duerfen nicht in Seed-Ketten einfliesst, weil ein Engine-Wechsel sonst aus
## derselben Welt eine andere macht. Diese Klasse ist die einzige Stelle, die
## Hashwerte fuer Ableitungen berechnet, damit alle Domänen dieselbe
## Zahlenwahrheit teilen. Eingangsdaten wandern hier nie in einen Seed-Kontext
## ungesalzen: Schemata wie Name, Position oder Identitaet werden immer mit
## einem Domänen-Salz gemischt, damit gleiche Werte in unterschiedlichen
## Rollen nicht kollidieren.
## Verboten (Preflight E012): hash() im Spielcode außerhalb dieser Klasse.

const FNV_OFFSET_BASIS: int = 5472609002491880229
const FNV_PRIM: int = 1099511628211
const MASK_63_BIT: int = 0x7FFFFFFFFFFFFFFF

## Kategorie logik: Wort- und Zahlenreihen-Hash (FNV-1a).

static func wort(text: String) -> int:
	## FNV-1a 64-bit auf einem String, auf 63 Bit gemaskt fuer GDScript-Zahlen.
	var wert: int = FNV_OFFSET_BASIS
	for zeichen in text:
		wert ^= ord(zeichen)
		wert = int((wert * FNV_PRIM) & MASK_63_BIT)
	return wert

static func wort_gesalzen(text: String, salz: String) -> int:
	## Mixt ein Domänen-Salz in den Hash, damit derselbe Eingangswert in
	## unterschiedlichen Rollen (Name, Position, Identitaet) verschieden
	## abgeleitet wird. Es wird doppelt gehasht, damit das Salz nicht aus dem
	## Ergebnis zurueckgerechnet werden kann.
	var gemischt := "%s\u001f%s" % [salz, text]
	var erst := wort(gemischt)
	return wort("%s\u001e%d" % [salz, erst])

static func vektor(punkt: Vector2i) -> int:
	## FNV-1a ueber die beiden Koordinaten als feste Längen-Wörter.
	## Gleiche Position liefert denselben Wert, auf jedem Rechner.
	var wert: int = FNV_OFFSET_BASIS
	wert = _schritt(wert, punkt.x)
	wert = _schritt(wert, punkt.y)
	return wert

static func _schritt(wert: int, zahl: int) -> int:
	## Ein Zahlenwort geht als vier Bytes, je Byte ein FNV-Schritt, ein.
	var gemaskt := int(zahl) & MASK_63_BIT
	for durchlauf in 4:
		var stueck := (gemaskt >> (durchlauf * 8)) & 0xFF
		wert ^= stueck
		wert = int((wert * FNV_PRIM) & MASK_63_BIT)
	return wert
