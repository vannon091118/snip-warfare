# -*- coding: utf-8 -*-
"""Statuszahlen Werkzeuge. Fassade über echte Teil-Domänen."""

from .status_muster import STATUSMUSTER, PAARFORM_MUSTER, BADGE_MUSTER
from .status_zaehlung import STATUSDOKUMENTE, statuszahlen_lesen


def paarformen_aufloesen(text):
    return PAARFORM_MUSTER.sub(lambda t: "%s %s" % (t.group(2), t.group(3)), text)


def badge_nachziehen(text, zahlen):
    zahl = str(zahlen["tests"])
    return BADGE_MUSTER.sub(
        lambda t: "%s%s%s%s%s" % (t.group("vorn"), zahl, t.group("mitte"), zahl, t.group("hinten")),
        text,
    )


def badge_verletzungen(text, zahlen):
    verletzungen = []
    for treffer in BADGE_MUSTER.finditer(text):
        zeile = text[:treffer.start()].count("\n") + 1
        ist = int(treffer.group("zahl"))
        soll = zahlen["tests"]
        if ist != soll or int(treffer.group("zwei")) != soll:
            verletzungen.append((zeile, "tests", ist, soll))
    return verletzungen


def statuszahl_ersetzen(text, muster, zahl):
    return muster.sub(lambda treffer: str(zahl) + treffer.group("rest"), text)


def statuszahlen_nachziehen(text, zahlen):
    text = paarformen_aufloesen(text)
    text = badge_nachziehen(text, zahlen)
    for muster, schluessel in STATUSMUSTER:
        text = statuszahl_ersetzen(text, muster, zahlen[schluessel])
    return text


def statuszahlen_verletzungen(text, zahlen):
    verletzungen = []
    text = paarformen_aufloesen(text)
    verletzungen.extend(badge_verletzungen(text, zahlen))
    for nummer, zeile in enumerate(text.splitlines(), start=1):
        for muster, schluessel in STATUSMUSTER:
            for treffer in muster.finditer(zeile):
                ist = int(treffer.group("zahl"))
                soll = zahlen[schluessel]
                if ist != soll:
                    verletzungen.append((nummer, schluessel, ist, soll))
    return verletzungen


__all__ = [
    "STATUSDOKUMENTE",
    "STATUSMUSTER",
    "PAARFORM_MUSTER",
    "BADGE_MUSTER",
    "paarformen_aufloesen",
    "badge_nachziehen",
    "badge_verletzungen",
    "statuszahlen_lesen",
    "statuszahl_ersetzen",
    "statuszahlen_nachziehen",
    "statuszahlen_verletzungen",
]
