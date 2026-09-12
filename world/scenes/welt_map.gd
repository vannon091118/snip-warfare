extends Control
## World Map Szene: Übersichtskarte der Makro-Regionen und des Fraktionsnetzwerks.
## Ermöglicht dem Spieler die Wahl seines Startbereichs vor der lokalen Spielkartengenerierung.
## Enthält keine Simulationslogik; sie bindet nur Planer, Modell und Sitzung.

const SZENE_KARTE := "res://world/scenes/welt.tscn"
const SZENE_HAUPTMENUE := "res://ui/scenes/hauptmenue.tscn"
const SZENE_UEBERGANG := "res://ui/scenes/uebergang.tscn"

var _model := Welt_Model.new()
var _registry := Welt_GeneratorRegistry.new()
var _biome := Welt_BiomRegistry.new()
var _netzwerk_planer := Welt_NetzwerkPlaner.new()
## Die Makrokarte hat ihre eigene Domäne: Sie plant nur Regionen und ruft
## niemals den lokalen Generator.
var _makro := Welt_MakroGenerator.new()
var _seed_offset: int = 0
var _gewaehlte_region: Vector2i = Vector2i.ZERO
var _basis_seed: int = 0
var _aktueller_seed_wert: int = 0

@onready var _karten_flaeche: Control = %KartenFlaeche
@onready var _info_label: Label = %InfoLabel
@onready var _nachbarn_label: Label = %NachbarnLabel
@onready var _starten_knopf: Button = %StartenKnopf
@onready var _neu_knopf: Button = %NeuKnopf
@onready var _zurueck_knopf: Button = %ZurueckKnopf

func _ready() -> void:
	if WeltSitzung.seed_wunsch != 0:
		_basis_seed = WeltSitzung.seed_wunsch
	else:
		var speicher_leser := Welt_Speicher.new()
		var anzahl := speicher_leser.welt_namen().size()
		var ableitung := Kern_Zufall.abgeleitet_fuer(421337 + anzahl * 1337, anzahl + 1)
		_basis_seed = int(ableitung.naechste_zahl() % 1000000000)
		if _basis_seed == 0:
			_basis_seed = 421337
	_starten_knopf.pressed.connect(_auf_starten)
	_neu_knopf.pressed.connect(_auf_neu_platzieren)
	_zurueck_knopf.pressed.connect(_auf_zurueck)
	_karten_flaeche.draw.connect(_karten_flaeche_zeichnen)
	_karten_flaeche.gui_input.connect(_karten_flaeche_eingabe)
	_welt_planen()
	_details_aktualisieren()

func _welt_planen() -> void:
	var seed_wert := (_basis_seed + _seed_offset * 10007) & 0x7FFFFFFF
	if seed_wert == 0:
		seed_wert = 421337
	_aktueller_seed_wert = seed_wert
	# Makroebene statt lokaler Erzeugung: Die Weltkarte plant nur ihre
	# Regionen. Kein Chunk, kein Objekt, kein Tier — die Weltkarte ist in
	# einem Bruchteil der Zeit da und die lokale Karte bleibt die einzige
	# Stelle mit Inhalt.
	_makro.karte_planen(_model, _registry, seed_wert)
	_netzwerk_planer.netzwerk_planen(_model, _registry, _seed_offset, _biome)
	_gewaehlte_region = _netzwerk_planer.spieler_region()
	_karten_flaeche.queue_redraw()

