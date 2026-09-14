extends RefCounted
class_name Einheit_VersorgungsMaschine
## Wachstum und Einwanderung der Einheiten-Domäne: Ein Haus aus 3 Nahrung
## erzeugt einen neuen Stickman, und die Einstiegs-Kette macht aus dem
## Wachstum eine automatische Einwanderungs-Kette. Die Rate steht
## menschenlesbar in progression.json je Stufe; ohne aktive einwanderung-
## Stufe kommt niemand. Der Ankömmling meldet sich an die Maschine zurück,
## damit die Stufe weiterzählt. Der Takt bleibt beim Manager; die Regel
## allein wohnt hier.

## Kategorie daten: Quellen des Nachschubs.
var _manager: Einheit_Manager = null
var _ressourcen: Einheit_Ressourcen = null
var _fortschritt: Welt_FortschrittsMaschine = null
var _lager: Lager_Manager = null
## Kategorie daten: Der Ankunftsort-Vertrag aus der Verdrahtung.
var _ankunft: Callable = Callable()

## Kategorie logik: Wachstum und Einwanderung.

func einrichten(p: Dictionary) -> void:
	_manager = p.get("manager")
	_ressourcen = p.get("ressourcen")
	_lager = p.get("lager")
	_fortschritt = p.get("fortschritt")
	_ankunft = p.get("ankunftsort", Callable())

func versuche_wachstum(haus_welt_position: Vector2) -> bool:
	if _ressourcen == null:
		return false
	_ressourcen.ernte_position_setzen(haus_welt_position)
	if not _ressourcen.entnehmen("fleisch", 3):
		return false
	_manager.einheit_hinzufuegen(haus_welt_position + Vector2(0, 20))
	return true

func einwanderung_ticken() -> void:
	## Einwanderung: Pro Verbrauchstakt erscheint je_tag Einwanderer direkt,
	## sofern die aktive Progressions-Stufe den Typ einwanderung trägt.
	## Der frühere Zähler verdoppelte die Wartezeit und ist entfernt worden.
	if _fortschritt == null:
		return
	var stufe := _fortschritt.aktive_stufe()
	if str(stufe.get("ziel_typ", "")) != "einwanderung":
		return
	var je_tag := int(stufe.get("einwanderer_je_tag", 0))
	for _i: int in je_tag:
		# Der Ankunftsort kommt aus dem Manager-Vertrag: Mit Blick der
		# Welt-Szene landet der Ankömmling im Bild, ohne fällt der Anker
		# auf das Lager zurück.
		_manager.einheit_hinzufuegen(_ankunftsort())
		_fortschritt.einwanderer_angekommen()


func _ankunftsort() -> Vector2:
	## Mit Blick-Vertrag landet der Ankömmling im Bild; ohne Vertrag greift
	## der Anker des Lagers, versetzt wie zuvor.
	if _ankunft.is_valid():
		return _ankunft.call()
	return _manager.lager_anker_position() + Vector2(24, 20)
