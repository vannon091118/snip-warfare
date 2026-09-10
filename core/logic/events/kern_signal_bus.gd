extends Node
class_name Kern_SignalBus
## Globaler Signalbus fuer Feedback-Ereignisse.
## Einheiten und Tiere melden Schaden und Tod hier; der Feedback-Manager
## hoert zu und erzeugt die schwebenden Anzeigen. Kein Zufall, nur Signale.
## Autoload-Name und Klasse teilen sich den Namen: Im Spiel erreichst du die
## Instanz ueber den Autoload, im statischen Zugriff ueber bus().

@warning_ignore("unused_signal")
signal schaden_erhalten(position: Vector2, schaden: int, art: String)
@warning_ignore("unused_signal")
signal gestorben(position: Vector2, typ: String, war_einheit: bool)
# Menü-Gegenprüfung: Ein geöffnetes Menü meldet sich; die
# Modifikator-Maschinen aktualisieren daraufhin ihre Faktoren.
@warning_ignore("unused_signal")
signal menue_geoeffnet()
# Zustands-Timeline: Jede protokollierte Buchung wird gemeldet, damit die
# UI den Einfluss der Modifikatoren zeigen kann. Nichts passiert ohne Feedback.
@warning_ignore("unused_signal")
signal timeline_eintrag(beschreibung: String)

static func bus() -> Kern_SignalBus:
	# Während des Szenen-Aufbaus erzeugen Manager ihre Maschinen als
	# Feld-Initialisierer, also noch außerhalb des aktiven Szenenbaums. Der
	# absolute Pfad ist dann verboten und würde einen Engine-Fehler werfen;
	# der Zugriff wird deshalb erst nach dem Eintritt in den Baum versucht.
	var baum := Engine.get_main_loop() as SceneTree
	if baum == null or baum.root == null:
		return null
	# Relativer Name vom Wurzelknoten statt absoluter Pfad: Der absolute Pfad
	# ist außerhalb des aktiven Szenenbaums verboten, der relative Name liest
	# denselben Autoload-Knoten auch während des frühen Szenen-Aufbaus.
	var knoten := baum.root.get_node_or_null("KernSignalBusAutoload")
	if knoten is Kern_SignalBus:
		return knoten as Kern_SignalBus
	return null

func _emit_schaden(position: Vector2, schaden: int, art: String) -> void:
	schaden_erhalten.emit(position, schaden, art)

func _emit_gestorben(position: Vector2, typ: String, war_einheit: bool) -> void:
	gestorben.emit(position, typ, war_einheit)

func _emit_menue_geoeffnet() -> void:
	menue_geoeffnet.emit()

func _emit_timeline_eintrag(beschreibung: String) -> void:
	timeline_eintrag.emit(beschreibung)
