extends Node
class_name Menue_StoryRegisseur
## Der Regisseur der Menue-Story: Er kennt nur den Takt und die Reihenfolge.
## Genau eine Verantwortung: Das passende Event je Takt anrufen. Keine
## Darstellung, keine Figuren; die Buehne spielt, der Pool liefert die Daten.

const AUSKLANG_TICKS := 480

## Kategorie daten: Pool, Buehne und der Takt-Stand der Runde.
var _daten: Menue_StoryDaten = null
var _buehne: Menue_BuehnenMeister = null
var _takt: int = -1

## Kategorie logik: Anstupsen und Takt-Schritt.

func anstupsen(buehne: Menue_BuehnenMeister) -> void:
	_buehne = buehne
	_daten = Menue_StoryDaten.new()
	if not _daten.laden():
		push_warning("Menue-Story: Der Datenpool liess sich nicht laden; die Story schweigt.")
		_daten = null
	_takt = -1
	# Genau ein Takt: die globale Weltuhr. Keine eigene Zeit im Menue.
	var weltuhr := get_node_or_null("/root/Weltuhr")
	if weltuhr != null and weltuhr.has_signal("tick"):
		weltuhr.tick.connect(tick_schritt)

func tick_schritt(_tick_nummer: int, _delta: float) -> void:
	# Der Vertrags-Ruf der Weltuhr traegt Nummer und Delta; die eigene
	# Stelle zaehlt die Datei selbst, die Werte der Uhr werden bewusst
	# ignoriert, denn der Takt des Menues ist die Reihenfolge, nicht die Uhr.
	if _daten == null or _buehne == null:
		return
	_takt += 1
	var stelle := _takt
	for event: Dictionary in _daten.events:
		if int(event.get("start", 0)) == stelle:
			_buehne.fuehre_aus(event)
	if _takt >= _daten.letzter_start() + AUSKLANG_TICKS:
		_buehne.buehne_leeren()
		_takt = -1

## Der Spieler hat etwas getan: Die Story vergisst ihre Stelle und beginnt
## wieder von vorn, bis der nächste Moment der Stille kommt.
func von_vorn() -> void:
	_takt = -1
	if _buehne != null:
		_buehne.buehne_leeren()
