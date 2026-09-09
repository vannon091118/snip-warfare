extends RefCounted
class_name Kern_SteuerungUebersetzer
## Uebersetzer der menschenlesbaren Steuerungs-Config in echte Spielwerte.
## Faktor 1.0 bedeutet zehn Sekunden auf der Weltuhr; diese Klasse rechnet
## in ticks um. Die Config darf direkt angepasst werden, die Logik liest nur
## das Uebersetzte und kennt keine hart codierten Tasten mehr.

static func ticks_aus_faktor(faktor: float) -> int:
	var geklemmt := clampf(faktor, 0.1, 10.0)
	var sekunden := geklemmt * 10.0
	return maxi(int(round(sekunden * Kern_Weltuhr.TICK_RATE_HZ)), 1)

static func faktor_aus_ticks(ticks: int) -> float:
	if ticks <= 0:
		return 0.1
	return clampf(float(ticks) / (10.0 * Kern_Weltuhr.TICK_RATE_HZ), 0.1, 10.0)

static func ist_gueltige_steuerung(steuerung: Kern_SteuerungBasis) -> bool:
	if steuerung == null:
		return false
	if steuerung.kamera_tasten.is_empty():
		return false
	if steuerung.auswahl_radius <= 0.0:
		return false
	if steuerung.kontext_aktionen.is_empty():
		return false
	for aktion in steuerung.kontext_aktionen:
		if typeof(aktion) != TYPE_DICTIONARY:
			return false
		var wort := aktion as Dictionary
		if not wort.has("id") or str(wort["id"]) == "":
			return false
		if not wort.has("label") or str(wort["label"]) == "":
			return false
		if not Kern_AssetPruefer.textur_pfad_gueltig(str(wort.get("icon_pfad", ""))):
			return false
	return true
