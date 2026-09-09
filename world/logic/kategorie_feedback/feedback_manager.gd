extends Node2D
class_name Welt_FeedbackManager
## Manager des sichtbaren Feedbacks (Job-Ernte). Er hängt direkt
## an der Prototyp-Karte bzw. am Renderer-Root und erzeugt pro Ernte
## eine schwebende +X Anzeige mit Ressourcen-Icon am Ziel-Objekt.
## Aufgerufen wird er über zeige_ernte(position, ressource, menge).

## Kategorie daten: Ressourcen-Icons und Ebene der Anzeigen.
var _ressourcen: Einheit_Ressourcen = null
var _ebene: Node2D = null

## Kategorie logik: Einrichten und Anzeigen.

func einrichten(ressourcen: Einheit_Ressourcen) -> void:
	_ressourcen = ressourcen

func _ready() -> void:
	_ebene = Node2D.new()
	_ebene.name = "FeedbackEbene"
	_ebene.z_index = 100
	add_child(_ebene)

func zeige_ernte(welt_position: Vector2, ressource: String, menge: int) -> void:
	if menge <= 0:
		return
	var icon := ""
	if _ressourcen != null:
		icon = _ressourcen.icon_pfad(ressource)
	var anzeige := Welt_PlusAnzeige.new()
	anzeige.einrichten(ressource, menge, icon, welt_position)
	_ebene.add_child(anzeige)
