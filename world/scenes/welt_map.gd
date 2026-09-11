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
var _seed_offset: int = 0
var _gewaehlte_region := Vector2i.ZERO
var _biom_name_karte: Dictionary = {}

@onready var _karten_flaeche: Control = %KartenFlaeche
@onready var _info_label: Label = %InfoLabel
@onready var _nachbarn_label: Label = %NachbarnLabel
@onready var _starten_knopf: Button = %StartenKnopf
@onready var _neu_knopf: Button = %NeuKnopf
@onready var _zurueck_knopf: Button = %ZurueckKnopf

func _ready() -> void:
	_starten_knopf.pressed.connect(_auf_starten)
	_neu_knopf.pressed.connect(_auf_neu_platzieren)
	_zurueck_knopf.pressed.connect(_auf_zurueck)
	_karten_flaeche.draw.connect(_karten_flaeche_zeichnen)
	_karten_flaeche.gui_input.connect(_karten_flaeche_eingabe)
	_welt_planen()
	_details_aktualisieren()

func _welt_planen() -> void:
	var seed_wert := WeltSitzung.seed_wunsch
	if seed_wert == 0:
		seed_wert = int(hash("world_map_%d" % _seed_offset) & 0x7FFFFFFF)
		if seed_wert == 0:
			seed_wert = 421337
	var def_reg := Welt_DefinitionRegistry.new()
	def_reg.laden()
	var groesse := def_reg.max_karten_groesse()
	_model.karte_erzeugen(groesse.x, groesse.y, "boden")
	_model.welt_seed = seed_wert
	var generator := Welt_Generator.new()
	generator.welt_erzeugen(_model, seed_wert, "gemaaessigt")
	_netzwerk_planer.netzwerk_planen(_model, _registry, _seed_offset)
	_gewaehlte_region = _netzwerk_planer.spieler_region()
	_karten_flaeche.queue_redraw()

func _karten_flaeche_zeichnen() -> void:
	if _model == null:
		return
	var reg_x := ceili(float(_model.raster_breite) / float(maxi(_model.region_kante, 1)))
	var reg_y := ceili(float(_model.raster_hoehe) / float(maxi(_model.region_kante, 1)))
	if reg_x <= 0 or reg_y <= 0:
		return
	var kachel_b := _karten_flaeche.size.x / float(reg_x)
	var kachel_h := _karten_flaeche.size.y / float(reg_y)

	# 1. Regionen mit Biomfarben zeichnen
	for ry in reg_y:
		for rx in reg_x:
			var region := _model.region_an_kachel(rx * _model.region_kante, ry * _model.region_kante)
			var b_id := str(region.get("biom_id", "gemaaessigt"))
			var farbe := Color(0.3, 0.5, 0.2)
			var biom_obj := _biome.biom_fuer(b_id)
			if biom_obj != null:
				farbe = Color.from_string(biom_obj.farbe, farbe)
			var r_rect := Rect2(rx * kachel_b, ry * kachel_h, kachel_b, kachel_h)
			_karten_flaeche.draw_rect(r_rect, farbe)
			_karten_flaeche.draw_rect(r_rect, Color(0, 0, 0, 0.3), false, 1.0)

	# 2. Wege zeichnen
	for weg in _netzwerk_planer.wege():
		var v_kachel: Vector2i = weg.get("von", Vector2i.ZERO)
		var n_kachel: Vector2i = weg.get("nach", Vector2i.ZERO)
		var v_pos := Vector2(float(v_kachel.x) / float(_model.raster_breite) * _karten_flaeche.size.x, float(v_kachel.y) / float(_model.raster_hoehe) * _karten_flaeche.size.y)
		var n_pos := Vector2(float(n_kachel.x) / float(_model.raster_breite) * _karten_flaeche.size.x, float(n_kachel.y) / float(_model.raster_hoehe) * _karten_flaeche.size.y)
		var linien_farbe := Color(0.9, 0.8, 0.4, 0.7)
		var breite := 2.5
		if str(weg.get("typ", "")) == "hauptweg":
			linien_farbe = Color(1.0, 0.9, 0.2, 0.9)
			breite = 3.5
		_karten_flaeche.draw_line(v_pos, n_pos, linien_farbe, breite)

	# 3. Fraktionen zeichnen
	for f in _netzwerk_planer.fraktionen():
		var pos := Vector2(float(f.position_kachel.x) / float(_model.raster_breite) * _karten_flaeche.size.x, float(f.position_kachel.y) / float(_model.raster_hoehe) * _karten_flaeche.size.y)
		_karten_flaeche.draw_circle(pos, 12.0, f.farbe)
		_karten_flaeche.draw_circle(pos, 12.0, Color.BLACK, false, 2.0)
		_karten_flaeche.draw_string(ThemeDB.fallback_font, pos + Vector2(-20, 24), f.angezeigter_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color.WHITE)

	# 4. Gewählte Spieler-Startregion hervorheben
	var sp_rect := Rect2(_gewaehlte_region.x * kachel_b, _gewaehlte_region.y * kachel_h, kachel_b, kachel_h)
	_karten_flaeche.draw_rect(sp_rect, Color(1.0, 0.85, 0.0, 0.35))
	_karten_flaeche.draw_rect(sp_rect, Color(1.0, 0.9, 0.1), false, 3.5)
	var sp_zentrum := sp_rect.position + sp_rect.size * 0.5
	_karten_flaeche.draw_circle(sp_zentrum, 8.0, Color(0.2, 0.6, 1.0))
	_karten_flaeche.draw_circle(sp_zentrum, 8.0, Color.WHITE, false, 2.0)
	_karten_flaeche.draw_string(ThemeDB.fallback_font, sp_zentrum + Vector2(-30, -14), "★ Startbereich", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1.0, 0.95, 0.4))

