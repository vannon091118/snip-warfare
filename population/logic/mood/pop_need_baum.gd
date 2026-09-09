extends Node
class_name Pop_NeedBaum
## Eigener Tree der Bedürfnis-Domäne. Er ist der Node-Anker, unter dem alle
## Need-Maschinen als eigene Kinder hängen (je Einheit eine Pop_MoodMaschine)
## und hält die Registries der Domäne: Need-Typen und Rassen-Schemata.
## Der Baum tickt nicht selbst: Der Tick-Fluss bleibt beim Einheit_Manager,
## der die Maschinen über Referenzen anspricht; dieser Baum sorgt nur für
## Struktur, Schema-Zuordnung und Erzeugung. Keine Darstellung, keine Zeit.

## Kategorie daten: Registries der Domäne und Zähler der Kinder.
var _need_registry := Pop_NeedRegistry.new()
var _rassen_registry := Pop_RassenSchemaRegistry.new()
var _naechste_kind_nummer: int = 1

## Kategorie logik: Schema-Abfragen und Erzeugung der Kind-Maschinen.

func rassen_schema(rasse_id: String) -> Pop_RassenSchema:
	return _rassen_registry.schema_fuer(rasse_id)

func standard_rasse() -> String:
	return _rassen_registry.standard_rasse()

func hat_rasse(rasse_id: String) -> bool:
	return _rassen_registry.hat_schema(rasse_id)

func nahrungs_faktor_fuer(rasse_id: String) -> float:
	var schema := rassen_schema(rasse_id)
	if schema == null:
		return 1.0
	return schema.faktor_nahrung

func bewegungs_faktor_fuer(rasse_id: String) -> float:
	var schema := rassen_schema(rasse_id)
	if schema == null:
		return 1.0
	return schema.faktor_bewegung

func einheit_need_anlegen(rasse_id: String, welt_position: Vector2) -> Pop_MoodMaschine:
	# Erzeugt die eigene Need-Maschine der Einheit als Kind dieses Baums
	# und weist ihr das Rassen-Schema zu. Die Maschine tickt weiterhin über
	# den Einheit_Manager; dieser Baum bleibt ihr struktureller Besitzer.
	var maschine := Pop_MoodMaschine.new()
	maschine.name = "NeedMaschine_%d" % _naechste_kind_nummer
	_naechste_kind_nummer += 1
	maschine.einrichten(_need_registry, null)
	maschine.rassen_schema_setzen(rassen_schema(rasse_id))
	maschine.welt_position_setzen(welt_position)
	add_child(maschine)
	return maschine