extends RefCounted
class_name Pop_MoodEskalation
## Blasen-Bau der Stimmung: Hier entstehen die Sprechblasen als Datenobjekte,
## aus Eskalationsstufen, Übergängen und Zeugen-Blicken. Reine Bauformen ohne
## Tick und ohne Signal; die Maschine übernimmt sie und meldet sie.

static func uebernehmen(ziel: Pop_Mood, mod: Pop_MoodModifikator, staerke: float) -> bool:
	## Einzige Übernahme einer Eskalationsstufe: Emoji, Kurzzeile, Grund,
	## Wirkung, Verhalten, Stufe und Kette kommen aus dem gewählten Eintrag.
	## Ohne Kette oder ohne erreichte Stufe ändert sie nichts.
	if mod == null or not mod.hat_eskalation():
		return false
	var stufe := mod.stufe_fuer(staerke)
	if stufe == null:
		return false
	_schreibe_stufe(ziel, mod, stufe)
	return true

static func aus_stufe(mod: Pop_MoodModifikator, stufe: Pop_MoodEskalationStufe) -> Pop_Mood:
	## Sichtbare Hervorhebung einer Kette von außen: Der Manager ruft sie,
	## wenn das autonome Verhalten auslöst, und die Blase erzählt dieselbe
	## Stufe, die das Verhalten wählt. Zwei Erzähl-Quellen entstehen nicht.
	if mod == null or stufe == null:
		return null
	var neu := Pop_Mood.new()
	neu.aktive_need_id = mod.need_id
	_schreibe_stufe(neu, mod, stufe)
	neu.intensitaet = 1.0
	neu.quelle = "verhalten"
	return neu

static func gedanke(need_id: String, emoji: String, gedanken_text: String) -> Pop_Mood:
	## Sprechblase aus einem Übergang: kurze, denkende Zeile mit eigenem Emoji.
	var neu := Pop_Mood.new()
	neu.aktive_need_id = need_id
	neu.emoji = emoji
	neu.sprechblase_text = gedanken_text
	neu.intensitaet = 0.6
	neu.quelle = "uebergang"
	return neu

## Nähe-Grenze für Zeugen: Der Mood-Pool trägt dazu keinen eigenen Wert,
## deshalb ist dieser Notfall-Default bewusst hier und keine zweite Quelle.
const ZEUGEN_NAEHE_KACHELN := 3.0

static func zeuge_war_nahe(ort: Vector2, tatort: Vector2) -> bool:
	return ort.distance_to(tatort) <= Welt_Model.KACHEL_GROESSE * ZEUGEN_NAEHE_KACHELN

static func zeugen(neben_an: bool, hat_gelernt: bool) -> Pop_Mood:
	## Gedanke eines Zeugen: Er hat eine Kannibalismus-Tat gesehen. Die Nähe
	## zum Tatort färbt den Satz, ohne eigenes Gelerntes ist es Ekel, mit
	## eigenem Gelernten Erinnerung.
	if hat_gelernt:
		var ort := "Direkt neben mir" if neben_an else "Drüben"
		return gedanke("kannibalismus", "😳", "%s habe ich es gesehen… es geht also." % ort)
	var schreck := "Direkt neben mir isst er einen von uns?!" if neben_an else "Da drüben isst er einen von uns?!"
	return gedanke("ekel", "😱", schreck)

static func _schreibe_stufe(ziel: Pop_Mood, mod: Pop_MoodModifikator, stufe: Pop_MoodEskalationStufe) -> void:
	ziel.emoji = stufe.emoji
	ziel.sprechblase_text = stufe.wirkung
	ziel.grund = stufe.grund
	ziel.wirkung = stufe.wirkung
	ziel.verhalten = stufe.verhalten
	ziel.stufe = stufe.stufe
	ziel.kette = mod.mod_id
	ziel.folge_mod_id = stufe.folge_mod_id
