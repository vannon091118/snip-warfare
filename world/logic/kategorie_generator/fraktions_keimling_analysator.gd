extends RefCounted
class_name Welt_FraktionsKeimlingAnalysator
## Fraktions_Keimling_Analysator: Letzter Generator-Pass vor dem Spawn.
## Teilt die Welt in NxN Makrozellen (N aus weltkarte_definition.json: regionen.breite, regionen.hoehe).
## Zählt Biome-Häufigkeiten und Ressourcendichten pro Zelle aus biom_raster und Objekt-Dichte.
## Schreibt archetype_score Dictionary: {"berg": 0.7, "wald": 0.1, "wasser": 0.2}.
## Wenn Score den Schwellenwert aus fraktions_ki_config.json überschreitet, wird ein Keimpunkt erzeugt.
## KEINE feste Fraktionen-Zahl - Weltstruktur bestimmt, wie viele entstehen.

## Kategorie daten: Makrozellen-Analyse und Archetypergebnisse.
var makro_celle_breite: int = 0
var makro_celle_hoehe: int = 0
var welt_breite: int = 0
var welt_hoehe: int = 0
var analyse_ergebnisse: Array[Dictionary] = []
var keimpunkte: Array[Dictionary] = []

## Mapping: Biom-ID zu Archetyp für Score-Berechnung
const BIOME_ZU_ARCHETYP: Dictionary = {
	"gemaaessigt": "wald",
	"wald": "wald",
	"wasser": "wasser",
	"ozean": "wasser",
	"see": "wasser",
	"steppe": "steppe",
	"tundra": "tundra",
	"gebirge": "berg",
	"berg": "berg"
}

## Ressourcen-Typen zu Archetyp
const RESSOURCE_ZU_ARCHETYP: Dictionary = {
	"erz": "berg",
	"stein": "berg",
	"holz": "wald",
	"beeren": "wald",
	"wasser_quelle": "wasser",
	"fisch": "wasser",
	"wild": "steppe",
	"kraut": "steppe",
	"eis": "tundra",
	"pilz": "wald"
}

## Kategorie logik: Welt in Zellen unterteilen und archetype_score berechnen.

func _init() -> void:
	_laden_konfiguration()

func _laden_konfiguration() -> void:
	## Lade weltkarte_definition.json für Makrozellen-Größe
	var def_pfad := "res://world/data/weltkarte_definition.json"
	if FileAccess.file_exists(def_pfad):
		var text := FileAccess.open(def_pfad, FileAccess.READ).get_as_text()
		var def: Variant = JSON.parse_string(text)
		makro_celle_breite = int(def.regionen.breite)
		makro_celle_hoehe = int(def.regionen.hoehe)
	else:
		makro_celle_breite = 16
		makro_celle_hoehe = 12
		push_warning("weltkarte_definition.json nicht gefunden, nutze Standard 16x12")

