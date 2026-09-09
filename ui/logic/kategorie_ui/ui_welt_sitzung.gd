extends Node
class_name Ui_WeltSitzung
## Sitzungszustand zwischen Menü, Karte und Editor.
## Bewusst klein: nur Übergabewerte, keine Logik.

var welt_name: String = ""
var kommt_vom_editor: bool = false
## Seed-Wunsch für eine neue zufällige Welt: 0 bedeutet "Zufall aus dem
## zentralen Kern_Zufall ziehen". Die Karte liest ihn beim Aufbau der Welt.
var seed_wunsch: int = 0