func _karten_flaeche_zeichnen() -> void:
	if _model == null:
		return
	var reg_x: int = ceili(float(_model.raster_breite) / float(maxi(_model.region_kante, 1)))
	var reg_y: int = ceili(float(_model.raster_hoehe) / float(maxi(_model.region_kante, 1)))
	if reg_x <= 0 or reg_y <= 0:
		return
	var kachel_b: float = _karten_flaeche.size.x / float(reg_x)
	var kachel_h: float = _karten_flaeche.size.y / float(reg_y)

	# 1. Regionen mit Biomfarben zeichnen
	for ry in reg_y:
		for rx in reg_x:
			var region: Dictionary = _model.region_an_kachel(rx * _model.region_kante, ry * _model.region_kante)
			var b_id: String = str(region.get("biom_id", "gemaaessigt"))
			var farbe: Color = Color(0.3, 0.5, 0.2)
			var biom_obj: Welt_BiomBasis = _biome.biom_fuer(b_id)
			if biom_obj != null:
				farbe = Color.from_string(biom_obj.farbe, farbe)
			var r_rect := Rect2(float(rx) * kachel_b, float(ry) * kachel_h, kachel_b, kachel_h)
			_karten_flaeche.draw_rect(r_rect, farbe)
			_karten_flaeche.draw_rect(r_rect, Color(0, 0, 0, 0.3), false, 1.0)
			_barriere_zeichen(r_rect, biom_obj, b_id)

	# 2. Wege zeichnen
	for weg: Dictionary in _netzwerk_planer.wege():
		var v_kachel: Vector2i = weg.get("von", Vector2i.ZERO)
		var n_kachel: Vector2i = weg.get("nach", Vector2i.ZERO)
		var v_pos := Vector2(float(v_kachel.x) / float(_model.raster_breite) * _karten_flaeche.size.x, float(v_kachel.y) / float(_model.raster_hoehe) * _karten_flaeche.size.y)
		var n_pos := Vector2(float(n_kachel.x) / float(_model.raster_breite) * _karten_flaeche.size.x, float(n_kachel.y) / float(_model.raster_hoehe) * _karten_flaeche.size.y)
		var linien_farbe: Color = Color(0.9, 0.8, 0.4, 0.7)
		var breite: float = 2.5
		if str(weg.get("typ", "")) == "hauptweg":
			linien_farbe = Color(1.0, 0.9, 0.2, 0.9)
			breite = 3.5
		_karten_flaeche.draw_line(v_pos, n_pos, linien_farbe, breite)

	# 3. Fraktionen zeichnen
	for f: Welt_Fraktion in _netzwerk_planer.fraktionen():
		var pos := Vector2(float(f.position_kachel.x) / float(_model.raster_breite) * _karten_flaeche.size.x, float(f.position_kachel.y) / float(_model.raster_hoehe) * _karten_flaeche.size.y)
		_karten_flaeche.draw_circle(pos, 12.0, f.farbe)
		_karten_flaeche.draw_circle(pos, 12.0, Color.BLACK, false, 2.0)
		_karten_flaeche.draw_string(ThemeDB.fallback_font, pos + Vector2(-20, 24), f.angezeigter_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color.WHITE)

	# 4. Gewählte Spieler-Startregion hervorheben
	var sp_rect := Rect2(float(_gewaehlte_region.x) * kachel_b, float(_gewaehlte_region.y) * kachel_h, kachel_b, kachel_h)
	_karten_flaeche.draw_rect(sp_rect, Color(1.0, 0.85, 0.0, 0.35))
	_karten_flaeche.draw_rect(sp_rect, Color(1.0, 0.9, 0.1), false, 3.5)
	var sp_zentrum: Vector2 = sp_rect.position + sp_rect.size * 0.5
	_karten_flaeche.draw_circle(sp_zentrum, 8.0, Color(0.2, 0.6, 1.0))
	_karten_flaeche.draw_circle(sp_zentrum, 8.0, Color.WHITE, false, 2.0)
	_karten_flaeche.draw_string(ThemeDB.fallback_font, sp_zentrum + Vector2(-30, -14), "★ Startbereich", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1.0, 0.95, 0.4))

func _barriere_zeichen(rechteck: Rect2, biom_obj: Welt_BiomBasis, biom_id: String) -> void:
	# Sichtbare Sperre: Jede Barriere trägt ihr eigenes Zeichen, damit Gebirge
	# und Ozean schon vor dem Klick als unpassierbar erkennbar sind.
	if biom_obj == null or not biom_obj.barriere:
		return
	var mitte := rechteck.position + rechteck.size * 0.5
	var kante := minf(rechteck.size.x, rechteck.size.y)
	if biom_id == "ozean":
		for lauf in 2:
			var y_linie := mitte.y + (float(lauf) - 0.5) * kante * 0.22
			_karten_flaeche.draw_line(
				Vector2(mitte.x - kante * 0.28, y_linie),
				Vector2(mitte.x + kante * 0.28, y_linie),
				Color(0.85, 0.93, 1.0, 0.75), 2.0)
		return
	var spitze := Vector2(mitte.x, mitte.y - kante * 0.26)
	var links := Vector2(mitte.x - kante * 0.26, mitte.y + kante * 0.18)
	var rechts := Vector2(mitte.x + kante * 0.26, mitte.y + kante * 0.18)
	_karten_flaeche.draw_colored_polygon(PackedVector2Array([spitze, links, rechts]), Color(1.0, 1.0, 1.0, 0.55))

