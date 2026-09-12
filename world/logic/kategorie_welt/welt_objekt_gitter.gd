extends RefCounted
class_name Welt_ObjektGitter
## Räumlicher Vorfilter für den Renderer: teilt Objekt-Positionen in
## gleichförmige Gitterzellen und liefert bei _sichtbar_anwenden() nur
## Kandidaten-Indizes für Zellen, die das Sichtrechteck schneiden.
## Ersetzt den linearen O(n)-Scan über alle Modell-Objekte durch einen
## O(k)-Zugriff (k = Objekte im Sichtbereich).
## Das Gitter kennt keine Knoten, kein Modell-Schreiben, nur Positionen
## und Indizes. Es wird nach Gebäudeplatzierung und Kartenwechsel neu aufgebaut.

## Kategorie daten: Zellgröße und das Positions-Woerterbuch.

const STANDARD_ZELL_GROESSE := 384.0

var _zell_groesse: float = STANDARD_ZELL_GROESSE
## Schlüssel: Vector2i-Zelladresse, Wert: Array[int] mit Objekt-Indizes.
var _zellen: Dictionary = {}

## Kategorie logik: Aufbau und räumliche Abfrage.

func zell_groesse_setzen(groesse: float) -> void:
	_zell_groesse = maxf(groesse, 32.0)

func aufbauen(model: Welt_Model) -> void:
	## Füllt das Gitter aus dem übergebenen Modell. Jede vorherige Belegung
	## wird vollständig geleert. Der Aufbau ist der einzige Schreibpfad.
	_zellen.clear()
	if model == null:
		return
	for i in model.objekt_anzahl():
		var zelle := _zelle_von(model.objekt_position(i))
		if not _zellen.has(zelle):
			_zellen[zelle] = [] as Array[int]
		(_zellen[zelle] as Array[int]).append(i)

func kandidaten_in(rechteck: Rect2) -> Array[int]:
	## Liefert alle Objekt-Indizes aus Gitterzellen, die sich mit dem
	## Sichtrechteck überschneiden. Ein Objekt knapp ausserhalb des
	## Rechtecks kann dabei auftreten (Zell-Granularität), der Renderer
	## prüft die genaue Position selbst.
	var ergebnis: Array[int] = []
	var min_zelle := _zelle_von(rechteck.position)
	var max_zelle := _zelle_von(rechteck.position + rechteck.size)
	for zy in range(min_zelle.y, max_zelle.y + 1):
		for zx in range(min_zelle.x, max_zelle.x + 1):
			var zelle := Vector2i(zx, zy)
			if _zellen.has(zelle):
				ergebnis.append_array(_zellen[zelle] as Array[int])
	return ergebnis

func ungueltig_machen() -> void:
	## Schnelle Invalidierung ohne vollständigen Neuaufbau: Wird nach
	## Gebäudeplatzierung aufgerufen; der Renderer baut danach beim
	## nächsten _sichtbar_anwenden() neu auf.
	_zellen.clear()

func ist_leer() -> bool:
	return _zellen.is_empty()

func _zelle_von(position: Vector2) -> Vector2i:
	## Berechnet die Gitterzelle für eine Weltposition.
	## Negative Koordinaten landen in negativen Zelladressen, die
	## dieselbe Wörterbuch-Mechanik nutzen wie positive.
	return Vector2i(
		floori(position.x / _zell_groesse),
		floori(position.y / _zell_groesse)
	)
