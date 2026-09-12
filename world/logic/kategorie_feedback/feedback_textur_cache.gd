extends RefCounted
class_name Welt_FeedbackTexturCache
## Textur-Cache fuer Feedback-Anzeigen: Haelt einmal geladene Texturen im
## Speicher, damit bei Schaden-, Tod- und Ernte-Events kein synchrones
## load() von der Platte ausgefuehrt werden muss.
## Jede Textur wird hoechstens einmal gelesen; nachfolgende Anzeigen
## bedienen sich direkt aus dem Speicher.

static var _cache: Dictionary = {}

static func textur_fuer(pfad: String) -> Texture2D:
	if pfad == "":
		return null
	if _cache.has(pfad):
		return _cache[pfad] as Texture2D
	if ResourceLoader.exists(pfad):
		var tex := load(pfad) as Texture2D
		_cache[pfad] = tex
		return tex
	return null

static func vorladen(pfad: String) -> void:
	if pfad != "":
		textur_fuer(pfad)

static func zuruecksetzen() -> void:
	_cache.clear()
