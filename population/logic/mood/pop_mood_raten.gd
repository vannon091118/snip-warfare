extends RefCounted
class_name Pop_MoodRaten
## Raten-Rechner der Stimmung: Jede Need-Rate läuft über den eigenen
## Modifikator-Faktor im Bereich Need mal die Multiplikatoren des
## Rassen-Schemas. Eigene Zahlen erfindet er nicht, Übergänge rechnet er
## nicht; er liefert nur Dringlichkeit, Abfall, Schwellwert und die beiden
## Faktoren für Nahrung und Bewegung.

var _modifikatoren := Kern_ModifikatorMaschine.new()

func _init() -> void:
	# Eigene Modifikator-Maschine mit Bereich Need: Der zentrale Faktor
	# skaliert die Need-Raten; die Rassen-Multiplikatoren kommen vom Schema.
	_modifikatoren.bereich_setzen("need")
	_modifikatoren.aktualisieren()

func dringlichkeit(typ: Pop_NeedBasis, schema: Pop_RassenSchema) -> float:
	var schema_faktor := schema.faktor_dringlichkeit if schema != null else 1.0
	return maxf(typ.dringlichkeit_pro_tick * schema_faktor * _modifikatoren.faktor(), 0.0)

func abfall(typ: Pop_NeedBasis, schema: Pop_RassenSchema) -> float:
	var schema_faktor := schema.faktor_abfall if schema != null else 1.0
	return maxf(typ.abfall_pro_tick * schema_faktor * _modifikatoren.faktor(), 0.0)

func schwellwert(typ: Pop_NeedBasis, schema: Pop_RassenSchema) -> int:
	var schema_faktor := schema.faktor_schwellwert if schema != null else 1.0
	return maxi(int(round(float(typ.schwellwert) * schema_faktor)), 0)

func nahrung(schema: Pop_RassenSchema) -> float:
	# Kombinierter Verbrauchsfaktor je Rasse: Schema mal zentraler Faktor.
	var schema_faktor := schema.faktor_nahrung if schema != null else 1.0
	return maxf(schema_faktor * _modifikatoren.faktor(), 0.1)

func bewegung(schema: Pop_RassenSchema) -> float:
	# Rassen-Multiplikator für die Bewegung der Einheit.
	return schema.faktor_bewegung if schema != null else 1.0