func analyse_ausfuehren(welt_model: Welt_Model, fraktions_ki_config: Dictionary) -> void:
	## Führe Analyse der fertigen Welt aus
	welt_breite = welt_model.raster_breite
	welt_hoehe = welt_model.raster_hoehe

	## Zerlege Welt in NxN Makrozellen
	var cellen_x := makro_celle_breite
	var cellen_y := makro_celle_hoehe

	## Initialisiere Zell-Datenstrukturen
	var zell_biome_zaehler: Dictionary = {}
	var zell_ressource_zaehler: Dictionary = {}
	var zell_objekt_dichte: Dictionary = {}

	for cy in range(cellen_y):
		for cx in range(cellen_x):
			var zell_id := "%d_%d" % [cx, cy]
			zell_biome_zaehler[zell_id] = {}
			zell_ressource_zaehler[zell_id] = {}
			zell_objekt_dichte[zell_id] = 0

	## Verteile Kacheln auf Makrozellen
	var kacheln_pro_zelle_x := maxi(welt_breite / cellen_x, 1)
	var kacheln_pro_zelle_y := maxi(welt_hoehe / cellen_y, 1)

	for kachel_y in range(welt_hoehe):
		for kachel_x in range(welt_breite):
			var cx := int(kachel_x / kacheln_pro_zelle_x)
			var cy := int(kachel_y / kacheln_pro_zelle_y)
			cx = clampi(cx, 0, cellen_x - 1)
			cy = clampi(cy, 0, cellen_y - 1)
			var cell_id := "%d_%d" % [cx, cy]

			## Biom aus biom_raster holen
			var biom_key := "%d:%d:%d" % [kachel_x, kachel_y, welt_model.aktive_z_ebene]
			var biome_id := "gemaaessigt"
			if welt_model.biom_raster.has(biom_key):
				biome_id = str(welt_model.biom_raster[biom_key])

			## Mappe Biom zu Archetyp und zähle
			var archetyp: Variant = BIOME_ZU_ARCHETYP.get(biome_id, "wald")
			if zell_biome_zaehler[cell_id].has(archetyp):
				zell_biome_zaehler[cell_id][archetyp] += 1
			else:
				zell_biome_zaehler[cell_id][archetyp] = 1

			## Zähle Ressourcen auf dieser Kachel (vereinfacht: Objekte als Proxy)
			## In der Praxis würde hier die tatsächliche Ressourcen-Karte gelesen
			zell_objekt_dichte[cell_id] += 1

	## Zusätzliche Ressourcen-Dichte aus Objekten berechnen
	_objekt_ressourcen_zaehlen(welt_model, cellen_x, cellen_y, kacheln_pro_zelle_x, kacheln_pro_zelle_y, zell_ressource_zaehler)

	## Berechne archetype_score pro Zelle
	var analyse_ergebnis: Dictionary = {}
	for cy in range(cellen_y):
		for cx in range(cellen_x):
			var cid := "%d_%d" % [cx, cy]
			var biome_zaehler: Dictionary = zell_biome_zaehler[cid]
			var ress_zaehler: Dictionary = zell_ressource_zaehler[cid]
			var score: Dictionary = {}

			## Normalisiere Biome/Archetyp-Frequenzen
			var total_biome := 0
			for count: int in biome_zaehler.values():
				total_biome += count
			if total_biome > 0:
				for arch: String in biome_zaehler:
					score[arch] = float(biome_zaehler[arch]) / float(total_biome)

			## Füge Ressourcendichten als Modifikator hinzu
			var total_ress := 0
			for count: int in ress_zaehler.values():
				total_ress += count
			if total_ress > 0:
				for ress: String in ress_zaehler:
					var arch: String = RESSOURCE_ZU_ARCHETYP.get(ress, "wald")
					var faktor := float(ress_zaehler[ress]) / float(total_ress) * 0.15
					if score.has(arch):
						score[arch] += faktor
					else:
						score[arch] = faktor

			## Objekt-Dichte als allgemeiner Besiedlungsdruck
			var dichte: float = zell_objekt_dichte[cid]
			if dichte > 0:
				var norm_dichte := float(dichte) / float(kacheln_pro_zelle_x * kacheln_pro_zelle_y)
				for arch in score.keys():
					score[arch] *= (1.0 + norm_dichte * 0.1)

			analyse_ergebnis[cid] = score

	analyse_ergebnisse.append(analyse_ergebnis)

	## Prüfe Schwellenwerte und erzeuge Keimpunkte
	_prüfe_und_erzeuge_keimpunkte(analyse_ergebnis, fraktions_ki_config, cellen_x, cellen_y, kacheln_pro_zelle_x, kacheln_pro_zelle_y)

