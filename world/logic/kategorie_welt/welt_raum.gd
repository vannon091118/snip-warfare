extends RefCounted
class_name Welt_Raum
## Kategorie daten: Raum-Descriptor (id, innen_kacheln, Masse, Türen, Hülle, Zentrum).
## Kategorie logik: Geometrische Enthalten-Abfragen und Wörterbuch-Abbildung.
## Datenklasse eines erkannten Raumes: rein datengetragen, keine Zeit, kein Tick.
## Sie beschreibt genau einen geschlossenen Raum mit seiner Innenfläche, seinen
## Türen und seinem abgeschlossenen Status. Die Erkennung liefert sie.

var id: String = ""
var innen_kacheln: Array[Vector2i] = []
var innen_flaeche: int = 0
var breite: int = 0
var hoehe: int = 0
var hat_tuer: bool = false
var geschlossen: bool = false
var tuer_kacheln: Array[Vector2i] = []
var min_kachel: Vector2i = Vector2i.ZERO
var max_kachel: Vector2i = Vector2i.ZERO
var zentrum: Vector2 = Vector2.ZERO
var z_ebene: int = 0

func _to_string() -> String:
	return "Raum %s: %dx%d innen=%d tuer=%s geschlossen=%s" % [id, breite, hoehe, innen_flaeche, "ja" if hat_tuer else "nein", "ja" if geschlossen else "nein"]

func enthaelt_kachel(kachel: Vector2i) -> bool:
	return innen_kacheln.has(kachel)

func enthaelt_welt_position(welt_position: Vector2, kachel_groesse: int) -> bool:
	var kachel := Vector2i(floori(welt_position.x / float(kachel_groesse)), floori(welt_position.y / float(kachel_groesse)))
	return enthaelt_kachel(kachel)

func nach_woerterbuch() -> Dictionary:
	return {
		"id": id,
		"innen_kacheln": innen_kacheln,
		"innen_flaeche": innen_flaeche,
		"breite": breite,
		"hoehe": hoehe,
		"hat_tuer": hat_tuer,
		"geschlossen": geschlossen,
		"tuer_kacheln": tuer_kacheln,
		"min_kachel": [min_kachel.x, min_kachel.y],
		"max_kachel": [max_kachel.x, max_kachel.y],
		"zentrum": [zentrum.x, zentrum.y],
		"z_ebene": z_ebene,
	}
