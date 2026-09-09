extends ConfirmationDialog
class_name Ui_WeltAuswahlDialog
## Weltauswahl-Dialog mit Liste der gespeicherten Welten und Eingabefeld
## für einen neuen Weltnamen. Wird vom Hauptmenü für Laden und Map-Editor
## genutzt; über neuer_name_erlaubt steuert die Ansicht, ob das Eingabefeld
## für "Neue Welt" sichtbar ist.

signal welt_gewaehlt(welt_name: String)

var neuer_name_erlaubt := false
var hinweis_text := ""

var _liste: ItemList
var _namen_feld: LineEdit
var _speicher := Welt_Speicher.new()

func _ready() -> void:
	_liste = ItemList.new()
	_liste.custom_minimum_size = Vector2(340, 200)
	_namen_feld = LineEdit.new()
	_namen_feld.placeholder_text = "Neue Welt: Name eingeben"
	var inhalt := VBoxContainer.new()
	if hinweis_text != "":
		var hinweis := Label.new()
		hinweis.text = hinweis_text
		inhalt.add_child(hinweis)
	inhalt.add_child(_liste)
	inhalt.add_child(_namen_feld)
	add_child(inhalt)
	ok_button_text = "Auswählen"
	get_cancel_button().text = "Zurück"
	about_to_popup.connect(_liste_aktualisieren)
	_liste.item_activated.connect(_auf_aktiviert)
	confirmed.connect(_bestaetigen)

func _liste_aktualisieren() -> void:
	_liste.clear()
	_namen_feld.clear()
	_namen_feld.visible = neuer_name_erlaubt
	for welt_name in _speicher.welt_namen():
		_liste.add_item(welt_name)
	if _liste.item_count > 0:
		_liste.select(0)

func _auf_aktiviert(_index: int) -> void:
	_bestaetigen()

func _bestaetigen() -> void:
	# Eingabe eines neuen Namens hat Vorrang, sonst die Listenauswahl.
	var neuer_name := _namen_feld.text.strip_edges()
	if neuer_name_erlaubt and neuer_name != "":
		welt_gewaehlt.emit(neuer_name)
		return
	var ausgewaehlt := _liste.get_selected_items()
	if ausgewaehlt.is_empty():
		return
	welt_gewaehlt.emit(_liste.get_item_text(ausgewaehlt[0]))
