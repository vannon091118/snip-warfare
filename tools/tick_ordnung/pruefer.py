# -*- coding: utf-8 -*-
"""Statischer Pruefer der Tick-Ordnung: Der Vertrag wird gegen den Code gehalten.

Eine Zustaendigkeit: Die erklaerte Ordnung aus ordnung.json mit dem echten
Anmeldestand im GDScript vergleichen und jede Abweichung als Befund melden.

Geprueft werden drei Dinge, und alle drei sind mechanisch entscheidbar:

  Erstens die Vollstaendigkeit. Jede Datei, die sich an den Tick anmeldet, muss
  in der Ordnung stehen. Sonst schleicht sich ein Teilnehmer ein, den niemand
  verortet hat, und die Zeitordnung verschiebt sich still.

  Zweitens die Anmeldeform. Kein Skript darf den globalen Autoload-Namen direkt
  lesen; die Uhr wird ueber /root/Weltuhr oder Kern_Weltuhr.bus() aufgeloest und
  vor dem Zugriff auf Null geprueft. Eine ungeschuetzte Anmeldung ist kein
  Schoenheitsfehler, sondern der Nil-Absturz beim naechsten Lauf ohne Autoload.

  Drittens die Ordnung selbst. Die Teilnehmerliste ist luecken- und dublettenfrei
  und in der Reihenfolge abgelegt, in der sie laufen soll.

Aufruf: python tools/tick_ordnung/pruefer.py
"""

import json
import re
import sys
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent
ORDNUNG_PFAD = Path(__file__).resolve().parent / "ordnung.json"

# Ein Anmeldungssatz ist jede Zeile, die den Tick der Uhr verbindet oder prueft.
ANMELDUNG_MUSTER = re.compile(r"(\w+)\.tick\.(connect|is_connected)\s*\(")

# Der blanke globale Autoload-Name. \b vor Weltuhr verhindert, dass
# Kern_Weltuhr oder ein Bezeichner wie _weltuhr faelschlich getroffen wird.
AUTOLOAD_MUSTER = re.compile(r"(?<![\w.])Weltuhr\s*\.")

# Null-Wache: Eine Zeile, die dieselbe Uhr-Referenz gegen Null prueft.
WACHE_MUSTER = r"{ref}\s*(?:!=\s*null|==\s*null)"

# Wie weit vor einer Anmeldung die Wache hoechstens stehen darf.
WACHE_FENSTER = 12

# Die Befundarten. Sie sind benannt, weil der Vertragstest sie liest; ein
# zweiter Aufguss derselben Zeichenkette waere eine zweite Wahrheit.
UNERKLAERT = "UNERKLAERT"
AUTOLOAD = "AUTOLOAD"
UNGESCHUETZT = "UNGESCHUETZT"
ORDNUNG = "ORDNUNG"


class Befund:
    """Ein Vertragsbruch mit Ort und Begruendung."""

    def __init__(self, art, datei, zeile, text):
        self.art = art
        self.datei = datei
        self.zeile = zeile
        self.text = text

    def zeile_text(self):
        """Der Befund als eine deutsche Zeile mit Ort."""
        return "%s | %s:%d | %s" % (self.art, self.datei, self.zeile, self.text)

    def __repr__(self):
        return "Befund(%s, %s:%d)" % (self.art, self.datei, self.zeile)


