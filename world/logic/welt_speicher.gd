extends RefCounted
class_name Welt_Speicher
## Speichert und lädt Welten als JSON-Dateien im Benutzerordner.
## Der Ablageort ist zentral definiert, damit UI und Editor ihn nicht kennen müssen.

## Kategorie daten: gelesene Welt-Wörterbücher; dieses Skript hält keine Feld-Arrays.

## Kategorie logik: Speichern, Laden, Auflisten und Löschen.

const ORDNER_NAME := "welten"

func _ordner() -> String:
	return "user://".path_join(ORDNER_NAME)

func welt_namen() -> Array[String]:
	var namen: Array[String] = []
	var verzeichnis := DirAccess.open(_ordner())
	if verzeichnis == null:
		return namen
	verzeichnis.list_dir_begin()
	var dateiname := verzeichnis.get_next()
	while dateiname != "":
		if not verzeichnis.current_is_dir() and dateiname.ends_with(".json"):
			namen.append(dateiname.trim_suffix(".json"))
		dateiname = verzeichnis.get_next()
	verzeichnis.list_dir_end()
	namen.sort()
	return namen

func speichern(welt_name: String, daten: Dictionary) -> bool:
	if welt_name.strip_edges() == "":
		return false
	DirAccess.make_dir_recursive_absolute(_ordner())
	var pfad := _ordner().path_join(welt_name + ".json")
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	if datei == null:
		return false
	datei.store_string(JSON.stringify(daten, "\t"))
	return true

func laden(welt_name: String) -> Dictionary:
	var pfad := _ordner().path_join(welt_name + ".json")
	if not FileAccess.file_exists(pfad):
		return {}
	var datei := FileAccess.open(pfad, FileAccess.READ)
	var daten: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(daten) != TYPE_DICTIONARY:
		return {}
	return daten

func loeschen(welt_name: String) -> bool:
	var pfad := _ordner().path_join(welt_name + ".json")
	if not FileAccess.file_exists(pfad):
		return false
	DirAccess.remove_absolute(pfad)
	return true
