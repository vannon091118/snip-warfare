extends PanelContainer
class_name Ui_HudOnboarding
## Onboarding-Fenster: Die Leitplanke der ersten Stunde. Es zeigt je
## Lehrschritt einen Tipp, hakt Erledigtes ab und hebt den sprechenden
## Schritt hervor. Es liest nur den Snapshot des Übersetzers und meldet
## nichts zurück; kein Zustand außer dem Sichtbar-Merker und dem Auf-/Zu-
## Knopf. Der Spieler kann es zuklappen; es kommt beim nächsten Fortschritt
## von selbst wieder.
##
## Kette: Welt_FortschrittsMaschine.stufe_erreicht -> Welt-Szene ->
## dieses Fenster.stufe_melden -> Uebersetzer -> auffrischen. Die Aussenwelt
## spricht nur mit stufe_melden und auffrischen; der Uebersetzer bleibt innen.

var _uebersetzer := Ui_OnboardingUebersetzer.new()
var _fortschritt: Welt_FortschrittsMaschine = null
var _titel_zeile: Label = null
var _liste: VBoxContainer = null
var _umklapp: Button = null
var _aufgeklappt: bool = true

## Kategorie logik: Einrichten, Auffrischen, Aufbau der Zeilen.

func einrichten(fortschritt: Welt_FortschrittsMaschine) -> void:
	_fortschritt = fortschritt

func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	add_theme_stylebox_override("panel", Ui_KleidMeister.panel_stil(10, 1))
	_titel_zeile = Label.new()
	_titel_zeile.text = _uebersetzer.titel()
	_titel_zeile.add_theme_font_size_override("font_size", 16)
	_umklapp = Button.new()
	_umklapp.text = "–"
	_umklapp.custom_minimum_size = Vector2(28, 28)
	_umklapp.focus_mode = Control.FOCUS_NONE
	_umklapp.pressed.connect(_auf_umklapp)
	var kopf := HBoxContainer.new()
	kopf.add_child(_titel_zeile)
	var dehner := Control.new()
	dehner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(dehner)
	kopf.add_child(_umklapp)
	_liste = VBoxContainer.new()
	_liste.add_theme_constant_override("separation", 6)
	add_child(kopf)
	add_child(_liste)
	auffrischen()

func stufe_melden(stufe_id: String) -> void:
	## Die einzige Tuer, durch die der Fortschritt hineinreicht: Der
	## Uebersetzer hakt ab und das Fenster zeichnet neu, ohne dass ein
	## Aufrufer je sein Inneres anfasst.
	_uebersetzer.fortschritt_melden(stufe_id)
	auffrischen()

func auffrischen() -> void:
	if _liste == null:
		return
	for kind in _liste.get_children():
		kind.queue_free()
	for eintrag: Dictionary in _uebersetzer.eintraege_ermitteln(_fortschritt):
		var zeile := Label.new()
		zeile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if bool(eintrag.get("erledigt", false)):
			zeile.text = "✓ %s" % str(eintrag.get("tipp", ""))
			zeile.modulate = Color(0.6, 0.75, 0.6, 0.65)
		elif bool(eintrag.get("sprechend", false)):
			zeile.text = "▸ %s" % str(eintrag.get("tipp", ""))
			zeile.modulate = Color(1.0, 0.95, 0.7)
		else:
			zeile.text = "· %s" % str(eintrag.get("tipp", ""))
			zeile.modulate = Color(0.75, 0.75, 0.75, 0.8)
		_liste.add_child(zeile)
	_liste.visible = _aufgeklappt

func _auf_umklapp() -> void:
	_aufgeklappt = not _aufgeklappt
	_umklapp.text = "+" if not _aufgeklappt else "–"
	auffrischen()
