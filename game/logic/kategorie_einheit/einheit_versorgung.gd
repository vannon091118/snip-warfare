extends RefCounted
class_name Einheit_Versorgung
## Nahrungs-Versorgung der Einheiten: Sie berechnet den Gesamtbedarf aus
## dem Rassen-Schema jeder Mood-Maschine, entnimmt Fleisch der Ressourcen-
## Verwaltung und teilt Hunger-Schaden aus, wenn der Bestand nicht reicht.
## Der Takt gehört dem Manager; die Regel allein gehört dieser Maschine.

## Kategorie daten: die Quellen der Versorgung.
var _ressourcen: Einheit_Ressourcen = null
var _je_einheit_je_takt: float = 0.8
var _hunger_schaden: int = 5
var _zufall := Kern_Zufall.new()

## Kategorie logik: Einrichten, Verteilen, Menge justieren.

func einrichten(ressourcen: Einheit_Ressourcen) -> void:
	_ressourcen = ressourcen

func verteilung_setzen(nahrung_je_takt: float) -> void:
	# Zentrale Einstellung aus der UI; der Bereich bleibt gesund geklemmt.
	_je_einheit_je_takt = clampf(nahrung_je_takt, 0.1, 5.0)

func verteilen(einheiten: Array[Dictionary]) -> void:
	# Rassen-Schemata: Jede Einheit verbraucht ihren eigenen Rassen-Faktor
	# mal den zentralen Need-Faktor, geliefert von ihrer Mood-Maschine.
	if _ressourcen == null:
		return
	var gesamt := 0
	for einheit: Dictionary in einheiten:
		var m: Pop_MoodMaschine = einheit["mood"]
		gesamt += int(ceil(_je_einheit_je_takt * m.nahrungs_faktor()))
	if gesamt <= 0:
		return
	if not _ressourcen.entnehmen("fleisch", gesamt):
		for einheit: Dictionary in einheiten:
			var st: Einheit_Status = einheit["status"]
			st.vital.schaden_nehmen(_hunger_schaden, _zufall, "hunger")
