extends RefCounted
class_name Ui_ExpansionMaschine
## Expansion-Maschine der Eingabe-Domäne: Erzeugt über die Karten-Fabrik eine
## neue Basis-Karte, trägt sie in die Welt-Sitzung ein, sichert die Welt und
## stößt den atomaren Modellwechsel in der Szene an. Kein Klick-Übersetzen:
## Nur der Expansions-Ablauf wohnt hier.

## Kategorie daten: Fabrik-, Sitzungs- und HUD-Referenzen.
var _map_fabrik: Welt_MapFabrik = null
var _hud: VBoxContainer = null
var _modell_ersetzen: Callable = Callable()

## Kategorie logik: Expansion ausführen.

func einrichten(map_fabrik: Welt_MapFabrik, hud: VBoxContainer, modell_ersetzen: Callable) -> void:
	_map_fabrik = map_fabrik
	_hud = hud
	_modell_ersetzen = modell_ersetzen

func expansion_ausfuehren() -> void:
	# Expansion: Die Fabrik erzeugt eine neue Karte, trägt sie in die World
	# ein und markiert sie als Basis; die Szene übernimmt das neue Modell.
	if _map_fabrik == null or WeltSitzung.world == null or not _modell_ersetzen.is_valid():
		if _hud != null:
			(_hud as Variant).meldung_setzen("Expansion nicht möglich: Keine World geladen.")
		return
	var neue_karte := _map_fabrik.neue_karte_erzeugen(WeltSitzung.world, "karte_%d" % WeltSitzung.world.map_zahl(), "gemaaessigt")
	if neue_karte == null:
		if _hud != null:
			(_hud as Variant).meldung_setzen("Expansion fehlgeschlagen: Generator verwarf die Karte.")
		return
	WeltSitzung.aktive_map_id = neue_karte.map_id
	var speicher := Welt_Speicher.new()
	speicher.world_speichern(WeltSitzung.welt_name, WeltSitzung.world)
	_modell_ersetzen.call(neue_karte)
	if _hud != null:
		(_hud as Variant).meldung_setzen("Expansion: Neue Basis-Karte %s erzeugt und gespeichert." % neue_karte.map_id)
