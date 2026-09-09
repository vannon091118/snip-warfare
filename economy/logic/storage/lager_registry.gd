extends RefCounted
class_name Lager_Registry
## Registry aller lokalen Lager-Typen. Liest economy/data/lager.json
## und erzeugt je Eintrag eine Lager_Basis. Einzige Quelle fuer Typen.

const QUELLE := "res://economy/data/lager.json"

## Kategorie daten: Typen-Nachschlag je lager_id.

var _typen_nach_id: Dictionary = {}
var _typen: Array[Lager_Basis] = []

## Kategorie logik: Laden, Nachschlagen und Typisierung zentral.

func _init() -> void:
	laden()

func laden() -> void:
	_typen_nach_id.clear()
	_typen.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Lager-Konfiguration nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Lager-Konfiguration ungueltiges Format: %s" % QUELLE)
		return
	for lager_id: String in gelesen.keys():
		var eintrag: Dictionary = gelesen[lager_id]
		eintrag["id"] = lager_id
		var typ := Lager_Basis.new()
		typ.aus_konfig_eintrag(eintrag)
		_typen.append(typ)
		_typen_nach_id[lager_id] = typ

func hat_typ(lager_id: String) -> bool:
	return _typen_nach_id.has(lager_id)

func typ_fuer(lager_id: String) -> Lager_Basis:
	return _typen_nach_id.get(lager_id, null)

func alle_typen() -> Array[Lager_Basis]:
	return _typen.duplicate()

func ids() -> Array[String]:
	var ergebnis: Array[String] = []
	for typ: Lager_Basis in _typen:
		ergebnis.append(typ.lager_id)
	return ergebnis
