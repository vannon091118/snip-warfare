extends RefCounted
class_name Pop_NamensGenerator
## Deterministischer Namensgenerator für Rassen und Fraktionen.
## Zieht Silben aus archetypspezifischen Pools mittels Kern_Zufall.
## Keine zufälligen Namen: gleicher Seed + gleicher Keimpunkt = gleicher Name.
## Pools sind in JSON definiert und erweiterbar.

## Silben-Pools pro Archetyp für Rassen-Namen
const RASSEN_SILBEN_POOLS: Dictionary = {
	"wald": {
		"vokal": ["a", "e", "i", "o", "u", "ä", "ö", "ü"],
		"konsonant": ["l", "r", "n", "s", "m", "h", "w", "b"],
		"silben": ["al", "el", "il", "ol", "ul", "an", "en", "in", "on", "un", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "am", "em", "im", "om", "um", "ah", "eh", "ih", "oh", "uh", "aw", "ew", "iw", "ow", "uw", "ab", "eb", "ib", "ob", "ub"],
		"anfang": ["Al", "El", "Il", "Ol", "Ul", "An", "En", "In", "On", "Un", "Ar", "Er", "Ir", "Or", "Ur", "As", "Es", "Is", "Os", "Us", "Am", "Em", "Im", "Om", "Um", "Aw", "Ew", "Iw", "Ow", "Uw", "Av", "Ev", "Iv", "Ov", "Uv"],
		"ende": ["in", "on", "an", "en", "il", "el", "al", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "im", "em", "am", "om", "um", "ith", "eth", "ath", "oth", "uth"]
	},
	"berg": {
		"vokal": ["a", "o", "u", "e", "i"],
		"konsonant": ["k", "g", "d", "t", "r", "n", "m", "z", "h"],
		"silben": ["ak", "ok", "uk", "ek", "ik", "ag", "og", "ug", "eg", "ig", "ad", "od", "ud", "ed", "id", "at", "ot", "ut", "et", "it", "ar", "or", "ur", "er", "ir", "an", "on", "un", "en", "in", "am", "om", "um", "em", "im", "az", "oz", "uz", "ez", "iz", "ah", "oh", "uh", "eh", "ih"],
		"anfang": ["Kor", "Gor", "Dor", "Tor", "Mor", "Nor", "Zor", "Hor", "Kar", "Gar", "Dar", "Tar", "Mar", "Nar", "Zar", "Har", "Kul", "Gul", "Dul", "Tul", "Mul", "Nul", "Zul", "Hul", "Kaz", "Gaz", "Daz", "Taz", "Maz", "Naz", "Zaz", "Haz"],
		"ende": ["ak", "ok", "uk", "ag", "og", "ug", "ad", "od", "ud", "at", "ot", "ut", "ar", "or", "ur", "an", "on", "un", "am", "om", "um", "az", "oz", "uz", "ah", "oh", "uh", "orn", "arn", "urn", "azh", "ogh", "ugh"]
	},
	"wasser": {
		"vokal": ["a", "e", "i", "o", "u", "ä"],
		"konsonant": ["l", "r", "n", "s", "m", "w", "f", "h"],
		"silben": ["al", "el", "il", "ol", "ul", "an", "en", "in", "on", "un", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "am", "em", "im", "om", "um", "aw", "ew", "iw", "ow", "uw", "af", "ef", "if", "of", "uf", "ah", "eh", "ih", "oh", "uh"],
		"anfang": ["Mar", "Nar", "Lar", "Sar", "War", "Far", "Har", "Mal", "Nel", "Sil", "Oll", "Ull", "Mal", "Mela", "Nila", "Sola", "Wela", "Fela", "Hela", "Mira", "Nira", "Sira", "Ola", "Ula", "Mare", "Nare", "Lare", "Sare", "Ware", "Fare", "Hare"],
		"ende": ["in", "on", "an", "en", "il", "el", "al", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "im", "em", "am", "om", "um", "ish", "esh", "ash", "osh", "ush", "ina", "ena", "ana", "ona", "una"]
	},
	"steppe": {
		"vokal": ["a", "e", "i", "o", "u"],
		"konsonant": ["k", "h", "r", "s", "t", "n", "m", "p", "b"],
		"silben": ["ak", "ek", "ik", "ok", "uk", "ah", "eh", "ih", "oh", "uh", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "at", "et", "it", "ot", "ut", "an", "en", "in", "on", "un", "am", "em", "im", "om", "um", "ap", "ep", "ip", "op", "up", "ab", "eb", "ib", "ob", "ub"],
		"anfang": ["Kas", "Kes", "Kis", "Kos", "Kus", "Has", "Hes", "His", "Hos", "Hus", "Ras", "Res", "Ris", "Ros", "Rus", "Tas", "Tes", "Tis", "Tos", "Tus", "Kan", "Ken", "Kin", "Kon", "Kun", "Han", "Hen", "Hin", "Hon", "Hun", "Rap", "Rep", "Rip", "Rop", "Rup"],
		"ende": ["ak", "ek", "ik", "ok", "uk", "ah", "eh", "ih", "oh", "uh", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "at", "et", "it", "ot", "ut", "an", "en", "in", "on", "un", "ap", "ep", "ip", "op", "up", "ab", "eb", "ib", "ob", "ub"]
	},
	"tundra": {
		"vokal": ["a", "e", "i", "o", "u", "y"],
		"konsonant": ["k", "v", "f", "r", "s", "n", "l", "h", "j"],
		"silben": ["ak", "ek", "ik", "ok", "uk", "av", "ev", "iv", "ov", "uv", "af", "ef", "if", "of", "uf", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "an", "en", "in", "on", "un", "al", "el", "il", "ol", "ul", "ah", "eh", "ih", "oh", "uh", "aj", "ej", "ij", "oj", "uj"],
		"anfang": ["Kor", "Vor", "For", "Sor", "Nor", "Lor", "Hor", "Jor", "Kul", "Vul", "Ful", "Sul", "Nul", "Lul", "Hul", "Jul", "Kaz", "Vaz", "Faz", "Saz", "Naz", "Laz", "Haz", "Jaz", "Kyl", "Vyl", "Fyl", "Syl", "Nyl", "Lyl", "Hyl", "Jyl"],
		"ende": ["ak", "ek", "ik", "ok", "uk", "av", "ev", "iv", "ov", "uv", "af", "ef", "if", "of", "uf", "ar", "er", "ir", "or", "ur", "as", "es", "is", "os", "us", "an", "en", "in", "on", "un", "al", "el", "il", "ol", "ul", "aj", "ej", "ij", "oj", "uj", "orn", "arn", "yrn"]
	}
}

