# -*- coding: utf-8 -*-
"""Einstieg des Roadmap-Abgleichs: Checkpoints gegen den Code abgleichen.

Diese Datei ist bewusst eine duenne Schale. Die Inhalte liegen in tools/roadmap/
und tragen dort je eine eigene Zustaendigkeit: kern die Muster und das Lesen,
checkpoint die CP-Eintraege, beweis die ausfuehrbaren Pruefungen, abhaken das
Setzen der Haekchen, befund die adversariale Gegenrede, erzeugen die Reihenfolge.

    python tools/roadmap_abgleichen.py                abgleichen und abhaken
    python tools/roadmap_abgleichen.py --pruefen      nur pruefen, nichts schreiben
    python tools/roadmap_abgleichen.py --ohne-godot   Laufpruefungen nicht starten
    python tools/roadmap_abgleichen.py --godot-befehl PFAD

Ein Haekchen entsteht ausschliesslich aus einem bestandenen Beweis. Die
Laufpruefungen tools/lauf_pruefung_*.gd kosten je einen Engine-Start; ohne
--ohne-godot werden sie ausgefuehrt und gelten nur, wenn sie fehlerfrei enden.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from roadmap.befund import FALSCH
from roadmap.erzeugen import abgleichen


def hauptprogramm():
    """Fuehrt den Abgleich aus und meldet den Ausgang als Rueckgabewert."""
    parser = argparse.ArgumentParser(description="Roadmap-Checkpoints gegen den Code abgleichen")
    parser.add_argument("--pruefen", action="store_true",
                        help="nur melden; kein Haekchen schreiben")
    parser.add_argument("--ohne-godot", action="store_true",
                        help="Laufpruefungen nicht ausfuehren (schneller Lauf)")
    parser.add_argument("--godot-befehl", default="godot",
                        help="Befehl oder Pfad der Godot-Engine")
    argumente = parser.parse_args()

    ergebnis = abgleichen(mit_godot=not argumente.ohne_godot,
                          godot_befehl=argumente.godot_befehl,
                          schreiben=not argumente.pruefen)
    if not ergebnis["gefunden"]:
        return 2
    falsch = len(ergebnis["gruppen"][FALSCH])
    if falsch:
        print("")
        print("Roadmap-Abgleich: %d falsche Haekchen gefunden; die Roadmap ueberzeichnet." % falsch)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(hauptprogramm())
