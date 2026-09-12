extends Node2D
class_name Lager_Darsteller
## Observer für Lager-Bestände: Hört auf den Signalbus (lager_geaendert)
## und rendert gestapelte Resource-Sprites auf der Lager-Kachel.
## Maximal 5 Icons pro Ressourcentyp, dann Zahl daneben.

@export var lager_index: int = -1
var lager_manager: Lager_Manager = null
var ressourcen: Einheit_Ressourcen = null

var _bus: Kern_SignalBus = null
var _sprite_container: Node2D = null
var _ressource_sprites: Dictionary = {}  # ressource_id -> Array[Sprite2D]
var _anzahl_labels: Dictionary = {}      # ressource_id -> Label
var _max_icons: int = 5
var _icon_abstand: float = 18.0
var _stapel_versatz: Vector2 = Vector2(0, -24.0)

func _ready() -> void:
	_bus = Kern_SignalBus.bus()
	if _bus != null:
		_bus.lager_geaendert.connect(_auf_lager_geaendert)

	# Container für Sprites erstellen
	_sprite_container = Node2D.new()
	_sprite_container.name = "LagerInhalt"
	add_child(_sprite_container)

	# Initiale Anzeige aufbauen
	_anzeige_aktualisieren()

func _exit_tree() -> void:
	if _bus != null and _bus.has_signal("lager_geaendert"):
		_bus.lager_geaendert.disconnect(_auf_lager_geaendert)

func _auf_lager_geaendert(lager_id: String) -> void:
	# Nur reagieren, wenn es unser Lager betrifft
	var erwartete_id := "lager_%d" % lager_index
	if lager_id == erwartete_id:
		_anzeige_aktualisieren()

func lager_index_setzen(idx: int) -> void:
	lager_index = idx

func lager_manager_setzen(mgr: Lager_Manager) -> void:
	lager_manager = mgr

func ressourcen_setzen(res: Einheit_Ressourcen) -> void:
	ressourcen = res

func _anzeige_aktualisieren() -> void:
	if lager_manager == null or lager_index < 0 or lager_index >= lager_manager.lager_zahl():
		_alle_sprites_entfernen()
		return

	if ressourcen == null:
		_alle_sprites_entfernen()
		return

	var bestaende: Dictionary = lager_manager.bestaende_im_lager(lager_index)
	if bestaende.is_empty():
		_alle_sprites_entfernen()
		return

	# Für jede Ressource Sprites rendern
	for ressource_id: String in bestaende:
		var menge: int = int(bestaende[ressource_id])
		if menge <= 0:
			_ressource_entfernen(ressource_id)
			continue
		_ressource_rendern(ressource_id, menge)

	# Ressourcen entfernen, die nicht mehr im Bestand sind
	var aktuelle_ids: Array = bestaende.keys()
	var zu_entfernen: Array[String] = []
	for rid: String in _ressource_sprites.keys():
		if not aktuelle_ids.has(rid):
			zu_entfernen.append(rid)
	for rid: String in zu_entfernen:
		_ressource_entfernen(rid)

func _ressource_rendern(ressource_id: String, menge: int) -> void:
	var icon_pfad := ""
	if ressourcen != null:
		icon_pfad = ressourcen.icon_pfad(ressource_id)
	if icon_pfad == "" or not ResourceLoader.exists(icon_pfad):
		return

	var textur: Texture2D = load(icon_pfad)
	if textur == null:
		return

	# Bestehende Sprites für diese Ressource holen oder erstellen
	var sprites: Array[Sprite2D] = _ressource_sprites.get(ressource_id, []) as Array[Sprite2D]
	var label: Label = _anzahl_labels.get(ressource_id, null) as Label

	# Gewünschte Anzahl Icons (max 5)
	var anzahl_icons: int = mini(menge, _max_icons)

	# Sprites anpassen: hinzufügen oder entfernen
	while sprites.size() < anzahl_icons:
		var sprite := Sprite2D.new()
		sprite.texture = textur
		sprite.scale = Vector2(0.5, 0.5)  # Kleiner für Stapel
		_sprite_container.add_child(sprite)
		sprites.append(sprite)

	while sprites.size() > anzahl_icons:
		var entfernte_flaeche: Sprite2D = sprites.pop_back()
		entfernte_flaeche.queue_free()

	# Positionen der Sprites setzen (gestapelt)
	var start_x: float = -((anzahl_icons - 1) * _icon_abstand) * 0.5
	for i in range(anzahl_icons):
		var stappel_flaeche: Sprite2D = sprites[i]
		stappel_flaeche.position = Vector2(start_x + i * _icon_abstand, _stapel_versatz.y)
		stappel_flaeche.z_index = i  # Stapel-Reihenfolge

	# Label für Anzahl (wenn > 5 oder generell zur Anzeige)
	if label == null:
		label = Label.new()
		label.name = "Anzahl_%s" % ressource_id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
		_sprite_container.add_child(label)
		_anzahl_labels[ressource_id] = label

	if menge > _max_icons:
		label.text = "x%d" % menge
		label.position = Vector2(start_x + anzahl_icons * _icon_abstand + 12.0, _stapel_versatz.y - 4.0)
		label.visible = true
	else:
		label.visible = false

	_ressource_sprites[ressource_id] = sprites

func _ressource_entfernen(ressource_id: String) -> void:
	var sprites: Array[Sprite2D] = _ressource_sprites.get(ressource_id, []) as Array[Sprite2D]
	for sprite: Sprite2D in sprites:
		if sprite.is_inside_tree():
			sprite.queue_free()
	_ressource_sprites.erase(ressource_id)

	var label: Label = _anzahl_labels.get(ressource_id, null) as Label
	if label != null and label.is_inside_tree():
		label.queue_free()
	_anzahl_labels.erase(ressource_id)

func _alle_sprites_entfernen() -> void:
	for sprites: Array[Sprite2D] in _ressource_sprites.values() as Array[Array]:
		for sprite: Sprite2D in sprites:
			if sprite.is_inside_tree():
				sprite.queue_free()
	_ressource_sprites.clear()

	for label: Label in _anzahl_labels.values() as Array[Label]:
		if label.is_inside_tree():
			label.queue_free()
	_anzahl_labels.clear()
