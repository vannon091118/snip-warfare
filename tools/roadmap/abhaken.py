# -*- coding: utf-8 -*-
"""Das Haekchen setzen: nur wo ein Beweis ihn traegt, und nie rueckwaerts.

Eine Zustaendigkeit: Aus den Belegen die Sperr-Regel anwenden und die offenen
Checkpoint-Zeilen umschreiben. Dieses Modul entscheidet nicht, was ein Beweis
ist; es gehorcht nur dem Urteil, das der Beweislauf gefaellt hat.

Zwei harte Regeln:
  Erstens wird ausschliesslich eine leere Klammer zum Haekchen. Ein bereits
  gesetztes Haekchen oder eine halbe Tilde wird nie zurueckgenommen; ein
  falsches Haekchen ist ein Befund, kein stiller Korrekturlauf.
  Zweitens braucht jedes Haekchen mindestens einen benannten Beweis, jeder
  Beleg muss gruen sein und jede genannte Klasse muss existieren und verdrahtet
  sein. Ein ungepruefter Beleg haelt das Haekchen genauso offen wie ein roter:
  Ungeprueft ist nicht bestanden.
"""

from .beweis import UNGEPRUEFT
from .kern import CP_MUSTER, STATUS_OFFEN, zeile_abhaken


class Urteil:
    """Das Urteil ueber einen Checkpoint: bestanden, widerlegt oder ungeprueft."""

    def __init__(self, checkpoint, belege):
        self.checkpoint = checkpoint
        self.belege = belege

    @property
    def hat_beweis(self):
        """Wahr, wenn der Eintrag mindestens eine ausfuehrbare Pruefung nennt."""
        return self.checkpoint.hat_beweis()

    @property
    def widerlegt(self):
        """Widerlegt heisst: Ein Beleg ist rot, nicht nur unbestaetigt."""
        return any(beleg.ist_rot for beleg in self.belege)

    @property
    def ungeprueft(self):
        """Ungeprueft heisst: kein roter Beleg, aber mindestens ein offener."""
        return not self.widerlegt and any(beleg.status == UNGEPRUEFT
                                          for beleg in self.belege)

    @property
    def bestanden(self):
        """Bestanden heisst: Ein Beweis ist benannt, und jeder Beleg ist gruen.

        Eine blosse Klassendeckung genuegt nie. Existiert eine genannte Klasse
        und sonst nichts, ist das eine Aussage ueber den Code, nicht ueber die
        Zusage des Eintrags; das Haekchen bleibt dann offen.
        """
        return self.hat_beweis and bool(self.belege) and all(
            beleg.ist_gruen for beleg in self.belege)

    @property
    def fehlgruende(self):
        """Nur die Gruende, die gegen den Eintrag sprechen."""
        return [beleg.text for beleg in self.belege if not beleg.ist_gruen]

    @property
    def klassenfehler(self):
        """Die roten Klassengruende: fehlende und nirgends aufgerufene Klassen."""
        return [beleg.text for beleg in self.belege
                if beleg.ist_rot and ("existiert nirgends" in beleg.text
                                      or "wird aber nirgends" in beleg.text)]

    def kurzfassung(self):
        """Eine Zeile, die den Ausgang eines Eintrags erzaehlt."""
        if self.bestanden:
            return "bestanden (%d Belege)" % len(self.belege)
        if not self.hat_beweis:
            return "kein ausfuehrbarer Beweis benannt"
        if self.widerlegt:
            return "widerlegt: %s" % "; ".join(self.fehlgruende[:2])
        return "ungeprueft: %s" % "; ".join(self.fehlgruende[:2])


def urteil_bilden(checkpoint, beweisstand):
    """Bildet das Urteil eines Checkpoints aus Beweisen und genannten Klassen.

    Ein Eintrag ohne benannten Beweis kann nie bestehen: Die blosse Behauptung
    ist kein Nachweis. Genannte Klassen kommen als Bedingung hinzu, weil Regel 7
    kein totes System duldet.
    """
    belege = list(beweisstand.beweis_belege(checkpoint))
    belege.extend(beweisstand.klassen_belege(checkpoint))
    return Urteil(checkpoint, belege)


def beurteilen(eintraege, beweisstand):
    """Urteilt jeden Checkpoint als Liste von Urteilen in Dokument-Reihenfolge."""
    return [urteil_bilden(eintrag, beweisstand) for eintrag in eintraege]


def abhaken(text, urteile):
    """Setzt Haekchen fuer alle offenen, bestandenen Eintraege.

    Zurueck kommen der neue Text und die Liste der abgehakten Kennungen, damit
    der Bericht genau sagen kann, was dieser Lauf geschrieben hat.
    """
    zeilen = text.splitlines()
    abgehakt = []
    for urteil in urteile:
        eintrag = urteil.checkpoint
        if eintrag.status != STATUS_OFFEN or not urteil.bestanden:
            continue
        index = eintrag.zeile - 1
        if index < 0 or index >= len(zeilen):
            continue
        neu = zeile_abhaken(zeilen[index])
        if neu == zeilen[index] or CP_MUSTER.match(neu) is None:
            continue
        zeilen[index] = neu
        abgehakt.append(eintrag.name)
    ergebnis = "\n".join(zeilen)
    if text.endswith("\n"):
        ergebnis += "\n"
    return ergebnis, abgehakt
