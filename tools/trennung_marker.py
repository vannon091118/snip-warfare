# -*- coding: utf-8 -*-
"""Setzt die Trennungskommentare in GDScript-Klassendateien mechanisch.

Die Projektverfassung verlangt, dass jede Klasse ihre Datenseite und ihre
Logikseite markiert. Dieses Werkzeug liest eine Klassen-Datei, findet den
ersten Zustand (``var`` auf Klassenebene) und die erste Methode (``func``) und
setzt dort genau dann einen Marker, wenn er fehlt. Es schreibt nur, wenn sich
etwas aendert, und ist idempotent.

    python tools/trennung_marker.py            alle Dateien anzeigen und setzen
    python tools/trennung_marker.py --pruefen  nur melden, nichts schreiben
"""

import argparse
import re
import sys
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent

# Ordner, die nie zum Projektvertrag gehoeren.
IGNORIERTE_TEILE = {".git", ".godot", ".freebuff", ".agents", ".kilo",
                    "__pycache__", "addons", "node_modules", ".pytest_cache"}

MARKER_DATEN = "## Kategorie daten"
MARKER_LOGIK = "## Kategorie logik"

KLASSEN_MUSTER = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
FELD_MUSTER = re.compile(r"^var\s+[A-Za-z_]", re.M)
METHODEN_MUSTER = re.compile(r"^(?:static\s+)?func\s+[A-Za-z_]", re.M)


def _zeile_von(text, position):
    return text.count("\n", 0, position) + 1


def marker_plan(text):
    """Liefert die fehlenden Marker als Liste (zeile, marker, text)."""
    plan = []
    if MARKER_DATEN not in text:
        treffer = FELD_MUSTER.search(text)
        if treffer is not None:
            plan.append((_zeile_von(text, treffer.start()), MARKER_DATEN))
    if MARKER_LOGIK not in text:
        treffer = METHODEN_MUSTER.search(text)
        if treffer is not None:
            plan.append((_zeile_von(text, treffer.start()), MARKER_LOGIK))
    return plan


def marker_setzen(text):
    """Fuegt fehlende Marker ein und liefert den neuen Text."""
    plan = marker_plan(text)
    if not plan:
        return text
    zeilen = text.splitlines()
    # Von unten nach oben einfuegen, damit die Zeilennummern gueltig bleiben.
    for zeile, marker in sorted(plan, reverse=True):
        zeilen.insert(zeile - 1, marker)
    ergebnis = "\n".join(zeilen)
    return ergebnis if text.endswith("\n") or not text else ergebnis + "\n"


def klassen_dateien():
    """Alle GDScript-Klassendateien des Projekts, sortiert."""
    gefunden = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.gd")):
        if IGNORIERTE_TEILE.intersection(pfad.parts):
            continue
        try:
            text = pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if KLASSEN_MUSTER.search(text) is None:
            continue
        gefunden.append((pfad, text))
    return gefunden


def hauptprogramm():
    parser = argparse.ArgumentParser(description="Trennungskommentare setzen")
    parser.add_argument("--pruefen", action="store_true",
                        help="nur melden, welche Marker fehlen")
    argumente = parser.parse_args()
    gesetzt = 0
    fehlend = 0
    for pfad, text in klassen_dateien():
        plan = marker_plan(text)
        if not plan:
            continue
        fehlend += len(plan)
        relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        for zeile, marker in plan:
            print("  %s:%d  %s" % (relativ, zeile, marker))
        if not argumente.pruefen:
            pfad.write_text(marker_setzen(text), encoding="utf-8", newline="\n")
            gesetzt += len(plan)
    if argumente.pruefen:
        print("Fehlende Marker: %d" % fehlend)
        return 0 if fehlend == 0 else 1
    print("Gesetzte Marker: %d" % gesetzt)
    return 0


if __name__ == "__main__":
    sys.exit(hauptprogramm())
