# -*- coding: utf-8 -*-
"""Mechanischer Versionsbump der globalen Projektversion.

V0.01 startet das Projekt, jeder Bump erhoeht um genau 0.01. Der Aufruf hebt
die Version in der Datei VERSION an und zieht jedes Dokument der Liste im
selben Lauf nach, damit Agenten die Dokumentation nicht vergessen koennen.

    python tools/version_bump.py            Version erhoehen und alle Dokumente nachziehen
    python tools/version_bump.py --pruefen  nur melden, ob alles synchron ist
    python tools/version_bump.py --setzen V0.07  genau diese Version setzen

Der Lauf ist idempotent: Wiederholte Aufrufe mit demselben Stand aendern nichts.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from preflight.kern import PROJEKT_STAMM
from preflight.pruef_version import (VERSIONIERTE_DOKUMENTE, VERSIONSDATEI,
                                     dokument_version, version_erhoehen,
                                     version_lesen, version_zeile)


def _setze_version(texte, alt, neu):
    """Ersetzt die Versionszeile in allen Dokumenten; liefert geaenderte Namen."""
    geaendert = []
    for relativ in VERSIONIERTE_DOKUMENTE:
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            print("  fehlt: %s" % relativ)
            continue
        text = pfad.read_text(encoding="utf-8")
        if dokument_version(text) is None:
            print("  ohne Versionszeile: %s wird uebersprungen" % relativ)
            continue
        if dokument_version(text) == neu:
            continue
        neu_text = _versionszeile_ersetzen(text, alt, neu)
        if neu_text != text:
            # newline="\n" ist Pflicht: Ohne die Angabe schreibt Python unter
            # Windows CRLF und der Whitespace-Waechter E042 schlaegt zu Recht an.
            pfad.write_text(neu_text, encoding="utf-8", newline="\n")
            geaendert.append(relativ)
    return geaendert


def _versionszeile_ersetzen(text, alt, neu):
    """Ersetzt ausschliesslich die Versionszeile, nie Fliesstext-Vorkommen."""
    ausgabe = []
    for zeile in text.splitlines():
        gestrippt = zeile.strip()
        if gestrippt.startswith("Version:") or gestrippt.startswith("Version :"):
            fassung = dokument_version(zeile)
            if fassung == alt or fassung is None:
                ausgabe.append(version_zeile(neu))
                continue
        ausgabe.append(zeile)
    ergebnis = "\n".join(ausgabe)
    return ergebnis if ergebnis.endswith("\n") else ergebnis + "\n"


def hauptprogramm():
    parser = argparse.ArgumentParser(description="Globale Version pflegen")
    parser.add_argument("--pruefen", action="store_true", help="nur den Ist-Stand melden")
    parser.add_argument("--setzen", default="", help="genau diese Version setzen, zum Beispiel V0.07")
    # Hinweis fuer den Leser: Alle Schreibzugriffe dieses Werkzeugs nutzen
    # newline="\n", damit die Versionierung nie CRLF in die Dokumente traegt.
    argumente = parser.parse_args()

    aktuell = version_lesen()
    if aktuell is None:
        print("FEHLER: %s fehlt oder traegt keine Version im Format V0.01" % VERSIONSDATEI)
        return 2

    if argumente.pruefen:
        print("Globale Version: %s" % aktuell)
        abweichungen = 0
        for relativ in VERSIONIERTE_DOKUMENTE:
            pfad = PROJEKT_STAMM / relativ
            if not pfad.is_file():
                print("  fehlt: %s" % relativ)
                abweichungen += 1
                continue
            eigene = dokument_version(pfad.read_text(encoding="utf-8"))
            marke = "ok" if eigene == aktuell else "ABWEICHUNG"
            print("  %-16s %s %s" % (relativ, eigene or "-", marke))
            if eigene != aktuell:
                abweichungen += 1
        print("Abweichungen: %d" % abweichungen)
        return 0 if abweichungen == 0 else 1

    neu = argumente.setzen.strip() if argumente.setzen else version_erhoehen(aktuell)
    if neu is None or dokument_version("Version: %s\n" % neu) != neu:
        print("FEHLER: ungeeignete Zielversion %r; erwartet wird das Format V0.01" % neu)
        return 2
    if neu == aktuell:
        print("Version bleibt %s; nichts zu tun." % aktuell)
        return 0

    (PROJEKT_STAMM / VERSIONSDATEI).write_text(neu + "\n", encoding="utf-8", newline="\n")
    print("Version: %s -> %s" % (aktuell, neu))
    geaendert = _setze_version(VERSIONIERTE_DOKUMENTE, aktuell, neu)
    for relativ in geaendert:
        print("  nachgezogen: %s" % relativ)
    print("Fertig: %d Dokumente angepasst." % len(geaendert))
    return 0


if __name__ == "__main__":
    raise SystemExit(hauptprogramm())