func _objekt_ressourcen_zaehlen(welt_model: Welt_Model, cellen_x: int, cellen_y: int, kacheln_pro_zelle_x: int, kacheln_pro_zelle_y: int, zell_ressource_zaehler: Dictionary) -> void:
	## Zähle Ressourcen-Typen basierend auf platzierten Objekten
	for obj_idx in range(welt_model.objekt_anzahl()):
		var obj_daten := welt_model.objekt_daten(obj_idx)
		if not obj_daten.has("element_id") or not obj_daten.has("position"):
			continue
		var element_id := str(obj_daten["element_id"])
		var pos := Vector2(obj_daten["position"][0], obj_daten["position"][1])
		var kachel_x := int(pos.x / welt_model.kachel_groesse)
		var kachel_y := int(pos.y / welt_model.kachel_groesse)
		var cx := int(kachel_x / kacheln_pro_zelle_x)
		var cy := int(kachel_y / kacheln_pro_zelle_y)
		cx = clampi(cx, 0, cellen_x - 1)
		cy = clampi(cy, 0, cellen_y - 1)
		var cell_id := "%d_%d" % [cx, cy]

		## Mapp Element-ID zu Ressource
		var ressource := _element_zu_ressource(element_id)
		if ressource != "":
			var zaehler: Dictionary = zell_ressource_zaehler[cell_id]
			if zaehler.has(ressource):
				zaehler[ressource] += 1
			else:
				zaehler[ressource] = 1

func _element_zu_ressource(element_id: String) -> String:
	match element_id:
		"baum": return "holz"
		"busch": return "beeren"
		"stein": return "stein"
		"steine_gruppe": return "stein"
		"berg": return "erz"
		"felswand": return "erz"
		"erzader": return "erz"
		"see": return "wasser_quelle"
		_: return ""

func _prüfe_und_erzeuge_keimpunkte(analyse_ergebnis: Dictionary, fraktions_ki_config: Dictionary, cellen_x: int, cellen_y: int, kacheln_pro_zelle_x: int, kacheln_pro_zelle_y: int) -> void:
	## Lade Schwellenwert aus Konfiguration
	var schwellenwert := 0.35  # RUECKFALL, wenn Konfiguration fehlt
	if fraktions_ki_config.has("keimling_schwellenwert"):
		schwellenwert = float(fraktions_ki_config["keimling_schwellenwert"])

	## Lade Archetyp-Gewichtung
	var archetyp_gewichtung := {}
	if fraktions_ki_config.has("archetyp_gewichtung"):
		archetyp_gewichtung = fraktions_ki_config.archetyp_gewichtung

	for cell_id: String in analyse_ergebnis:
		var score: Dictionary = analyse_ergebnis[cell_id]
		## Wende Gewichtung an
		var gewichteter_score: Dictionary = {}
		var max_score := 0.0
		var dominant_archetyp := "wald"
		for arch: String in score:
			var val := float(score[arch])
			var gewicht := float(archetyp_gewichtung.get(arch, 1.0))
			var gew_val := val * gewicht
			gewichteter_score[arch] = gew_val
			if gew_val > max_score:
				max_score = gew_val
				dominant_archetyp = arch

		## Gesamt-Score ist der gewichtete Maximum-Wert
		var gesamt_score := max_score

		if gesamt_score > schwellenwert:
			## Erzeuge Keimpunkt für diese Zelle
			var keimpunkt: Dictionary = {}
			keimpunkt["zellen_id"] = cell_id
			keimpunkt["dominante_archetyp"] = dominant_archetyp
			keimpunkt["score"] = gewichteter_score
			keimpunkt["gesamt_score"] = gesamt_score

			## Berechne Weltposition (Mitte der Makrozelle)
			var coords := cell_id.split("_")
			var cx := int(coords[0])
			var cy := int(coords[1])
			var welt_x := (cx + 0.5) * kacheln_pro_zelle_x * Welt_Model.KACHEL_GROESSE
			var welt_y := (cy + 0.5) * kacheln_pro_zelle_y * Welt_Model.KACHEL_GROESSE
			keimpunkt["position"] = Vector2(welt_x, welt_y)
			keimpunkt["makro_koordinaten"] = Vector2i(cx, cy)

			keimpunkte.append(keimpunkt)

func get_keimpunkte() -> Array[Dictionary]:
	return keimpunkte.duplicate(true)

func get_analyse_ergebnisse() -> Array[Dictionary]:
	return analyse_ergebnisse.duplicate(true)