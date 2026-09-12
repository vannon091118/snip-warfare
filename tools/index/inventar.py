# -*- coding: utf-8 -*-
"""Klasseninventar je Domaene: die Datenquelle aller drei Indizes.

Eine Zuständigkeit: Aus den GDScript-Dateien des Projekts die Klassen, ihre
Datei, ihre Zeilenzahl und den Fingerabdruck je Domaene lesen. Der Root-Index,
der Domaenen-Index und die Last-Datei lesen alle aus diesem einen Ergebnis.
"""

from .kern import (ALLE_DOMAENEN, DOMAENEN, KLASSEN_MUSTER, REST_DOMAENE,
                   fingerprint, gd_dateien, klassen_name_holen)


def inventar_sammeln(dateien=None):
    """Liefert je Domaene die Klassen als (Name, Pfad, Zeilenzahl).

    Klassen ohne Domaenen-Ordner landen im Auffangkorb `rest`, damit die
    Matrix keine echte Arbeit als leere Zeile verschweigt.
    """
    dateien = gd_dateien() if dateien is None else dateien
    inventar = {schluessel: [] for schluessel, _k, _p, _o in ALLE_DOMAENEN}
    for relativ, code in dateien:
        name = klassen_name_holen(code)
        if name is None:
            continue
        for schluessel, _kuerzel, _praefix, ordner in DOMAENEN:
            if relativ.startswith(ordner):
                inventar[schluessel].append((name, relativ, code.count("\n") + 1))
                break
        else:
            inventar[REST_DOMAENE[0]].append((name, relativ, code.count("\n") + 1))
    return inventar


def project_klassen(dateien=None):
    """Jede Klasse des Projekts als (Name, Pfad), unabhaengig vom Ordner."""
    dateien = gd_dateien() if dateien is None else dateien
    gefunden = []
    for relativ, code in dateien:
        name = KLASSEN_MUSTER.search(code)
        if name is not None:
            gefunden.append((name.group(1), relativ))
    return sorted(gefunden)


def dateien_je_domaene(dateien=None):
    """Zaehlt die GDScript-Dateien je Domaene; der Auffangkorb zaehlt mit."""
    dateien = gd_dateien() if dateien is None else dateien
    zaehler = {schluessel: 0 for schluessel, _k, _p, _o in ALLE_DOMAENEN}
    for relativ, _code in dateien:
        for schluessel, _kuerzel, _praefix, ordner in DOMAENEN:
            if relativ.startswith(ordner):
                zaehler[schluessel] += 1
                break
        else:
            zaehler[REST_DOMAENE[0]] += 1
    return zaehler, 0


def fingerabdruecke(inventar):
    """Fingerabdruck der Klassennamen je Domaene fuer den Delta-Vergleich."""
    return {schluessel: fingerprint(name for name, _pfad, _zeilen in eintraege)
            for schluessel, eintraege in inventar.items()}


def gesamt_klassen(inventar):
    """Anzahl aller Klassen in den Domaenen-Ordnern."""
    return sum(len(eintraege) for eintraege in inventar.values())
