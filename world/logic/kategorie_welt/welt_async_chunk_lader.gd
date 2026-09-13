extends RefCounted
class_name Welt_AsyncChunkLader
## Zeitgeslicener Chunk-Lader der Welt-Domäne: Er materialisiert die Karte
## über mehrere Ticks verteilt statt alle Chunks in einem Frame.
## Der 334-Millisekunden-Spike beim Weltstart lag am synchronen Vollbau in
## der Chunk-Schleife des Welt_Generators; dieser Lader zieht die Arbeit
## in 16-Millisekunden-Budgets, gespeist von der Szene an der Weltuhr.
## Der Generator bleibt die einzige Füll-Wahrheit: Der Lader ruft nur
## chunk_fuellen_oeffentlich() desselben Generators, keine zweite Füll-Logik.
## Keine Darstellung, keine Eingabe; Zustand ist nur die Warteschlange.

## Kategorie daten: Warteschlange und Deckel.

## Chunks je Schritt: Der Deckel hält den Frame-Rest ruhig, ohne die
## Wanduhr anzufassen. Die Füllung selbst ist ortsfest deterministisch;
## die Verteilung über mehrere Frames ändert am Ergebnis nichts.
const CHUNKS_PRO_SCHRITT := 4

## Ob der Lader gerade arbeitet.
var laeuft: bool = false

## Einmal-Ereignis: wird beim Abschluss gefeuert.
signal fertig

var _chunks: Array[Vector2i] = []
var _index: int = 0
var _model: Welt_Model = null
var _generator: Welt_Generator = null
var _biom_id: String = ""
var _z_ebene: int = 0
var _kamera_pos: Vector2 = Vector2.INF

## Kategorie logik: Start, Schritt und Fortschritt.

func starten(p_model: Welt_Model, p_generator: Welt_Generator, biom_id: String, z_ebene: int = 0) -> void:
	## Baut die Chunk-Liste auf und sortiert sie nach Kameranähe, damit der
	## sichtbare Teil zuerst materialisiert wird (lazy loading nach Blick).
	_model = p_model
	_generator = p_generator
	_biom_id = biom_id
	_z_ebene = z_ebene
	_chunks.clear()
	_index = 0
	laeuft = false
	if _model == null or _generator == null:
		fertig.emit()
		return
	var kante := maxi(_generator.chunk_groesse(), 1)
	var breite := ceili(float(_model.raster_breite) / float(kante))
	var hoehe := ceili(float(_model.raster_hoehe) / float(kante))
	for cy in hoehe:
		for cx in breite:
			_chunks.append(Vector2i(cx, cy))
	if _chunks.is_empty():
		fertig.emit()
		return
	_chunks.sort_custom(_naeher_an_kamera)
	laeuft = true

func kamera_position_setzen(pos: Vector2) -> void:
	## Die Szene reicht die Kamera-Position herein; sie entscheidet nur
	## über die Reihenfolge, nie über den Inhalt.
	_kamera_pos = pos

func schritt() -> void:
	## Verarbeitet höchstens CHUNKS_PRO_SCHRITT Chunks je Ruf; der nächste
	## Ruf zieht die Arbeit weiter. Keine Uhr, kein Messen, nur Zählen.
	if not laeuft:
		return
	var verarbeitet := 0
	while _index < _chunks.size() and verarbeitet < CHUNKS_PRO_SCHRITT:
		var chunk := _chunks[_index]
		_index += 1
		_generator.chunk_fuellen_oeffentlich(_model, chunk, _biom_id, _z_ebene)
		verarbeitet += 1
	if _index >= _chunks.size():
		_abschliessen()

func fortschritt_anteil() -> float:
	## Fortschritt für Ladeanzeigen, 0 bis 1.
	if _chunks.is_empty():
		return 1.0
	return float(_index) / float(_chunks.size())

func laufende_anzahl() -> int:
	## Wie viele Chunks noch offen sind, für den Lauf-Log.
	return maxi(_chunks.size() - _index, 0)

func _abschliessen() -> void:
	laeuft = false
	fertig.emit()

func _naeher_an_kamera(a: Vector2i, b: Vector2i) -> bool:
	## Sichtbares zuerst: Die Chunk-Mitte mit dem kleinsten Abstand zur
	## Kamera gewinnt. Ohne Kamera-Position bleibt die Reihenfolge.
	if _kamera_pos == Vector2.INF:
		return false
	return _chunk_mitte(a).distance_squared_to(_kamera_pos) < _chunk_mitte(b).distance_squared_to(_kamera_pos)

func _chunk_mitte(chunk: Vector2i) -> Vector2:
	var kante := float(_generator.chunk_groesse()) * float(_model.kachel_groesse)
	return Vector2(chunk) * kante + Vector2(kante, kante) * 0.5