## Silben-Pools für Fraktions-Namen (etwas formeller/gruppenhafter)
const FRAKTION_SILBEN_POOLS: Dictionary = {
	"wald": {
		"anfang": ["Silber", "Grün", "Moos", "Blatt", "Wald", "Hain", "Eichen", "Buchen", "Tannen", "Farn", "Wild", "Reh", "Hirsch", "Fuchs", "Dachs", "Eulen", "Sänger", "Wächter", "Hüter", "Kinder"],
		"mittel": ["wald", "hain", "grün", "moos", "blatt", "ast", "zweig", "baum", "wurzel", "erde", "licht", "schatten", "wind", "klang", "sang", "ruf", "blick", "schritt", "pfad", "weg"],
		"ende": ["bund", "orden", "kreis", "gemeinschaft", "schaft", "volk", "stamm", "clan", "sippe", "familie", "garde", "wache", "hüter", "wächter", "kinder", "enkel", "nachkommen", "linie", "blut", "geist"]
	},
	"berg": {
		"anfang": ["Eisen", "Stein", "Fels", "Gipfel", "Kamm", "Grub", "Erz", "Metall", "Bronze", "Stahl", "Hammer", "Amboss", "Schmied", "Berg", "Tief", "Schacht", "Stollen", "Gang", "Höhle", "Kluft"],
		"mittel": ["stein", "fels", "eisen", "erz", "metall", "bronze", "stahl", "hammer", "amboss", "schmied", "berg", "tief", "schacht", "stollen", "gang", "höhle", "kluft", "grat", "kamm", "gipfel"],
		"ende": ["bund", "orden", "kreis", "gemeinschaft", "schaft", "volk", "stamm", "clan", "sippe", "familie", "garde", "wache", "hüter", "wächter", "bruderschaft", "schwesternschaft", "zunft", "gilde", "haus", "linie"]
	},
	"wasser": {
		"anfang": ["Blau", "Welle", "Strom", "Fluss", "See", "Meer", "Bucht", "Hafen", "Anker", "Segel", "Mast", "Kiel", "Ruder", "Netz", "Perle", "Muschel", "Koralle", "Tiefe", "Strand", "Ufer"],
		"mittel": ["welle", "strom", "fluss", "see", "meer", "bucht", "hafen", "anker", "segel", "mast", "kiel", "ruder", "netz", "perle", "muschel", "koralle", "tiefe", "strand", "ufer", "brandung"],
		"ende": ["bund", "orden", "kreis", "gemeinschaft", "schaft", "volk", "stamm", "clan", "sippe", "familie", "garde", "wache", "hüter", "wächter", "flotte", "schar", "schwarm", "schule", "linie", "blut", "geist"]
	},
	"steppe": {
		"anfang": ["Gold", "Weit", "Ebene", "Gras", "Horizont", "Sonne", "Wind", "Sturm", "Pferd", "Reiter", "Bogen", "Pfeil", "Speer", "Schild", "Herde", "Rind", "Stier", "Kuh", "Kalb", "Lamm"],
		"mittel": ["weit", "ebene", "gras", "horizont", "sonne", "wind", "sturm", "pferd", "reiter", "bogen", "pfeil", "speer", "schild", "herde", "rind", "stier", "kuh", "kalb", "lamm", "wolle"],
		"ende": ["bund", "orden", "kreis", "gemeinschaft", "schaft", "volk", "stamm", "clan", "sippe", "familie", "garde", "wache", "hüter", "wächter", "horde", "zug", "karawane", "stamm", "sippe", "linie", "blut"]
	},
	"tundra": {
		"anfang": ["Eis", "Frost", "Schnee", "Nord", "Winter", "Kalt", "Gletscher", "Eisbär", "Wolf", "Rentier", "Elch", "Mammut", "Säbel", "Zahn", "Klaue", "Pranke", "Fell", "Pelz", "Daunen", "Wärme"],
		"mittel": ["eis", "frost", "schnee", "nord", "winter", "kalt", "gletscher", "eisbar", "wolf", "rentier", "elch", "mammut", "säbel", "zahn", "klaue", "pranke", "fell", "pelz", "daunen", "wärme"],
		"ende": ["bund", "orden", "kreis", "gemeinschaft", "schaft", "volk", "stamm", "clan", "sippe", "familie", "garde", "wache", "hüter", "wächter", "horde", "rudel", "meute", "herde", "linie", "blut", "geist"]
	}
}

