extends RefCounted
class_name Kern_AssetPruefer
## Pflicht-Gate des Projekts: Jede Registry-Aktion muss eine sichtbare
## Reaktion im Spiel hervorbringen. Deshalb zeigt jeder Registry-Eintrag auf
## ein Asset. Fehlt eine SVG, erzeugt dieser Prüfer einen Platzhalter,
## damit die Registrierung trotzdem gültig bleibt (Asset-Zwang mit Fallback).
## Die Validierung läuft sowohl im Preflight (E022) als auch zur Laufzeit.

## Kategorie daten: der Standard-Platzhalter als SVG-Quelle.
const PLATZHALTER_SVG := """<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" width=\"64\" height=\"64\"><rect x=\"1\" y=\"1\" width=\"62\" height=\"62\" rx=\"7\" fill=\"#F6F1E4\" stroke=\"#C75B39\" stroke-width=\"2\" stroke-dasharray=\"6 4\"/><text x=\"32\" y=\"30\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"8\" fill=\"#4A4237\">Fehlt</text><text x=\"32\" y=\"40\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"6\" fill=\"#7A6A54\">SVG</text></svg>"""

## Kategorie logik: Prüf- und Korrektur-Routinen.

static func textur_pfad_gueltig(pfad: String) -> bool:
	if pfad == "":
		return false
	if not pfad.begins_with("res://"):
		return false
	if not (pfad.ends_with(".svg") or pfad.ends_with(".png") or pfad.ends_with(".tres")):
		return false
	return ResourceLoader.exists(pfad) or FileAccess.file_exists(pfad)

static func eintrag_hat_asset(eintrag: Dictionary) -> bool:
	# Unterstützt Varianten der Katalog-Feldnamen (textur_pfad, sheet_pfad, icon_pfad, asset).
	for schluessel in ["textur_pfad", "sheet_pfad", "icon_pfad", "asset"]:
		var pfad := str(eintrag.get(schluessel, ""))
		if pfad != "" and textur_pfad_gueltig(pfad):
			return true
	return false

static func sichere_textur_pfad(eintrag: Dictionary, _fallback_id: String) -> String:
	for schluessel in ["textur_pfad", "sheet_pfad", "icon_pfad"]:
		var pfad := str(eintrag.get(schluessel, ""))
		if pfad != "" and textur_pfad_gueltig(pfad):
			return pfad
	var platzhalter_pfad := "res://core/assets/platzhalter.svg"
	_stelle_platzhalter_sicher(platzhalter_pfad)
	return platzhalter_pfad

static func _stelle_platzhalter_sicher(pfad: String) -> void:
	if ResourceLoader.exists(pfad) or FileAccess.file_exists(pfad):
		return
	var system_pfad := ProjectSettings.globalize_path(pfad)
	var ordner := system_pfad.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ordner)
	var inhalt := PLATZHALTER_SVG.replace("Fehlt", str(pfad.get_file().get_basename().capitalize()))
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	if datei != null:
		datei.store_string(inhalt)
		datei.close()

static func validiere_katalog_eintraege(katalog: Array) -> Array[Dictionary]:
	# Liefert je Eintrag ohne Asset eine Warnmeldung; Aufrufer können loggen oder blocken.
	var warnungen: Array[Dictionary] = []
	for index in katalog.size():
		var eintrag: Variant = katalog[index]
		if typeof(eintrag) != TYPE_DICTIONARY:
			continue
		var wort := eintrag as Dictionary
		if eintrag_hat_asset(wort):
			continue
		var eintrag_id := str(wort.get("id", "unbekannt_%d" % index))
		warnungen.append({"index": index, "id": eintrag_id, "grund": "kein gueltiges Asset"})
		# Pflege: in der Registry wird über sichere_textur_pfad ein Platzhalter erzeugt,
		# daher bleibt der Eintrag hier registrierbar.
	return warnungen

static func ticks_aus_faktor(faktor: float) -> int:
	# Einzige Wahrheit: Weltuhr uebersetzt faktor -> ticks, hier nur delegiert.
	return Kern_Weltuhr.ticks_aus_faktor(faktor)
