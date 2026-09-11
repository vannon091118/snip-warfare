extends Node
class_name Ui_WeltSitzung
## Sitzungszustand zwischen Menü, Karte und Editor.
## Bewusst klein: nur Übergabewerte, keine Logik.

## Kategorie daten: Übergabewerte der aktuellen Spielsitzung.
var welt_name: String = ""
var kommt_vom_editor: bool = false
## Seed-Wunsch für eine neue zufällige Welt: 0 bedeutet "Zufall aus dem
## zentralen Kern_Zufall ziehen". Die Karte liest ihn beim Aufbau der Welt.
var seed_wunsch: int = 0

## World-Ebene: Die Sitzung hält die einzige World-Referenz zwischen den
## Szenen. Die aktive Map in der World ist dasselbe Welt_Model-Objekt wie
## in der Welt-Szene (Instanz-Übernahme beim Laden, Expansion und Speichern);
## die Sitzung erzeugt keine zweite Kartenwahrheit, sie trägt nur den
## Verweis und die aktive map_id zwischen Szenenwechseln.
var world: Welt_World = null
var aktive_map_id: String = ""

## World-Map-Startbereich: Der vom Spieler vor Spielstart gewählte Bereich
## liefert Biom, Koordinaten und Fraktionsnetzwerk an die lokale Generierung.
var start_region_x: int = 0
var start_region_y: int = 0
var start_biom_id: String = ""
var fraktionen_netzwerk: Array[Dictionary] = []

## Übergangs-Verbindung: Die Zwischen-Szene liest Ziel und Ankündigung
## aus der Sitzung und läutet die nächste Szene ein. So können später
## Events und Cutscenes als Verbindungen zwischen Szenen eingefügt werden.
var uebergang_ziel: String = ""
var uebergang_text: String = ""

## Kategorie logik: Hilfsfunktionen für die Sitzungsverwaltung.

func startbereich_setzen(region_x: int, region_y: int, biom_id: String) -> void:
	start_region_x = region_x
	start_region_y = region_y
	start_biom_id = biom_id
