extends RefCounted
class_name Einheit_WegPlanung
## Planung des Laufwegs für Einheiten: Sie baut das begehbare Netz aus dem
## Welt_Model und der Pfad-Registry, sucht Wege über den fertigen A-Stern
## undcached Ergebnisse je Start- und Zielzelle. Sie bewegt selbst nichts
## und kennt keine Einheiten; die Zustandsmaschine der Einheit folgt nur
## den gelieferten Wegpunkten. Ohne Pfad fällt der Aufrufer auf die
## geradlinige Bewegung zurück, damit Einheiten nie stehen bleiben.

## Kategorie daten: Netz, Finder, Registry und Weg-Cache.
const CACHE_MAX := 96

var _netz := Kern_PathNetz.new()
var _finder := Kern_PathFinder.new()
var _registry := Kern_PathRegistry.new()
var _cache: Dictionary = {}
var _cache_reihenfolge: Array[String] = []
## RUECKFALL: Kachelkante bis das Modell sie liefert (Testlaeufe ohne Welt).
var _kachel_groesse: float = float(Welt_Model.KACHEL_GROESSE)

## Kategorie logik: Netz aus Modell, Weg je Start und Ziel.


func netz_erneuern(model: Welt_Model) -> void:
	# Das Netz entsteht aus dem Modell; jede Welt-Objektposition sperrt
	# ihre Kachel, damit Einheiten Hindernisfelder umgehen statt durch
	# sie zu clippen. Ein neuer Aufbau verwirft den Cache, weil alte
	# Wege zu veralteten Sperrungen führen würden.
	_registry.laden()
	if model != null:
		_kachel_groesse = maxf(float(model.kachel_groesse), 1.0)
	var kollisionen: Array[Vector2] = []
	if model != null:
		for i in model.objekt_anzahl():
			kollisionen.append(model.objekt_position(i))
	_netz.aufbauen(model, _registry, kollisionen)
	_cache.clear()
	_cache_reihenfolge.clear()


func weg_zu(start: Vector2, ziel: Vector2) -> PackedVector2Array:
	# Liefert Wegpunkte in Weltkoordinaten ohne Start- und Zielpunkt;
	# leer heißt: keine sinnvolle Route, der Aufrufer läuft geradeaus.
	if _netz.breite <= 0 or _netz.hoehe <= 0:
		return PackedVector2Array()
	if _zelle_von(start) == _zelle_von(ziel):
		return PackedVector2Array()
	var ursprung_zelle := _zelle_von(start)
	var ziel_zelle := _zelle_von(ziel)
	if ursprung_zelle == ziel_zelle:
		return PackedVector2Array()
	# Steht die Einheit auf einem gesperrten Feld (Objekt- oder Terrain-
	# Sperre), beginnt die Route am nächsten freien Feld; einen Punkt für
	# dieses Feld gibt es nicht, die Einheit läuft direkt zum ersten
	# Freifeld und verlässt so sichtbar das Hindernis.
	var start_zelle := ursprung_zelle
	if _ist_gesperrt(ursprung_zelle):
		start_zelle = _freie_zelle_nahe(ursprung_zelle)
	var schluessel := "%d:%d->%d:%d" % [start_zelle.x, start_zelle.y, ziel_zelle.x, ziel_zelle.y]
	if _cache.has(schluessel):
		return _cache[schluessel]
	# Das Zielfeld darf betreten werden, wenn dort das Arbeitsobjekt steht;
	# die Sperre gilt nur für den Umweg über fremde Hindernisfelder.
	var ziel_knoten: Kern_PathKnoten = _netz.knoten_bei(ziel_zelle)
	var ziel_gesperrt := false
	if ziel_knoten != null and ziel_knoten.gesperrt:
		ziel_gesperrt = true
		ziel_knoten.gesperrt = false
	var zellen := _finder.weg_suchen(_netz.knoten_nach_position, start_zelle, ziel_zelle)
	if ziel_gesperrt and ziel_knoten != null:
		ziel_knoten.gesperrt = true
	# Nur Zwischenfelder bekommen Zellenmitten: Start- und Zielfeld
	# tragen keinen Punkt, damit niemand zur Hindernismitte zurückläuft
	# und der Endanlauf die direkte Linie zum Arbeitsziel bleibt.
	var punkte := PackedVector2Array()
	for lauf: int in zellen.size():
		if lauf == 0 or lauf == zellen.size() - 1:
			continue
		punkte.append(Vector2(zellen[lauf]) * _kachel_groesse + Vector2.ONE * (_kachel_groesse * 0.5))
	_cache[schluessel] = punkte
	_cache_reihenfolge.append(schluessel)
	if _cache_reihenfolge.size() > CACHE_MAX:
		var alt: String = _cache_reihenfolge.pop_front()
		_cache.erase(alt)
	return punkte


func _zelle_von(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x / _kachel_groesse), int(position.y / _kachel_groesse))

func _ist_gesperrt(zelle: Vector2i) -> bool:
	var knoten: Kern_PathKnoten = _netz.knoten_bei(zelle)
	return knoten == null or knoten.gesperrt

func _freie_zelle_nahe(ursprung: Vector2i) -> Vector2i:
	# Deterministischer Ring um den Ursprung: kleiner Radius zuerst,
	# feste Leserichtung; das erste freie Feld gewinnt. Ohne Treffer
	# bleibt der Ursprung, der Aufrufer fällt auf geradeaus zurück.
	for radius: int in range(1, 9):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var kandidat := ursprung + Vector2i(dx, dy)
				if not _ist_gesperrt(kandidat):
					return kandidat
	return ursprung
