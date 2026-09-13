extends Node2D
class_name Lager_Darsteller
## Observer für Lager-Bestände: Hört auf den Signalbus (lager_geaendert)
## und lässt den Stapel-Bauer die Resource-Sprites auf der Lager-Kachel
## zeichnen. Maximal 5 Icons pro Ressourcentyp, dann Zahl daneben. Genau
## eine Verantwortung: Lauschen, filtern, weiterleiten.

@export var lager_index: int = -1
var lager_manager: Lager_Manager = null
var ressourcen: Einheit_Ressourcen = null

var _bus: Kern_SignalBus = null
var _stapel: Lager_StapelBauer = null

func _ready() -> void:
	_bus = Kern_SignalBus.bus()
	if _bus != null:
		_bus.lager_geaendert.connect(_auf_lager_geaendert)
	var container := Node2D.new()
	container.name = "LagerInhalt"
	add_child(container)
	_stapel = Lager_StapelBauer.new(container)
	_anzeige_aktualisieren()

func _exit_tree() -> void:
	if _bus != null and _bus.has_signal("lager_geaendert"):
		_bus.lager_geaendert.disconnect(_auf_lager_geaendert)

func _auf_lager_geaendert(lager_id: String) -> void:
	# Nur reagieren, wenn es unser Lager betrifft
	if lager_id == "lager_%d" % lager_index:
		_anzeige_aktualisieren()

func lager_index_setzen(idx: int) -> void:
	lager_index = idx

func lager_manager_setzen(mgr: Lager_Manager) -> void:
	lager_manager = mgr

func ressourcen_setzen(res: Einheit_Ressourcen) -> void:
	ressourcen = res

func _anzeige_aktualisieren() -> void:
	if _stapel == null:
		return
	if lager_manager == null or lager_index < 0 or lager_index >= lager_manager.lager_zahl() or ressourcen == null:
		_stapel.alles_entfernen()
		return
	var bestaende: Dictionary = lager_manager.bestaende_im_lager(lager_index)
	if bestaende.is_empty():
		_stapel.alles_entfernen()
		return
	for ressource_id: String in bestaende:
		_stapel.anzeigen_aktualisieren(ressource_id, int(bestaende[ressource_id]), ressourcen.icon_pfad(ressource_id))
	# Ressourcen entfernen, die nicht mehr im Bestand sind
	var aktuelle_ids: Array = bestaende.keys()
	for rid: String in _stapel.aktuelle_ressourcen():
		if not aktuelle_ids.has(rid):
			_stapel.ressource_entfernen(rid)
