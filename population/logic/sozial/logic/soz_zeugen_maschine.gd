extends RefCounted
class_name Soz_ZeugenMaschine
## Kategorie logik: Verteilt beobachtete Taten an Zeugen im Radius.
## Wer dabei steht, glaubt selbst gesehen zu haben; niemand würfelt.

## Kategorie daten: Die Taten-Gewichte und der Zeugen-Radius aus dem Datenpool.
var _regeln: Soz_Datenpool = null
## Kategorie daten: Ethik-Konten und Image-Glauben, besessen vom Manager.
var _ethik: Dictionary = {}
var _glauben: Dictionary = {}
## Kategorie logik: Nachschlage-Ruf für Positionen, gesetzt vom Manager.
var position_fuer: Callable = Callable()

func einrichten(regeln: Soz_Datenpool) -> void:
	_regeln = regeln

func registrieren(einheit_id: int) -> void:
	if not _ethik.has(einheit_id):
		var konto := Soz_EthikLedger.new()
		konto.tiefe_setzen(int(_regeln.gruppe("zeugen").get("erinnerung_tiefe", 8)))
		_ethik[einheit_id] = konto

func ethik_von(einheit_id: int) -> float:
	var konto: Soz_EthikLedger = _ethik.get(einheit_id)
	return konto.kontostand() if konto != null else 0.0

func glaube_von(beobachter: int, ziel: int) -> Soz_ImageGlaube:
	return _glauben.get(_schluessel(beobachter, ziel))

func tat_buchen(taeter: int, _opfer: int, tat_name: String) -> void:
	var gewicht: Dictionary = _regeln.gruppe("taten").get(tat_name, {})
	if gewicht.is_empty():
		return
	var radius := float(_regeln.gruppe("zeugen").get("radius_px", 220.0))
	var tat_position: Vector2 = position_fuer.call(taeter)
	for zeuge: int in _ethik:
		if zeuge == taeter:
			continue
		var abstand: Vector2 = position_fuer.call(zeuge) - tat_position
		if abstand.length() > radius:
			continue
		var konto: Soz_EthikLedger = _ethik[zeuge] if zeuge == taeter else null
		if konto != null:
			konto.buchen(float(gewicht.get("ethik_stoss", 0.0)))
		_glauben_verfestigen(zeuge, taeter, float(gewicht.get("gerecht_stoss", 0.0)) * -1.0)

func _glauben_verfestigen(beobachter: int, ziel: int, wert: float) -> void:
	var schluessel := _schluessel(beobachter, ziel)
	var glaube: Soz_ImageGlaube = _glauben.get(schluessel)
	if glaube == null:
		glaube = Soz_ImageGlaube.new()
		_glauben[schluessel] = glaube
	glaube.mischen(wert, 0.5)

func _schluessel(beobachter: int, ziel: int) -> String:
	return "%d_%d" % [beobachter, ziel]
