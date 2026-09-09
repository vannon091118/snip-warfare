extends HBoxContainer
## HUD-Spitze: Ressourcenleiste. Reiner Observer über Einheit_Ressourcen.
## Sie liest nur den Bestand und zeigt ihn an; sie ändert keinen Zustand
## und kennt keine Jobs, keine Welt und keine Kamera.
## Kette: Einheit_Ressourcen.bestand_geaendert -> diese Leiste -> Label-Text.

## Kategorie daten: Zuordnung Ressource -> Zähler-Label.
var _zaehler_nach_ressource: Dictionary = {}

## Kategorie logik: Anzeigen des aktuellen Bestands.

func einrichten(ressourcen: Einheit_Ressourcen) -> void:
	for kind: Node in get_children():
		kind.queue_free()
	_zaehler_nach_ressource.clear()
	for ressource: String in ressourcen.ressource_ids():
		var feld := HBoxContainer.new()
		var icon := TextureRect.new()
		var pfad := ressourcen.icon_pfad(ressource)
		if pfad != "" and ResourceLoader.exists(pfad):
			icon.texture = load(pfad)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var zaehler := Label.new()
		zaehler.text = str(ressourcen.bestand(ressource))
		feld.add_child(icon)
		feld.add_child(zaehler)
		add_child(feld)
		_zaehler_nach_ressource[ressource] = zaehler
	if not ressourcen.bestand_geaendert.is_connected(_auf_bestand):
		ressourcen.bestand_geaendert.connect(_auf_bestand)

func _auf_bestand(ressource: String, neuer_bestand: int) -> void:
	if _zaehler_nach_ressource.has(ressource):
		(_zaehler_nach_ressource[ressource] as Label).text = str(neuer_bestand)
