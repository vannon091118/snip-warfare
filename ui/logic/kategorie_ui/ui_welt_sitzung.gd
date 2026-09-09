extends Node
class_name Ui_WeltSitzung
## Sitzungszustand zwischen Menü, Karte und Editor.
## Bewusst klein: nur Übergabewerte, keine Logik.

var welt_name: String = ""
var kommt_vom_editor: bool = false
## Seed-Wunsch für eine neue zufällige Welt: 0 bedeutet "Zufall aus dem
## zentralen Kern_Zufall ziehen". Die Karte liest ihn beim Aufbau der Welt.
var seed_wunsch: int = 0

## World-Ebene: Die geladene World hält alle Maps; aktive_map_id bestimmt,
## welche Karte die Welt-Szene aufbaut. Beide Felder sind reine Übergabe,
## die Logik liegt in Welt_World und Welt_Ladevorgang.
var world: Welt_World = null
var aktive_map_id: String = ""

## Übergangs-Verbindung: Die Zwischen-Szene liest Ziel und Ankündigung
## aus der Sitzung und läutet die nächste Szene ein. So können später
## Events und Cutscenes als Verbindungen zwischen Szenen eingefügt werden.
var uebergang_ziel: String = ""
var uebergang_text: String = ""