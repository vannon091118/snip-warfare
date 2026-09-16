extends Welt_ModellSpeicher
class_name Welt_Model
## Spitze der Welt-Modell-Kette und zugleich der gebundene Name der Fassade:
## Alles Fremde sieht weiterhin Welt_Model mit derselben oeffentlichen Flaeche.
## Die Kette darunter: Basis (Raster), Objekte, Leben, Regionen, Biom,
## Migration, Speicher. Diese Spitze haelt nur noch den Registry-Zugriff
## fuer die Trefferpruefung und den Erschoepfungskasten als Komponente.
## RT-Pyramide: Basisobjekt der Pyramide. Darauf stehen Registries und
## Mutationen. Das aktive Biom wirkt ueber die Mutationsmaschine auf den
## Zustand, nie direkt auf die Daten. Karten sind relativ gross:
## 32x24 Kacheln a 512 Pixel.

var _welt_registry: Welt_Registry = null

## Erschoepfungssystem: Die Rechnung wohnt in der Welt_ErschoepfungMaschine;
## das Modell haelt nur den Datenkasten und delegiert jede Anfrage.
var _erschoepfung := Welt_ErschoepfungMaschine.new()

func objekt_bei(ziel: Vector2, such_radius: float) -> int:
	# Gibt den Index des Objekts zurueck, das den Punkt (nahe) abdeckt; sonst -1.
	# Fuer die Trefferpruefung wird nur die Datenklasse Objekt_Basis gelesen;
	# hier fliesst keine Logik einer anderen Domäne ein.
	if _welt_registry == null:
		_welt_registry = Welt_RegistryZugriff.welt()
	var registry := _welt_registry
	var bester_index := -1
	var beste_flaeche := INF
	for index in objekte.size():
		var objekt: Objekt_Basis = registry.finde_objekt(str(objekte[index]["element_id"]))
		if objekt == null:
			continue
		var halbe_breite := objekt.anzeige_breite / 2.0
		var hoehe := objekt.anzeige_hoehe
		var mitte := objekt_position(index) + Vector2(0, -hoehe / 2.0)
		var abstand := (mitte - ziel).abs()
		if abstand.x <= halbe_breite + such_radius and abstand.y <= hoehe / 2.0 + such_radius:
			var flaeche := halbe_breite * hoehe
			if flaeche < beste_flaeche:
				beste_flaeche = flaeche
				bester_index = index
	return bester_index

func _chunk_key_aus_position(x: int, y: int) -> String:
	var cx := int(float(x) / float(chunk_groesse))
	var cy := int(float(y) / float(chunk_groesse))
	return "%d_%d" % [cx, cy]

func _chunk_key_aus_kachel(kachel_x: int, kachel_y: int) -> String:
	var cx := int(float(kachel_x) / float(chunk_groesse))
	var cy := int(float(kachel_y) / float(chunk_groesse))
	return "%d_%d" % [cx, cy]

## Erschoepfung: Reine Delegation an die Maschine; die oeffentlichen Namen
## bleiben stabil, damit Generator, Ressourcen und Speicher unveraendert
## weiterlesen koennen.
func erschoepfung_initialisieren() -> void:
	_erschoepfung.initialisieren(chunk_groesse, raster_breite, raster_hoehe)

func erschoepfung_holen(chunk_key: String, ressource_typ: String) -> int:
	return _erschoepfung.holen(chunk_key, ressource_typ)

func erschoepfung_setzen(chunk_key: String, ressource_typ: String, wert: int) -> void:
	_erschoepfung.setzen(chunk_key, ressource_typ, wert)

func erschoepfung_erhoehen(chunk_key: String, ressource_typ: String, delta: int) -> void:
	_erschoepfung.erhoehen(chunk_key, ressource_typ, delta)

func erschoepfung_prozent(chunk_key: String, ressource_typ: String) -> float:
	return _erschoepfung.prozent(chunk_key, ressource_typ)

func kann_ressource_spawnen(chunk_key: String, ressource_typ: String, lager_bestand: int) -> bool:
	return _erschoepfung.kann_ressource_spawnen(chunk_key, ressource_typ, lager_bestand)

func erschoepfung_zuruecksetzen_fuer_chunk(chunk_key: String) -> void:
	_erschoepfung.zuruecksetzen_fuer_chunk(chunk_key)

func erschoepfung_alle_chunks_zuruecksetzen() -> void:
	_erschoepfung.alle_chunks_zuruecksetzen()

func erschoepfung_zustand_holen() -> Dictionary:
	return _erschoepfung.zustand_holen()

func erschoepfung_zustand_setzen(daten: Dictionary) -> void:
	_erschoepfung.zustand_setzen(daten)
