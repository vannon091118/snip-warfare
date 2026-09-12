# -*- coding: utf-8 -*-
"""Pruefkategorie index (E044): Die Index-Familie muss zum Code passen.

Die drei erzeugten Indizes werden beim Preflight im Speicher neu berechnet und
Zeile fuer Zeile mit der Datei verglichen. Wer eine Index-Datei von Hand
verbessert oder nach einem Umbau nicht neu erzeugt, bekommt E044 mit Datei und
echter Zeile. Die eine Last-Datei wird nicht auf Gleichheit geprueft, denn ihr
Bericht haengt am letzten Lauf; geprueft wird ihr maschineller Standblock.
"""

import sys
from pathlib import Path

from .kern import PROJEKT_STAMM, fehler

TOOLS_ORDNER = Path(__file__).resolve().parent.parent
if str(TOOLS_ORDNER) not in sys.path:
    sys.path.insert(0, str(TOOLS_ORDNER))

from index.erzeugen import erwartete_texte, stand_berechnen  # noqa: E402
from index.kern import (MARKER_ENDE, MARKER_START,  # noqa: E402
                        block_zwischen, erste_abweichung)
from index.letzte_aenderung import STAND_ENDE, STAND_START  # noqa: E402


def pruefe_index(dateien=None):
    """E044: Jede Index-Datei traegt genau den Stand, den der Code vorgibt."""
    stand = stand_berechnen(dateien)
    erwartet = erwartete_texte(stand)
    for relativ, soll_text in erwartet.items():
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            fehler("E044", relativ, 1,
                   "Index-Datei fehlt; python tools/index_generieren.py erzeugt sie")
            continue
        vorhanden = pfad.read_text(encoding="utf-8")
        if relativ == "INDEX.md":
            _pruefe_block(relativ, vorhanden, soll_text)
            continue
        if relativ == "INDEX_LETZTE_AENDERUNG.md":
            _pruefe_last(relativ, vorhanden, soll_text)
            continue
        _pruefe_ganz(relativ, vorhanden, soll_text)


def _pruefe_ganz(relativ, vorhanden, soll_text):
    """Vergleicht eine vollstaendig erzeugte Index-Datei."""
    abweichung = _abweichung(vorhanden, soll_text)
    if abweichung is None:
        return
    zeile, soll, ist = abweichung
    fehler("E044", relativ, zeile,
           "Index ist nicht aktuell (%s statt %s); python tools/index_generieren.py "
           "erzeugt die Datei neu" % (_kurz(ist), _kurz(soll)))


def _pruefe_block(relativ, vorhanden, soll_text):
    """Vergleicht nur den auto-generierten Marker-Block des Root-Index."""
    soll_block = block_zwischen(soll_text, MARKER_START, MARKER_ENDE)
    ist_block = block_zwischen(vorhanden, MARKER_START, MARKER_ENDE)
    if ist_block is None:
        fehler("E044", relativ, 1,
               "Marker %s und %s fehlen; python tools/index_generieren.py erzeugt den "
               "Block neu" % (MARKER_START, MARKER_ENDE))
        return
    abweichung = _abweichung(ist_block, soll_block)
    if abweichung is None:
        return
    zeile, soll, ist = abweichung
    fehler("E044", relativ, _block_zeile(vorhanden, MARKER_START) + zeile - 1,
           "auto-generierter Block ist nicht aktuell (%s statt %s); python "
           "tools/index_generieren.py erzeugt ihn neu" % (_kurz(ist), _kurz(soll)))


def _pruefe_last(relativ, vorhanden, soll_text):
    """Prueft Existenz, Versionszeile und den maschinellen Standblock."""
    if STAND_START not in vorhanden or STAND_ENDE not in vorhanden:
        fehler("E044", relativ, 1,
               "maschineller Standblock fehlt; python tools/index_generieren.py legt "
               "genau diese eine Last-Datei neu an")
        return
    # Der Soll-Text ist bereits genau der Standblock zwischen den Markern.
    soll_block = soll_text
    ist_block = vorhanden[vorhanden.index(STAND_START):vorhanden.index(STAND_ENDE)]
    abweichung = _abweichung(ist_block, soll_block)
    if abweichung is None:
        return
    zeile, soll, ist = abweichung
    fehler("E044", relativ, _block_zeile(vorhanden, STAND_START) + zeile - 1,
           "Standblock ist nicht aktuell (%s statt %s); python tools/index_generieren.py "
           "zieht ihn nach" % (_kurz(ist), _kurz(soll)))


def _abweichung(vorhanden, soll):
    """Erste abweichende Zeile zweier Texte oder None."""
    return erste_abweichung(soll, vorhanden)


def _block_zeile(text, marker):
    """Zeilennummer der Markerzeile in einer Datei."""
    for nummer, zeile in enumerate(text.splitlines(), start=1):
        if marker in zeile:
            return nummer
    return 1


def _kurz(text):
    """Kuerzt eine Zeile fuer die Meldung auf lesbare Laenge."""
    gekuerzt = text.strip()
    return (gekuerzt[:70] + "...") if len(gekuerzt) > 73 else gekuerzt