## Kategorie logik: Generiere Namen deterministisch

static func generiere_rassen_name(archetyp: String, keimpunkt_id: String, welt_seed: int) -> String:
	## Erzeuge RNG für diese spezifische Kombination
	var rng := Kern_Zufall.abgeleitet_fuer(welt_seed, hash(keimpunkt_id + "_rasse_" + archetyp))
	var pools: Dictionary = RASSEN_SILBEN_POOLS.get(archetyp, RASSEN_SILBEN_POOLS["wald"])

	## Name-Struktur: Anfang + 1-2 Silben + Ende
	var name := ""
	var anfang_pool: Array = pools.get("anfang", [])
	var silben_pool: Array = pools.get("silben", [])
	var ende_pool: Array = pools.get("ende", [])

	## Anfang (1 Element)
	var anfang_idx := rng.naechste_zahl() % anfang_pool.size()
	name += anfang_pool[anfang_idx]

	## 1-2 mittlere Silben
	var silben_anzahl := 1 + (rng.naechste_zahl() % 2)
	for i in range(silben_anzahl):
		var silb_idx := rng.naechste_zahl() % silben_pool.size()
		name += silben_pool[silb_idx].to_lower()

	## Ende (1 Element)
	var ende_idx := rng.naechste_zahl() % ende_pool.size()
	name += ende_pool[ende_idx].to_lower()

	return name

static func generiere_fraktions_name(archetyp: String, keimpunkt_id: String, welt_seed: int) -> String:
	## Erzeuge RNG für diese spezifische Kombination
	var rng := Kern_Zufall.abgeleitet_fuer(welt_seed, hash(keimpunkt_id + "_fraktion_" + archetyp))
	var pools: Dictionary = FRAKTION_SILBEN_POOLS.get(archetyp, FRAKTION_SILBEN_POOLS["wald"])

	## Name-Struktur: Anfang + Mitte + Ende (mit Bindestrich oder Leerzeichen)
	var rng_wahl := rng.naechste_zahl() % 3
	var trennzeichen := " " if rng_wahl == 0 else "-" if rng_wahl == 1 else ""

	var anfang_pool: Array = pools.get("anfang", [])
	var mitte_pool: Array = pools.get("mittel", [])
	var ende_pool: Array = pools.get("ende", [])

	var anfang_idx := rng.naechste_zahl() % anfang_pool.size()
	var name: String = str(anfang_pool[anfang_idx])

	var mitte_idx := rng.naechste_zahl() % mitte_pool.size()
	name += trennzeichen + mitte_pool[mitte_idx].to_lower()

	var ende_idx := rng.naechste_zahl() % ende_pool.size()
	name += trennzeichen + ende_pool[ende_idx].to_lower()

	return name

static func hash(input: String) -> int:
	## FNV-1a 64-bit Hash für deterministische Seed-Ableitung
	var h: int = int(0x84222325) | (int(0xcbf29ce4) << 32)
	for zeichen in input:
		h ^= ord(zeichen)
		h = int((h * 0x100000001b3) & 0x7FFFFFFFFFFFFFFF)
	return h
