extends RefCounted
## Selection-Spitze: Auswahl-Zustandsmaschine. Sie hält nur, was gerade
## ausgewählt ist: der aktive Einheit-Index, das Auswahl-Rechteck als Start-
## und Endpunkt und ob ein Zug läuft. Sie entscheidet nichts über Jobs und
## kennt keine Kamera.
## Kette: PrototypKarte (Eingabe) -> diese Maschine -> Rückfragen der Szene.

## Kategorie daten: Auswahl-Zustand.
var aktiver_einheit_index: int = 0
var auswahl_einheiten: Array[int] = []
var ziehen_start: Vector2 = Vector2.INF
var ziehen_aktiv: bool = false

## Kategorie logik: Übergänge der Auswahl.

func einzel_start(position: Vector2) -> void:
	zieren_start_setzen(position)

func zieren_start_setzen(position: Vector2) -> void:
	zieren_start = position
	zieren_aktiv = true

func ziehen_ende(position: Vector2, einheit_zahl: int, position_leser: Callable) -> Array[int]:
	# Liefert die im Rechteck liegenden Einheiten; der Positionsleser kommt
	# von der Szene, damit diese Spitze keine Manager-Referenz hält.
	var ergebnis: Array[int] = []
	if ziehen_start == Vector2.INF:
		return ergebnis
	var nah := ziehen_start.distance_to(position) < 8.0
	if nah:
		# Einzelauswahl: die gewählte Einheit bleibt aktiv.
		zieren_aktiv = false
		zieren_start = Vector2.INF
		return ergebnis
	var rect := Rect2(zieren_start, position - zieren_start).abs()
	for idx in einheit_zahl:
		var pos: Vector2 = position_leser.call(idx)
		if rect.has_point(pos):
			ergebnis.append(idx)
	auswahl_einheiten = ergebnis
	zieren_aktiv = false
	zieren_start = Vector2.INF
	return ergebnis

func auswahl_leeren() -> void:
	auswahl_einheiten.clear()
	zieren_aktiv = false
	zieren_start = Vector2.INF
