extends Node2D
class_name Welt_FeedbackManager
## Manager des sichtbaren Feedbacks (Job-Ernte, Schaden, Tod). Er hängt direkt
## an der Prototyp-Karte bzw. am Renderer-Root und erzeugt pro Ereignis
## eine schwebende Anzeige mit Icon am Ziel-Objekt.
## Abonniert globale Signale vom Kern_SignalBus.

## Kategorie daten: Ressourcen-Icons und Ebene der Anzeigen.
var _ressourcen: Einheit_Ressourcen = null
var _ebene: Node2D = null

## Kategorie logik: Einrichten, Anzeigen und Signal-Handling.

func einrichten(ressourcen: Einheit_Ressourcen) -> void:
	_ressourcen = ressourcen

func _ready() -> void:
	_ebene = Node2D.new()
	_ebene.name = "FeedbackEbene"
	_ebene.z_index = 100
	add_child(_ebene)
	Kern_SignalBus.schaden_erhalten.connect(_auf_schaden_erhalten)
	Kern_SignalBus.gestorben.connect(_auf_gestorben)

func _exit_tree() -> void:
	Kern_SignalBus.schaden_erhalten.disconnect(_auf_schaden_erhalten)
	Kern_SignalBus.gestorben.disconnect(_auf_gestorben)

func zeige_ernte(welt_position: Vector2, ressource: String, menge: int) -> void:
	if menge <= 0:
		return
	var icon := ""
	if _ressourcen != null:
		icon = _ressourcen.icon_pfad(ressource)
	var anzeige := Welt_PlusAnzeige.new()
	anzeige.einrichten(ressource, menge, icon, welt_position)
	_ebene.add_child(anzeige)

func zeige_schaden(welt_position: Vector2, schaden: int, art: String) -> void:
	if schaden <= 0:
		return
	var anzeige := Welt_SchadenAnzeige.new()
	anzeige.einrichten(schaden, art, welt_position)
	_ebene.add_child(anzeige)

func zeige_tod(welt_position: Vector2, typ: String, war_einheit: bool) -> void:
	var anzeige := Welt_TodAnzeige.new()
	anzeige.einrichten(typ, war_einheit, welt_position)
	_ebene.add_child(anzeige)

func _auf_schaden_erhalten(position: Vector2, schaden: int, art: String) -> void:
	zeige_schaden(position, schaden, art)

func _auf_gestorben(position: Vector2, typ: String, war_einheit: bool) -> void:
	zeige_tod(position, typ, war_einheit)