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
from preflight.pruef_version import (STATUSDOKUMENTE, VERSIONSDATEI,
                                     dokument_version, dokumente_finden,
                                     statuszahlen_lesen, statuszahlen_nachziehen,
                                     version_erhoehen, version_lesen,
                                     version_zeile)


def _setze_version(alt, neu):
    """Zieht jedes Projekt-Dokument nach; fehlende Zeilen werden ergaenzt."""
    geaendert = []
    for relativ in dokumente_finden():
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            continue
        text = pfad.read_text(encoding="utf-8")
        if dokument_version(text) == neu:
            continue
        if dokument_version(text) is None:
            # Ein neues Dokument erhaelt die Zeile ohne Aufforderung.
            neu_text = text.rstrip("\n") + "\n\n" + version_zeile(neu) + "\n"
        else:
            neu_text = _versionszeile_ersetzen(text, alt, neu)
        if neu_text != text:
            # newline="\n" ist Pflicht: Ohne die Angabe schreibt Python unter
            # Windows CRLF und der Whitespace-Waechter E042 schlaegt zu Recht an.
            pfad.write_text(neu_text, encoding="utf-8", newline="\n")
            geaendert.append(relativ)
    return geaendert


def _statuszahlen_nachziehen():
    """Zieht Klassen-, Datei- und Szenenzahl in den Dokumenten nach.

    Ohne diese Stufe wuerde die Dokumentation beim naechsten neuen Skript
    wieder eine alte Zahl erzaehlen; der Nachzug haelt sie mechanisch aktuell.
    Der Ersatz tauscht ausschliesslich die Zahl, nie das Substantiv daneben.
    """
    zahlen = statuszahlen_lesen()
    geaendert = []
    for relativ in STATUSDOKUMENTE:
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            continue
        text = pfad.read_text(encoding="utf-8")
        neu_text = statuszahlen_nachziehen(text, zahlen)
        if neu_text != text:
            pfad.write_text(neu_text, encoding="utf-8", newline="\n")
            geaendert.append(relativ)
    return zahlen, geaendert


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
    parser.add_argument("--nachziehen", action="store_true",
                        help="Dokumente an die bestehende Version anpassen, ohne sie zu erhoehen")
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
        for relativ in dokumente_finden():
            pfad = PROJEKT_STAMM / relativ
            eigene = dokument_version(pfad.read_text(encoding="utf-8"))
            marke = "ok" if eigene == aktuell else "ABWEICHUNG"
            print("  %-56s %s %s" % (relativ, eigene or "-", marke))
            if eigene != aktuell:
                abweichungen += 1
        print("Abweichungen: %d" % abweichungen)
        return 0 if abweichungen == 0 else 1

    if argumente.nachziehen:
        # Reiner Nachzug: Die Version bleibt, jedes Dokument wird angeglichen.
        geaendert = _setze_version(aktuell, aktuell)
        zahlen, zahlen_geaendert = _statuszahlen_nachziehen()
        for relativ in sorted(set(geaendert) | set(zahlen_geaendert)):
            print("  nachgezogen: %s" % relativ)
        print("Nachzug fertig: %d Dokumente angepasst (%d Klassen, %d Dateien, %d Szenen)." %
              (len(set(geaendert) | set(zahlen_geaendert)),
               zahlen["klassen"], zahlen["dateien"], zahlen["szenen"]))
        return 0

    neu = argumente.setzen.strip() if argumente.setzen else version_erhoehen(aktuell)
    if neu is None or dokument_version("Version: %s\n" % neu) != neu:
        print("FEHLER: ungeeignete Zielversion %r; erwartet wird das Format V0.01" % neu)
        return 2
    if neu == aktuell and not argumente.setzen:
        print("Version bleibt %s; nur der Nachzug prueft die Dokumente." % aktuell)
        geaendert = _setze_version(aktuell, aktuell)
        _, zahlen_geaendert = _statuszahlen_nachziehen()
        print("Fertig: %d Dokumente angepasst." % len(set(geaendert) | set(zahlen_geaendert)))
        return 0

    (PROJEKT_STAMM / VERSIONSDATEI).write_text(neu + "\n", encoding="utf-8", newline="\n")
    print("Version: %s -> %s" % (aktuell, neu))
    geaendert = _setze_version(aktuell, neu)
    _, zahlen_geaendert = _statuszahlen_nachziehen()
    for relativ in sorted(set(geaendert) | set(zahlen_geaendert)):
        print("  nachgezogen: %s" % relativ)
    print("Fertig: %d Dokumente angepasst." % len(set(geaendert) | set(zahlen_geaendert)))
    return 0


if __name__ == "__main__":
    raise SystemExit(hauptprogramm())