func _karten_flaeche_eingabe(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseButton and ereignis.pressed and ereignis.button_index == MOUSE_BUTTON_LEFT:
		var reg_x := ceili(float(_model.raster_breite) / float(maxi(_model.region_kante, 1)))
		var reg_y := ceili(float(_model.raster_hoehe) / float(maxi(_model.region_kante, 1)))
		if reg_x <= 0 or reg_y <= 0:
			return
		var kachel_b := _karten_flaeche.size.x / float(reg_x)
		var kachel_h := _karten_flaeche.size.y / float(reg_y)
		var klick_rx := clampi(int(ereignis.position.x / kachel_b), 0, reg_x - 1)
		var klick_ry := clampi(int(ereignis.position.y / kachel_h), 0, reg_y - 1)
		_gewaehlte_region = Vector2i(klick_rx, klick_ry)
		_netzwerk_planer.spieler_region_setzen(_gewaehlte_region, _model)
		_karten_flaeche.queue_redraw()
		_details_aktualisieren()

func _details_aktualisieren() -> void:
	var region := _model.region_an_kachel(_gewaehlte_region.x * _model.region_kante, _gewaehlte_region.y * _model.region_kante)
	var biom_id := str(region.get("biom_id", "gemaaessigt"))
	var biom_obj := _biome.biom_fuer(biom_id)
	var biom_name := biom_obj.angezeigter_name if biom_obj != null else biom_id.capitalize()

	_info_label.text = "Region: [%d, %d]\nBiom: %s\nCharakter: %s" % [
		_gewaehlte_region.x,
		_gewaehlte_region.y,
		biom_name,
		_biom_charakter_text(biom_id)
	]

	var nachbarn := _netzwerk_planer.nachbarn_fuer("spieler")
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
	var region := _model.region_an_kachel(_gewaehlte_region.x * _model.region_kante, _gewaehlte_region.y * _model.region_kante)
	var biom_id := str(region.get("biom_id", "gemaaessigt"))
	WeltSitzung.startbereich_setzen(_gewaehlte_region.x, _gewaehlte_region.y, biom_id)
	WeltSitzung.fraktionen_netzwerk = _netzwerk_planer.nach_array()
	WeltSitzung.uebergang_ziel = SZENE_KARTE
	WeltSitzung.uebergang_text = "Die lokale Spielkarte wird generiert …"
	get_tree().change_scene_to_file(SZENE_UEBERGANG)

func _auf_zurueck() -> void:
	WeltSitzung.uebergang_ziel = SZENE_HAUPTMENUE
	WeltSitzung.uebergang_text = "Zurück zum Hauptmenü …"
	get_tree().change_scene_to_file(SZENE_UEBERGANG)
