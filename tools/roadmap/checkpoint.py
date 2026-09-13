# -*- coding: utf-8 -*-
"""Ein Checkpoint als Datenklasse, gelesen aus der Roadmap.

Eine Zustaendigkeit: Aus dem Roadmap-Text die CP-Eintraege herausziehen und je
Eintrag festhalten, was er behauptet. Der Parser erfindet nichts und deutet
nichts: Nummer, Kapitel, Status, genannte Klassen und Beweise stehen woertlich
so in der Zeile, wie sie dastehen.
"""

from .kern import (CP_MUSTER, KAPITEL_MUSTER, STATUS_FERTIG, STATUS_OFFEN,
                   STATUS_TEILWEISE, beweis_pfade_aus, klassen_aus)


class Checkpoint:
    """Ein CP-Eintrag der Roadmap mit Zeile, Kapitel, Status und Beweisen."""

    def __init__(self, zeile, kapitel, status, nummer, klammer, rest):
        self.zeile = zeile
        self.kapitel = kapitel
        self.status = status
        self.nummer = nummer
        self.klammer = klammer
        self.rest = rest

    @property
    def ist_fertig(self):
        """Setzt das Haekchen: Nur das x zaehlt als fertig."""
        return self.status == STATUS_FERTIG

    @property
    def ist_teilweise(self):
        """Die Tilde ist die halbe Zusage: Sie deckt nicht, sie erzaehlt."""
        return self.status == STATUS_TEILWEISE

    @property
    def ist_offen(self):
        """Offen ist nur die leere Klammer; alles andere ist eine Aussage."""
        return self.status == STATUS_OFFEN

    @property
    def titel(self):
        """Der sprechende Beiname hinter der Nummer, sonst ein Strich."""
        return self.klammer.strip() if self.klammer else ""

    @property
    def name(self):
        """Nummer und Beiname als eine lesbare Kennung."""
        return "%s (%s)" % (self.nummer, self.titel) if self.titel else self.nummer

    def klassen(self):
        """Die Klassen, die dieser Eintrag namentlich behauptet."""
        return klassen_aus(self.rest)

    def beweis_pfade(self):
        """Die ausfuehrbaren Pruefungen, die dieser Eintrag als Beweis nennt."""
        return beweis_pfade_aus(self.rest)

    def hat_beweis(self):
        """Wahr, wenn der Eintrag mindestens eine ausfuehrbare Pruefung nennt."""
        return bool(self.beweis_pfade())

    def __repr__(self):
        return "Checkpoint(%s, Zeile %d, Status %r)" % (self.nummer, self.zeile, self.status)


def checkpoints_lesen(text):
    """Alle CP-Eintraege eines Roadmap-Textes in Reihenfolge ihres Auftretens.

    Das laufende Kapitel wird mitgefuehrt, damit jeder Eintrag weiss, in welchem
    Slice er steht. Kapitel, die selbst Zeilen sind, werden nie als Eintrag
    gelesen.
    """
    eintraege = []
    kapitel = ""
    for nummer, roh in enumerate(text.splitlines(), start=1):
        kapitel_treffer = KAPITEL_MUSTER.match(roh)
        if kapitel_treffer is not None:
            kapitel = kapitel_treffer.group("titel").strip()
            continue
        treffer = CP_MUSTER.match(roh)
        if treffer is None:
            continue
        eintraege.append(Checkpoint(
            zeile=nummer,
            kapitel=kapitel,
            status=treffer.group("status").lower(),
            nummer=treffer.group("nummer"),
            klammer=treffer.group("klammer") or "",
            rest=treffer.group("rest"),
        ))
    return eintraege


def doppelte_nummern(eintraege):
    """Nummern, die mehr als einmal vergeben sind, mit ihren Zeilen.

    Doppelte Nummern sind kein Schoenheitsfehler: Ein Verweis auf CP-0.15 zeigt
    dann auf zwei verschiedene Zusagen, und keine davon ist noch eindeutig.
    """
    nach_nummer = {}
    for eintrag in eintraege:
        nach_nummer.setdefault(eintrag.nummer, []).append(eintrag.zeile)
    return {nummer: zeilen for nummer, zeilen in nach_nummer.items() if len(zeilen) > 1}
