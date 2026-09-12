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
# Autonomes Verhalten: Jede Kannibalismus-Tat wird am Tatort gemeldet,
# damit Zeugen im Umkreis wahrnehmen und lernen können. Der Bus ist die
# einzige Brücke zwischen Täter und Zeugen, kein direkter Ruf.
@warning_ignore("unused_signal")
signal kannibalismus_erreignis(tatort: Vector2)
# Menü-Gegenprüfung: Ein geöffnetes Menü meldet sich; die
# Modifikator-Maschinen aktualisieren daraufhin ihre Faktoren.
@warning_ignore("unused_signal")
signal menue_geoeffnet()
# Zustands-Timeline: Jede protokollierte Buchung wird gemeldet, damit die
# UI den Einfluss der Modifikatoren zeigen kann. Nichts passiert ohne Feedback.
signal timeline_eintrag(beschreibung: String)
# Lager-Bestand ändert: Wird ausgestoßen, wenn ein Lager seinen Bestand
# ändert (Ressourcen eingelagert oder entnommen). Der Darsteller liest hier
# und aktualisiert die visuelle Darstellung.
signal lager_geaendert(lager_id: String)
# Produktionsraum entstanden: Wird ausgestoßen, wenn ein Möbel-Set einen
# Raum mit passendem Profil (z. B. "rathaus") vervollständigt. Der
# Welt_FortschrittsMaschine hört zu und spawnt den Orchestrator.
@warning_ignore("unused_signal")
signal produktionsraum_entstanden(raum_id: String, profil: String)
# Fraktions-Konflikt: Wenn die Fraktions-KI Maschine den Konfliktschwellenwert
# überschreitet, wird dieses Signal ausgestoßen. Die Weltkarte visualisiert
# dies als Farbänderung der Verbindungslinien zwischen Fraktionsknoten.
@warning_ignore("unused_signal")
signal konflikt_erklaert(fraktion_a: String, fraktion_b: String)
# Einheiten-Auswahl: Wird ausgestoßen, wenn der Spieler eine Einheit
# auswählt. Das Pop_EinheitPanel hört zu und zeigt die Details.
@warning_ignore("unused_signal")
signal einheit_ausgewaehlt(einheit_id: int)
# Z-Layer: Wird ausgestoßen, wenn Job_Graben die Decke einer Z-Ebene entfernt
# (Fels-Tile auf 0 Leben). Der Wasser_Automat hört darauf und fügt die
# Wasser-Tiles direkt über dem Loch zur Dirty-Queue hinzu.
@warning_ignore("unused_signal")
signal decken_entfernt(position: Vector2, z_ebene: int)

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

func _emit_kannibalismus(tatort: Vector2) -> void:
	kannibalismus_erreignis.emit(tatort)

func _emit_menue_geoeffnet() -> void:
	menue_geoeffnet.emit()

func _emit_timeline_eintrag(beschreibung: String) -> void:
	timeline_eintrag.emit(beschreibung)

func _emit_lager_geaendert(lager_id: String) -> void:
	lager_geaendert.emit(lager_id)

func _emit_konflikt_erklaert(fraktion_a: String, fraktion_b: String) -> void:
	konflikt_erklaert.emit(fraktion_a, fraktion_b)

func _emit_produktionsraum_entstanden(raum_id: String, profil: String) -> void:
	produktionsraum_entstanden.emit(raum_id, profil)

func _emit_einheit_ausgewaehlt(einheit_id: int) -> void:
	einheit_ausgewaehlt.emit(einheit_id)

func _emit_decke_entfernt(position: Vector2, z_ebene: int) -> void:
	decken_entfernt.emit(position, z_ebene)
