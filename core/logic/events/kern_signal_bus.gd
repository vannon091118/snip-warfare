extends Node
## Globaler Signalbus fuer Feedback-Ereignisse.
## Einheiten und Tiere melden Schaden und Tod hier; der Feedback-Manager
## hoert zu und erzeugt die schwebenden Anzeigen. Kein Zufall, nur Signale.

signal schaden_erhalten(position: Vector2, schaden: int, art: String)
signal gestorben(position: Vector2, typ: String, war_einheit: bool)
