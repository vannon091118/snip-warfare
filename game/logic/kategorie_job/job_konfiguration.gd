extends RefCounted
class_name Job_Konfiguration
## Liest die zentrale Job-Konfiguration. Eine Zustaendigkeit: Aus dem
## Woerterbuch eines Jobs die Werte holen, mit denen gerechnet wird. Kein Job
## kennt die Schluesselnamen doppelt, und kein Wert steht hart im Code.


static func name(konfiguration: Dictionary, job_id: String) -> String:
	return str(konfiguration.get("name", job_id.capitalize()))


static func logik_id(konfiguration: Dictionary) -> String:
	return str(konfiguration.get("logik_id", ""))


static func modifikator_id(konfiguration: Dictionary) -> String:
	return str(konfiguration.get("modifikator_id", "normal"))


static func faktor(konfiguration: Dictionary) -> float:
	return float(konfiguration.get("faktor", 1.0))


static func ist_loop(konfiguration: Dictionary) -> bool:
	return bool(konfiguration.get("loop", false))


static func ressource(konfiguration: Dictionary) -> String:
	return str(konfiguration.get("ressource", ""))


static func animation(konfiguration: Dictionary) -> String:
	return str(konfiguration.get("animation", "hacken"))


static func reichweite(konfiguration: Dictionary) -> float:
	return float(konfiguration.get("reichweite", 140.0))


static func harvest_menge(konfiguration: Dictionary) -> int:
	return int(konfiguration.get("harvest_menge", 1))


static func ziel_array(konfiguration: Dictionary, haupt: String, ersatz: String) -> Array[String]:
	## Ziel-Listen kommen als Woerterbuch-Eintrag und werden typisiert gelesen.
	var roh: Variant = konfiguration.get(haupt, konfiguration.get(ersatz, []))
	var typisiert: Array[String] = []
	if typeof(roh) == TYPE_ARRAY:
		for wert: Variant in roh as Array:
			typisiert.append(str(wert))
	return typisiert
