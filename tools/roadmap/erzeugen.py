# -*- coding: utf-8 -*-
"""Orchestrierung des Roadmap-Abgleichs.

Eine Zustaendigkeit: Die Reihenfolge kennen, nicht die Inhalte. Lesen, Parser,
Beweislauf, Urteil, Befund, Schreiben, Bericht. Jeder Schritt liegt in seinem
eigenen Baustein; hier werden sie nur nacheinander bedient, damit alle denselben
Stand sehen.
"""

from . import abhaken as abhaken_modul
from . import befund as befund_modul
from .befund import FALSCH
from .beweis import Beweisstand
from .checkpoint import checkpoints_lesen, doppelte_nummern
from .kern import ROADMAP_PFAD, markdown_schreiben, roadmap_lesen


def abgleichen(mit_godot=True, godot_befehl="godot", schreiben=True, bericht=True):
    """Vergleicht die Roadmap mit dem echten Code und hakt Gedecktes ab.

    Zurueck kommt ein Ergebnis-Woerterbuch mit den Kennzahlen des Laufs, dem
    Befund und der Liste der frisch abgehakten Checkpoints. Ohne Roadmap
    passiert nichts; der Aufrufer entscheidet ueber den Rueckgabewert.
    """
    text = roadmap_lesen()
    if text is None:
        if bericht:
            print("Keine %s gefunden; nichts abzugleichen." % ROADMAP_PFAD)
        return {"gefunden": False, "abgehakt": [], "befund": [],
                "eintraege": 0, "gruppen": {FALSCH: []}}

    eintraege = checkpoints_lesen(text)
    doppelte = doppelte_nummern(eintraege)
    beweisstand = Beweisstand(mit_godot=mit_godot, godot_befehl=godot_befehl)
    urteile = abhaken_modul.beurteilen(eintraege, beweisstand)
    gruppen, doppelte_befunde = befund_modul.befunde_sammeln(urteile, doppelte)

    abgehakt = []
    if schreiben:
        neuer_text, abgehakt = abhaken_modul.abhaken(text, urteile)
        if neuer_text != text:
            markdown_schreiben(neuer_text)

    ergebnis = {
        "gefunden": True,
        "eintraege": len(eintraege),
        "abgehakt": abgehakt,
        "gruppen": gruppen,
        "doppelte": doppelte,
        "befund": befund_modul.bericht(gruppen, doppelte_befunde),
    }
    if bericht:
        _berichten(ergebnis, schreiben)
    return ergebnis


def _berichten(ergebnis, schreiben):
    """Schreibt den Laufbericht: erst die Handlung, dann die Gegenrede."""
    print("Roadmap-Abgleich: %d Checkpoints gelesen." % ergebnis["eintraege"])
    if ergebnis["abgehakt"]:
        print("  neu abgehakt: %s" % ", ".join(ergebnis["abgehakt"]))
    elif schreiben:
        print("  neu abgehakt: nichts; kein offener Eintrag traegt seinen Beweis.")
    print("")
    for zeile in ergebnis["befund"]:
        print(zeile)


def befund_lesen(text=None, mit_godot=True, godot_befehl="godot"):
    """Der Befund allein, ohne Schreiben: fuer Prueflaeufe und den Preflight.

    Der Aufrufer bekommt genau die Zeilen, die ein Mensch lesen soll, und
    nichts darueber hinaus.
    """
    text = roadmap_lesen() if text is None else text
    if text is None:
        return ["Keine %s gefunden." % ROADMAP_PFAD]
    eintraege = checkpoints_lesen(text)
    doppelte = doppelte_nummern(eintraege)
    beweisstand = Beweisstand(mit_godot=mit_godot, godot_befehl=godot_befehl)
    urteile = abhaken_modul.beurteilen(eintraege, beweisstand)
    gruppen, doppelte_befunde = befund_modul.befunde_sammeln(urteile, doppelte)
    return befund_modul.bericht(gruppen, doppelte_befunde)
