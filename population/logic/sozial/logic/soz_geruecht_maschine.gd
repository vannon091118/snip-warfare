extends RefCounted
class_name Soz_GeruechtMaschine
## Kategorie logik: Wandernde Gerüchte. Stufe 0 bleibt beim Zeugen, ab Stufe 1
## wird an Nachbarn weitererzählt, wobei der Glaube je Stufe abfällt. Farben
## und Wirkungen kommen aus dem Datenpool, es wird nie gewürfelt.

## Kategorie daten: Der geladene Regeln-Pool.
var _regeln: Soz_Datenpool = null
## Kategorie daten: Träger-Id -> Array[Soz_Geruecht].
var _tragende: Dictionary = {}
## Kategorie logik: Nachschlage-Rufe, gesetzt vom Manager.
var position_fuer: Callable = Callable()
var traits_von: Callable = Callable()

func einrichten(regeln: Soz_Datenpool) -> void:
	_regeln = regeln

func geruechte_von(traeger_id: int) -> Array:
	return _tragende.get(traeger_id, []) as Array

## Kategorie logik: Am Tatort entsteht ein Gerücht in der Stufe seiner Art.

func urheur_buchen(taeter: int, opfer: int, art: String, glaube: float) -> void:
	var geruecht := Soz_Geruecht.new()
	geruecht.einrichten(opfer, taeter, art, glaube, _regeln.gruppe("geruechte"))
	_tragende[taeter] = geruechte_von(taeter)
	_tragende[taeter].append(geruecht)

## Kategorie logik: Der Gerede-Takt wandert pro Stufe einen Ring weiter.
## Nur Träger mit glaubwürdigen Gerüchten ab Stufe 1 erzählen weiter.

func gerede_takt(_delta: float, alle_ids: Array) -> void:
	var takt := _regeln.faktor("geruechte", "gerede_takt_ticks")
	if takt <= 0.0:
		return
	var paare: Array = []
	for traeger: int in _tragende:
		for geruecht: Soz_Geruecht in geruechte_von(traeger):
			if geruecht.eskalation() >= 1 and geruecht.glaube > 0.05:
				paare.append([traeger, geruecht])
	_weitergeben(paare, alle_ids)

func _weitergeben(paare: Array, alle_ids: Array) -> void:
	var verlust := _regeln.faktor("geruechte", "konfidenz_verlust_je_stufe")
	var art_regeln: Dictionary = _regeln.gruppe("geruechte").get("art", {})
	for eintrag: Array in paare:
		var traeger: int = eintrag[0]
		var geruecht: Soz_Geruecht = eintrag[1]
		# Ein Nachbar im Umfeld nimmt das Gerücht an; Traits färben den Glauben.
		var zuhoerer := _nachbar_fuer(traeger, alle_ids)
		if zuhoerer < 0:
			continue
		var neues_glaube := geruecht.glaube * verlust
		if neues_glaube <= 0.05:
			geruecht.glaube = 0.0
			continue
		var kopie := Soz_Geruecht.new()
		kopie.einrichten(geruecht.ziel_id, geruecht.urheber_id, geruecht.art, neues_glaube, art_regeln if false else _regeln.gruppe("geruechte"))
		_tragende[zuhoerer] = geruechte_von(zuhoerer)
		_tragende[zuhoerer].append(kopie)
		geruecht.glaube *= 0.5

func _nachbar_fuer(traeger: int, alle_ids: Array) -> int:
	# Der nächste Nachbar in Richtung Position; ohne Positionsruf bleibt es leer.
	if not position_fuer.is_valid():
		return -1
	var eigene: Vector2 = position_fuer.call(traeger)
	var bester := -1
	var beste_distanz := INF
	for id: int in alle_ids:
		if id == traeger:
			continue
		var abstand: Vector2 = position_fuer.call(id) - eigene
		if abstand.length() < beste_distanz:
			beste_distanz = abstand.length()
			bester = id
	return bester
