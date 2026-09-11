extends VBoxContainer
class_name Ui_DebugPanelSzene
## Debug-Fenster: das einzige Panel, das Einheit- und Tierzustand beisammen
## hält und ein- oder ausblendet. Es ist standardmäßig unsichtbar und wird
## ausschließlich über den Debug-Schalter des Eingabe-Übersetzers (F3)
## sichtbar. Es besitzt keine Spiellogik, keinen Zustand und keine eigenen
## Zahlen; es komponiert nur die zwei Beobachter-Szenen und reicht ihre
## Quellen durch.
## Kette: F3 -> Ui_EingabeSteuerung.debug_umgeschaltet -> dieses Fenster.

const EINHEIT_PANEL_SZENE := preload("res://ui/scenes/panels/einheit_panel.tscn")
const TIER_PANEL_SZENE := preload("res://ui/scenes/panels/tier_panel.tscn")

## Kategorie daten: die zwei komponierten Beobachter.
var einheit_panel: Control = null
var tier_panel: Control = null

## Kategorie logik: Komposition und Sichtbarkeit.

func einrichten(auswahl: Ui_AuswahlManager, einheiten: Einheit_Manager, tiere: Tier_Manager) -> void:
	# Godot-komponiert: PackedScene -> instantiate -> add_child, damit _ready
	# und @onready der Panels laufen. Die Quellen kommen von außen; dieses
	# Fenster kennt weder Auswahl noch Manager selbst.
	var kopf := Label.new()
	kopf.name = "DebugKopf"
	kopf.text = "Debug (F3): Einheit und Tierbestand"
	add_child(kopf)
	einheit_panel = EINHEIT_PANEL_SZENE.instantiate()
	einheit_panel.name = "EinheitPanel"
	if einheit_panel.has_method("einrichten"):
		einheit_panel.call("einrichten", auswahl, einheiten)
	add_child(einheit_panel)
	tier_panel = TIER_PANEL_SZENE.instantiate()
	tier_panel.name = "TierPanel"
	if tier_panel.has_method("einrichten"):
		tier_panel.call("einrichten", tiere)
	add_child(tier_panel)

func sichtbar_setzen(sichtbar: bool) -> void:
	# Einzige Schreibstelle der Sichtbarkeit: Der Schalter aus der Eingabe
	# entscheidet, dieses Fenster gehorcht nur.
	visible = sichtbar

func ist_sichtbar() -> bool:
	return visible
