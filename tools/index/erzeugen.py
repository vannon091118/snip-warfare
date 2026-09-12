# -*- coding: utf-8 -*-
"""Orchestrierung der Index-Familie.

Eine Zuständigkeit: Den Stand berechnen und den Root-, den Domaenen- und den
Datenindex samt der einen Last-Datei schreiben. Dieses Modul kennt die
Reihenfolge, nicht die Inhalte. Die einzelnen Bausteine liefern Texte, hier
werden sie nacheinander bedient, damit alle vier Indizes denselben Stand sehen.
"""

from .daten import pools_sammeln, zusammenfassung as daten_zahlen
from .inventar import (dateien_je_domaene, fingerabdruecke, inventar_sammeln,
                       project_klassen)
from .matrix import array_sammeln, signal_sammeln, zusammenfassung
from . import daten_index, domaenen_index, letzte_aenderung, root_index


def stand_berechnen(dateien=None):
    """Der eine Stand: Inventar, Signale, Arrays, Pools und alle Kennzahlen."""
    from .kern import gd_dateien, normalisiere
    dateien = gd_dateien() if dateien is None else normalisiere(dateien)
    inventar = inventar_sammeln(dateien)
    signale, offen = signal_sammeln(dateien)
    arrays = array_sammeln(dateien)
    pools = pools_sammeln(dateien)
    dateien_zaehler, ohne_domaene = dateien_je_domaene(dateien)
    zahlen = {
        "klassen": len(project_klassen(dateien)),
        "dateien": len(dateien),
        "signale": zusammenfassung(signale, arrays)["signale"],
        "array_typen": zusammenfassung(signale, arrays)["array_typen"],
        "pools": daten_zahlen(pools)["pools"],
    }
    domaenenstand = {}
    for schluessel, abdruck in fingerabdruecke(inventar).items():
        domaenenstand[schluessel] = {
            "klassen": len(inventar.get(schluessel, [])),
            "dateien": dateien_zaehler.get(schluessel, 0),
            "fingerabdruck": abdruck,
        }
    return {
        "inventar": inventar,
        "signale": signale,
        "offen": offen,
        "arrays": arrays,
        "pools": pools,
        "dateien": dateien_zaehler,
        "ohne_domaene": ohne_domaene,
        "zahlen": zahlen,
        "domaenenstand": domaenenstand,
    }


def schreiben(stand):
    """Schreibt Root-, Domaenen- und Datenindex und danach die eine Last-Datei."""
    geaendert = []
    if root_index.schreiben(stand["inventar"], stand["signale"], stand["arrays"],
                            stand["zahlen"])[0]:
        geaendert.append(root_index.INDEX_PFAD)
    if domaenen_index.schreiben(stand["inventar"], stand["signale"], stand["offen"],
                                stand["arrays"], stand["dateien"]):
        geaendert.append(domaenen_index.DATEI)
    if daten_index.schreiben(stand["pools"]):
        geaendert.append(daten_index.DATEI)
    last_geaendert, delta = letzte_aenderung.schreiben(stand["zahlen"],
                                                       stand["domaenenstand"])
    if last_geaendert:
        geaendert.append(letzte_aenderung.DATEI)
    return geaendert, delta


def neu_erzeugen(dateien=None, bericht=True):
    """Berechnet den Stand, schreibt die vier Indizes und meldet das Ergebnis."""
    stand = stand_berechnen(dateien)
    geaendert, delta = schreiben(stand)
    if bericht:
        for name in geaendert:
            print("  geschrieben: %s" % name)
        print("Index-Familie: %d Dateien geschrieben, %d Klassen, %d Signale, "
              "%d Array-Elementtypen, %d Pools."
              % (len(geaendert), stand["zahlen"]["klassen"], stand["zahlen"]["signale"],
                 stand["zahlen"]["array_typen"], stand["zahlen"]["pools"]))
        for satz in delta:
            print("  letzte Aenderung: %s" % satz)
    return stand, geaendert, delta


def erwartete_texte(stand):
    """Die Soll-Texte der vier Dateien fuer den Waechter, ohne zu schreiben."""
    return {
        root_index.INDEX_PFAD: root_index.erwarteter_block(
            stand["inventar"], stand["signale"], stand["arrays"], stand["zahlen"]),
        domaenen_index.DATEI: domaenen_index.erwarteter_text(
            stand["inventar"], stand["signale"], stand["offen"], stand["arrays"],
            stand["dateien"]),
        daten_index.DATEI: daten_index.erwarteter_text(stand["pools"]),
        letzte_aenderung.DATEI: letzte_aenderung.erwarteter_stand_text(
            stand["zahlen"], stand["domaenenstand"]),
    }