func _karten_flaeche_eingabe(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseButton and ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		var reg_x: int = ceili(float(_model.raster_breite) / float(maxi(_model.region_kante, 1)))
		var reg_y: int = ceili(float(_model.raster_hoehe) / float(maxi(_model.region_kante, 1)))
		if reg_x <= 0 or reg_y <= 0:
			return
		var kachel_b: float = _karten_flaeche.size.x / float(reg_x)
		var kachel_h: float = _karten_flaeche.size.y / float(reg_y)
		var klick_rx: int = clampi(int(ereignis.position.x / kachel_b), 0, reg_x - 1)
		var klick_ry: int = clampi(int(ereignis.position.y / kachel_h), 0, reg_y - 1)
		var gewaehlt := Vector2i(klick_rx, klick_ry)
		# Barriere: Der Klick wird abgewiesen, der bisherige Startbereich bleibt.
		if _netzwerk_planer.ist_barriere_region(_model, gewaehlt):
			return
		_gewaehlte_region = gewaehlt
		_netzwerk_planer.spieler_region_setzen(_gewaehlte_region, _model)
		_karten_flaeche.queue_redraw()
		_details_aktualisieren()

func _details_aktualisieren() -> void:
	var region: Dictionary = _model.region_an_kachel(_gewaehlte_region.x * _model.region_kante, _gewaehlte_region.y * _model.region_kante)
	var biom_id: String = str(region.get("biom_id", "gemaaessigt"))
	var biom_obj: Welt_BiomBasis = _biome.biom_fuer(biom_id)
	var biom_name: String = biom_obj.biom_name if biom_obj != null else biom_id.capitalize()

	_info_label.text = "Region: [%d, %d]\nBiom: %s\nCharakter: %s" % [
		_gewaehlte_region.x,
		_gewaehlte_region.y,
		biom_name,
		_biom_charakter_text(biom_id)
	]

	var nachbarn: Array[String] = _netzwerk_planer.nachbarn_fuer("spieler")
	var nachbarn_texte: Array[String] = []
	for n_id in nachbarn:
		for f in _netzwerk_planer.fraktionen():
			if f.fraktion_id == n_id:
				nachbarn_texte.append("%s (%s)" % [f.angezeigter_name, ", ".join(f.bevorzugte_biome)])
	if nachbarn_texte.is_empty():
		_nachbarn_label.text = "Direkte Nachbarn: Keine (isoliert)"
	else:
		_nachbarn_label.text = "Direkte Nachbarn (%d):\n• %s" % [nachbarn_texte.size(), "\n• ".join(nachbarn_texte)]

func _biom_charakter_text(biom_id: String) -> String:
	match biom_id:
		"gemaaessigt":
			return "Dichte Wälder, reiche Beerensträucher und milde Temperaturen."
		"tundra":
			return "Kaltes Ödland mit Bären, Eisbären und kargen Ressourcen."
		"steppe":
			return "Weite Ebenen mit schnellen Hasen und freiem Bauland."
		_:
			return "Ausgewogene Landschaft."

func _auf_neu_platzieren() -> void:
	_seed_offset += 1
	_welt_planen()
	_details_aktualisieren()

func _auf_starten() -> void:
	var region: Dictionary = _model.region_an_kachel(_gewaehlte_region.x * _model.region_kante, _gewaehlte_region.y * _model.region_kante)
	var biom_id: String = str(region.get("biom_id", "gemaaessigt"))
	WeltSitzung.startbereich_setzen(_gewaehlte_region.x, _gewaehlte_region.y, biom_id)
	WeltSitzung.seed_wunsch = int(region.get("seed", _aktueller_seed_wert))
	WeltSitzung.fraktionen_netzwerk = _netzwerk_planer.nach_array()
	WeltSitzung.uebergang_ziel = SZENE_KARTE
	WeltSitzung.uebergang_text = "Die lokale Spielkarte wird generiert …"
	get_tree().change_scene_to_file(SZENE_UEBERGANG)

func _auf_zurueck() -> void:
	WeltSitzung.uebergang_ziel = SZENE_HAUPTMENUE
	WeltSitzung.uebergang_text = "Zurück zum Hauptmenü …"
	get_tree().change_scene_to_file(SZENE_UEBERGANG)
