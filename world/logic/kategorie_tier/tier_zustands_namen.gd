extends RefCounted
class_name Tier_ZustandsNamen
## Die Namen der Tierzustände als eine einzige Quelle. Der Status haelt das
## Enum, die Verhaltens-Maschine spricht Namen, und diese Klasse uebersetzt in
## beide Richtungen. So kennt keine Seite die Schreibweise der anderen.

const RUHE := "ruhe"
const AUFGESCHRECKT := "aufgeschreckt"
const WEGFLIEGEN := "wegfliegen"
const VERFOLGEN := "verfolgen"
const TOT := "tot"

const REIHENFOLGE := [RUHE, AUFGESCHRECKT, WEGFLIEGEN, VERFOLGEN, TOT]


static func name_fuer(wert: int) -> String:
	## Der Name eines Zustandswertes; ohne Treffer gilt die Ruhe.
	if wert < 0 or wert >= REIHENFOLGE.size():
		return RUHE
	return REIHENFOLGE[wert]


static func wert_fuer(name: String) -> int:
	## Der Zustandswert eines Namens; ohne Treffer gilt die Ruhe.
	var stelle := REIHENFOLGE.find(name)
	return 0 if stelle < 0 else stelle
