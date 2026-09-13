# -*- coding: utf-8 -*-
"""Der Tick-Ordnungs-Prüfer: Die Reihenfolge der Weltuhr-Teilnehmer als Vertrag.

Jede Datei dieses Pakets hat genau eine Zustaendigkeit: ordnung.json traegt die
erklaerte Reihenfolge und je Domaene den Grund, pruefer.py liest den Code und
vergleicht ihn mit der Erklaerung. Der Einstieg bleibt die Datei pruefer.py
selbst, die auch direkt aufgerufen werden kann.

Warum es dieses Paket gibt: Die Weltuhr sendet ihren Tick als Signal. Wer sich
wann anmeldet, entscheidet ueber die Ausfuehrungsreihenfolge je Tick. Ohne
Erklaerung ist diese Reihenfolge ein Zufall der Aufbaureihenfolge: Ein neues
add_child an der falschen Stelle verschiebt stillschweigend die Zeitordnung
aller Domaenen gegeneinander. Genau das prueft dieses Paket mechanisch.
"""
