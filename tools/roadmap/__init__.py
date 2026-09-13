# -*- coding: utf-8 -*-
"""Die Roadmap-Abgleich-Familie: Checkpoints gegen den echten Code abgleichen.

Jede Datei dieses Pakets hat genau eine Zustaendigkeit: kern die Muster und
das Lesen/Schreiben, checkpoint die CP-Eintraege als Datenklassen, beweis die
ausfuehrbaren Pruefungen, abhaken das Setzen der Haekchen, befund die
adversariale Gegenrede und erzeugen die Reihenfolge. Der Einstieg bleibt
tools/roadmap_abgleichen.py.

Grundsatz: Ein Haekchen entsteht nur aus einem bestandenen Beweis. Die Datei
wird nie schlechter gemacht als sie ist; ein falsches Haekchen wird gemeldet,
nicht stillschweigend entfernt.
"""
