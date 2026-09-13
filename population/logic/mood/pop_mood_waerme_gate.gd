extends RefCounted
class_name Pop_MoodWaermeGate
## Wärme-Gate der Stimmung: Es liest die Wärme am eigenen Ort, entscheidet
## über die Schwellwerte der Mood-Registry, ob Kälte oder Hitze regiert, und
## kennt das Folgeziel der Sicherheit. Keine zweite Schwelle neben der
## Registry, kein Tick; die Maschine reicht nur durch.

var _waerme_feld: Welt_WaermeFeld = null
var _tageszyklus: Welt_TageszyklusMaschine = null
var _mood_mods: Pop_MoodModifikatorRegistry = null
var _welt_position: Vector2 = Vector2.ZERO

func einrichten(waerme_feld: Welt_WaermeFeld, tageszyklus: Welt_TageszyklusMaschine, mood_mods: Pop_MoodModifikatorRegistry) -> void:
	_waerme_feld = waerme_feld
	_tageszyklus = tageszyklus
	_mood_mods = mood_mods

func position_setzen(pos: Vector2) -> void:
	_welt_position = pos

func position() -> Vector2:
	return _welt_position

func bereit() -> bool:
	return _waerme_feld != null

func wert() -> float:
	if _waerme_feld == null:
		return 0.0
	var hell := 1.0 if _tageszyklus == null else _tageszyklus.helligkeit()
	return _waerme_feld.waerme_an(_welt_position, hell)

func gate_mod() -> Pop_MoodModifikator:
	## Einzige Gate-Auswahl für Wärme: Kälte und Hitze werden über die
	## Registry-Schwellwerte entschieden, dieselbe Entscheidung wie im
	## Umgebungsschaden der Vital-Maschine. Zwei Pfadkopien existieren nicht.
	if _mood_mods == null:
		return null
	var kalt := _mood_mods.mod_fuer("kaelte")
	var heiss := _mood_mods.mod_fuer("hitze")
	var w := wert()
	if kalt != null and w < kalt.schwellwert:
		return kalt
	if heiss != null and w > heiss.schwellwert:
		return heiss
	return null

func ersatz_verfuegbarkeit(schwellwert: int) -> int:
	## Verfügbarkeit der Wärme für den Need-Schritt: Unter dem Kälteschwellwert
	## gibt es nichts, über dem Hitzeschwellwert alles. Die Grenzen kommen
	## allein aus der Registry, der Fallback dient nur leeren Prüfkontexten.
	var w := wert()
	if w < _schwellwert_von("kaelte", -0.4):
		return -1
	if w > _schwellwert_von("hitze", 0.6):
		return 99
	return schwellwert

func not_ausmass() -> float:
	## Not-Ausmaß der Wärme: Kälte wirkt unter null, Hitze darüber. Der Betrag
	## bringt beide auf dieselbe steigende Skala wie die Schwellen der Ketten.
	var w := wert()
	return maxf(-w, 0.0) if w < 0.0 else maxf(w, 0.0)

func folge_ziel(mod: Pop_MoodModifikator) -> Vector2:
	## Verhalten in Sicherheit bringen: Bei Kälte geht es zum nächsten Feuer,
	## bei Hitze davon weg. Ohne Verhalten gibt es kein Ziel.
	if mod == null or mod.verhalten != "in_sicherheit_bringen" or _waerme_feld == null:
		return Vector2.INF
	if wert() < mod.schwellwert:
		return _waerme_feld.naechstes_feuer_fuer(_welt_position)
	return _flucht_von_feuer()

func _flucht_von_feuer() -> Vector2:
	var feuer := _waerme_feld.naechstes_feuer_fuer(_welt_position)
	if feuer == Vector2.INF:
		return Vector2.INF
	return _welt_position + (_welt_position - feuer).normalized() * Welt_Model.KACHEL_GROESSE * 3.0

func _schwellwert_von(mod_id: String, fallback: float) -> float:
	if _mood_mods == null:
		return fallback
	var mod := _mood_mods.mod_fuer(mod_id)
	return mod.schwellwert if mod != null else fallback