def ordnung_lesen(pfad=None):
    """Liest die erklaerte Ordnung; bei fehlender oder kaputter Datei None."""
    pfad = ORDNUNG_PFAD if pfad is None else Path(pfad)
    if not pfad.is_file():
        return None
    try:
        daten = json.loads(pfad.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return daten if isinstance(daten, dict) else None


def gd_dateien():
    """Alle GDScript-Dateien des Projekts als (relativer Pfad, Text)."""
    dateien = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.gd")):
        try:
            relativ_pf = pfad.relative_to(PROJEKT_STAMM)
        except ValueError:
            continue
        teile = set(relativ_pf.parts)
        if teile & {".godot", "addons", "__pycache__", ".freebuff"}:
            continue
        try:
            text = pfad.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        relativ = str(relativ_pf).replace("\\", "/")
        dateien.append((relativ, text))
    return dateien


def _zeichenkette_zeile(text, nummer):
    """Die Zeile eines Textes; leere Zeichenkette ausserhalb des Bereichs."""
    zeilen = text.splitlines()
    return zeilen[nummer - 1] if 0 < nummer <= len(zeilen) else ""


def _wache_vorhanden(zeilen, index, ref):
    """Prueft eine Null-Wache derselben Uhr-Referenz vor der Anmeldung.

    Das Fenster ist bewusst endlich: Eine Pruefung irgendwo weit oben in der
    Funktion schuetzt die Anmeldung nicht, weil dazwischen etwas die Referenz
    veraendert haben kann.
    """
    muster = re.compile(WACHE_MUSTER.format(ref=re.escape(ref)))
    anfang = max(0, index - WACHE_FENSTER)
    return any(muster.search(zeile) for zeile in zeilen[anfang:index + 1])


def teilnehmer_sammeln(dateien):
    """Alle Anmeldestellen als Liste aus (Datei, Zeile, Uhr-Referenz, Text)."""
    stellen = []
    for relativ, text in dateien:
        for nummer, zeile in enumerate(text.splitlines(), start=1):
            treffer = ANMELDUNG_MUSTER.search(zeile)
            if treffer is None:
                continue
            stellen.append((relativ, nummer, treffer.group(1), zeile.strip()))
    return stellen


def pruefe_ordnung(ordnung=None, dateien=None):
    """Prueft alle drei Vertragsteile und liefert die Befunde in Reihenfolge."""
    befundungen = []
    ordnung = ordnung_lesen() if ordnung is None else ordnung
    if ordnung is None:
        return [Befund(ORDNUNG, "tools/tick_ordnung/ordnung.json", 1,
                       "Ordnung fehlt oder ist kein lesbares JSON")]

    teilnehmer = ordnung.get("teilnehmer", [])
    dateien = gd_dateien() if dateien is None else dateien

    # Erstens: Vollstaendigkeit. Jede Anmeldestelle braucht ihren Eintrag.
    erklaerte_dateien = [str(eintrag.get("datei", "")) for eintrag in teilnehmer]
    for relativ, nummer, _ref, zeile in teilnehmer_sammeln(dateien):
        if relativ in erklaerte_dateien:
            continue
        if relativ.startswith("tools/"):
            # Laufpruefungen bauen die Uhr selbst nach und gehoeren nicht in
            # die Spielordnung.
            continue
        befundungen.append(Befund(
            UNERKLAERT, relativ, nummer,
            "meldet sich am Tick an, steht aber nicht in der Ordnung: %s" % zeile))

    # Zweitens: Anmeldeform. Kein blanker Autoload, jede Stelle geschuetzt.
    for relativ, text in dateien:
        if relativ == "core/logic/clock/weltuhr.gd":
            continue
        zeilen = text.splitlines()
        for nummer, zeile in enumerate(zeilen, start=1):
            if AUTOLOAD_MUSTER.search(zeile) and not zeile.strip().startswith("#"):
                if "get_node_or_null" in zeile or "Kern_Weltuhr.bus()" in zeile:
                    continue
                befundungen.append(Befund(
                    AUTOLOAD, relativ, nummer,
                    "greift direkt auf den globalen Autoload zu statt auf /root/Weltuhr "
                    "mit Null-Pruefung: %s" % zeile.strip()))
        for nummer, zeile in enumerate(zeilen, start=1):
            treffer = ANMELDUNG_MUSTER.search(zeile)
            if treffer is None or treffer.group(2) != "connect":
                continue
            ref = treffer.group(1)
            if _wache_vorhanden(zeilen, nummer - 1, ref):
                continue
            befundungen.append(Befund(
                UNGESCHUETZT, relativ, nummer,
                "meldet %s.tick ohne Null-Wache und ohne is_connected-Pruefung an" % ref))

    # Drittens: Die Ordnung selbst muss sauber sein, sonst ist sie kein Vertrag.
    if len(erklaerte_dateien) != len(set(erklaerte_dateien)):
        doppelt = sorted({d for d in erklaerte_dateien if erklaerte_dateien.count(d) > 1})
        befundungen.append(Befund(ORDNUNG, "tools/tick_ordnung/ordnung.json", 1,
                                  "Dateien mehrfach erklaert: %s" % ", ".join(doppelt)))
    ohne_grund = [e.get("datei", "?") for e in teilnehmer if not str(e.get("grund", "")).strip()]
    if ohne_grund:
        befundungen.append(Befund(ORDNUNG, "tools/tick_ordnung/ordnung.json", 1,
                                  "Erklaerung ohne Grund: %s" % ", ".join(ohne_grund)))
    return befundungen


def hauptprogramm():
    """Gibt alle Befunde aus und meldet den Ausgang als Rueckgabewert."""
    befundungen = pruefe_ordnung()
    if not befundungen:
        print("Tick-Ordnung OK: %d Teilnehmer, keine Abweichung." %
              len((ordnung_lesen() or {}).get("teilnehmer", [])))
        return 0
    print("TICK-ORDNUNG BEFUNDE (%d):" % len(befundungen))
    for befund in befundungen:
        print("  " + befund.zeile_text())
    return 1


if __name__ == "__main__":
    sys.exit(hauptprogramm())
