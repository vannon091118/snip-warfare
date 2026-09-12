extends RefCounted
class_name Welt_UiAufbau
## UI-Aufbau-Spitze der Welt-Szene: Baut die Fenster-Panels und die Karten-
## Ebene als modulare Control-Spitzen und verwaltet die Lager-Darsteller.
## Die Szene hängt nur diese Spitze an und liest die gebauten Referenzen;
## kein Knoten-Bau bleibt mehr in der Szene selbst.

const _DebugPanelSkript := preload("res://ui/scenes/hud/hud_debug_panel.gd")
const _BauPanelSzene := preload("res://ui/scenes/panels/bau_panel.tscn")
const _PopEinheitUebersetzerSkript := preload("res://ui/logic/kategorie_ui/ui_pop_einheit_uebersetzer.gd")
const _PopEinheitPanelSzene := preload("res://ui/scenes/panels/pop_einheit_panel.tscn")

## Kategorie daten: Gebaute Referenzen und Darsteller-Verwaltung.
var karten_ebene: CanvasLayer = null
var karten_viewer: Ui_KartenViewer = null
var karten_info: Ui_WeltInfo = null
var debug_panel: Control = null
var bau_panel: Ui_BauPanelSzene = null
var pop_einheit_panel: Control = null
var pop_einheit_uebersetzer: Ui_PopEinheitUebersetzer = null
var _lager_darsteller_eltern: Node = null

## Kategorie logik: Aufbau und Pflege der UI-Knoten.

func karten_ebene_bauen(eltern: Node, model: Welt_Model, registry: Welt_Registry, biome: Welt_BiomRegistry) -> void:
	# Komponier-Schritt: reine Observer-Schicht als CanvasLayer.
	_lager_darsteller_eltern = eltern
	karten_ebene = CanvasLayer.new()
	karten_ebene.layer = 30
	karten_ebene.visible = false
	var hintergrund := ColorRect.new()
	hintergrund.color = Color(0, 0, 0, 0.55)
	hintergrund.set_anchors_preset(Control.PRESET_FULL_RECT)
	karten_ebene.add_child(hintergrund)
	karten_viewer = Ui_KartenViewer.new()
	karten_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	karten_viewer.offset_left = 80.0
	karten_viewer.offset_top = 60.0
	karten_viewer.offset_right = -80.0
	karten_viewer.offset_bottom = -120.0
	karten_ebene.add_child(karten_viewer)
	var info := Ui_WeltInfo.new()
	info.position = Vector2(90, 20)
	karten_ebene.add_child(info)
	karten_viewer.einrichten(model, registry, biome)
	eltern.add_child(karten_ebene)
	karten_info = info

func debug_panel_bauen(canvas: CanvasLayer, auswahl: Ui_AuswahlManager, stockmaenner: Einheit_Manager, tiere: Tier_Manager) -> void:
	# Debug-Fenster als eigener Knoten unter der UI-Ebene. Es ist standardmäßig
	# unsichtbar; nur der Debug-Schalter (F3) macht es sichtbar.
	if canvas == null:
		return
	debug_panel = _DebugPanelSkript.new()
	debug_panel.name = "DebugPanel"
	debug_panel.visible = false
	debug_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	debug_panel.offset_left = -420.0
	debug_panel.offset_top = 96.0
	debug_panel.custom_minimum_size = Vector2(408, 0)
	debug_panel.call("einrichten", auswahl, stockmaenner, tiere)
	canvas.add_child(debug_panel)

func bau_panel_bauen(canvas: CanvasLayer, definitionen: Gebaeude_DefinitionRegistry, fortschritt: Welt_FortschrittsMaschine, steuerung: Kern_SteuerungRegistry, empfaenger: Callable) -> void:
	if canvas == null:
		return
	bau_panel = _BauPanelSzene.instantiate()
	bau_panel.name = "BauPanel"
	bau_panel.einrichten(definitionen, fortschritt, steuerung)
	bau_panel.bau_gewaehlt.connect(empfaenger)
	canvas.add_child(bau_panel)

func pop_einheit_panel_bauen(canvas: CanvasLayer, need_baum: Pop_NeedBaum, stockmaenner: Einheit_Manager, ressourcen: Einheit_Ressourcen) -> void:
	if canvas == null:
		return
	pop_einheit_uebersetzer = _PopEinheitUebersetzerSkript.new()
	pop_einheit_uebersetzer.einrichten(need_baum, stockmaenner, ressourcen)
	pop_einheit_panel = _PopEinheitPanelSzene.instantiate()
	pop_einheit_panel.name = "PopEinheitPanel"
	pop_einheit_panel.einrichten(pop_einheit_uebersetzer)
	canvas.add_child(pop_einheit_panel)

func debug_panel_sichtbar_setzen(sichtbar: bool) -> void:
	# Der einzige Sichtbarkeits-Weg des Debug-Fensters; die Szene reicht
	# nur den Signal-Wert durch.
	if debug_panel != null:
		debug_panel.call("sichtbar_setzen", sichtbar)

func lager_darsteller_einrichten(lager: Lager_Manager, ressourcen: Einheit_Ressourcen) -> void:
	# Alte Darsteller entfernen
	if _lager_darsteller_eltern == null:
		return
	for kind in _lager_darsteller_eltern.get_children():
		if kind.name.begins_with("LagerDarsteller_"):
			kind.queue_free()
	# Erstellt einen Lager_Darsteller für jedes Lager und hängt ihn an die Szene
	for idx in lager.lager_zahl():
		var darsteller := Lager_Darsteller.new()
		darsteller.name = "LagerDarsteller_%d" % idx
		darsteller.lager_index_setzen(idx)
		darsteller.lager_manager_setzen(lager)
		darsteller.ressourcen_setzen(ressourcen)
		# Position auf Lager-Kachel setzen
		darsteller.position = lager.lager_position(idx)
		_lager_darsteller_eltern.add_child(darsteller)
