extends RefCounted
class_name Ui_OnboardingUebersetzer
## Übersetzer des Onboarding-Fensters: Er liest die Lehrschritte aus dem
## Datenpool ui/data/onboarding.json und entscheidet anhand des
## Welt_FortschrittsMaschine-Standes, welcher Schritt gerade der sprechende
## ist. Er rechnet nichts und kennt kein Fenster; er liefert nur Snapshots
## als Array aus Dictionaries, das Fenster liest und zeigt.
##
## Verantwortlichkeit: Lehrschritte laden, Stand bestimmen, als UI-Einträge
## übersetzen. Erweiterung ohne UI-Code: Ein neuer Schritt in onboarding.json
## erscheint automatisch in der Leitplanke.

const QUELLE := "res://ui/data/onboarding.json"

## Kategorie daten: geladene Schritte, Titel und der Merker erledigter ids.
var _schritte: Array[Dictionary] = []
var _titel: String = "Erste Schritte"
var _erledigt: Dictionary = {}

## Kategorie logik: Laden, Stand bestimmen, als UI-Einträge übersetzen.

func _init() -> void:
	laden()

func laden() -> void:
	_schritte.clear()
	if not FileAccess.file_exists(QUELLE):
		push_warning("Onboarding-Pool nicht gefunden: %s" % QUELLE)
		return
	var datei := FileAccess.open(QUELLE, FileAccess.READ)
	var gelesen: Variant = JSON.parse_string(datei.get_as_text())
	if typeof(gelesen) != TYPE_DICTIONARY:
		push_warning("Onboarding-Pool ungueltiges Format: %s" % QUELLE)
		return
	var pool: Dictionary = gelesen as Dictionary
	_titel = str(pool.get("titel", _titel))
	for eintrag: Variant in pool.get("schritte", []):
		if eintrag is Dictionary:
			_schritte.append((eintrag as Dictionary).duplicate(true))

func titel() -> String:
	return _titel

func fortschritt_melden(stufe_id: String) -> void:
	# Der Fortschritt meldet eine abgeschlossene Stufe; die Leitplanke hakt
	# jeden Lehrschritt ab, der auf genau diese Stufe zeigt.
	for schritt: Dictionary in _schritte:
		if str(schritt.get("stufe_id", "")) == stufe_id:
			_erledigt[str(schritt.get("id", ""))] = true

func eintraege_ermitteln(fortschritt: Welt_FortschrittsMaschine) -> Array[Dictionary]:
	## Der Snapshot für das Fenster: je Schritt id, Tipp, Haken und die Marke
	## ob er der aktuelle sprechende Schritt ist.
	var aktive_id := _sprechende_id(fortschritt)
	var ergebnis: Array[Dictionary] = []
	for schritt: Dictionary in _schritte:
		var id := str(schritt.get("id", ""))
		ergebnis.append({
			"id": id,
			"tipp": str(schritt.get("tipp", "")),
			"erledigt": bool(_erledigt.get(id, false)),
			"sprechend": id == aktive_id,
		})
	return ergebnis

func _sprechende_id(fortschritt: Welt_FortschrittsMaschine) -> String:
	## Der erste nicht abgehakte Schritt spricht; zeigt seine Stufe auf die
	## gerade aktive Progressions-Stufe, ist er genau jetzt der Lehrer.
	for schritt: Dictionary in _schritte:
		var id := str(schritt.get("id", ""))
		if bool(_erledigt.get(id, false)):
			continue
		var ausloeser := str(schritt.get("ausloeser", ""))
		if ausloeser == "progression_stufe":
			var stufe_id := str(schritt.get("stufe_id", ""))
			var aktive := str(fortschritt.aktive_stufe().get("id", "")) if fortschritt != null else ""
			if aktive == "" or aktive == stufe_id:
				return id
		else:
			return id
	return ""
