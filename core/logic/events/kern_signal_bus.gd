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

static func bus() -> Kern_SignalBus:
	var baum := Engine.get_main_loop() as SceneTree
	if baum != null:
		var knoten := baum.root.get_node_or_null("/root/KernSignalBusAutoload")
		if knoten is Kern_SignalBus:
			return knoten as Kern_SignalBus
	return null

func _emit_schaden(position: Vector2, schaden: int, art: String) -> void:
	schaden_erhalten.emit(position, schaden, art)

func _emit_gestorben(position: Vector2, typ: String, war_einheit: bool) -> void:
	gestorben.emit(position, typ, war_einheit)

func _emit_menue_geoeffnet() -> void:
	menue_geoeffnet.emit()
