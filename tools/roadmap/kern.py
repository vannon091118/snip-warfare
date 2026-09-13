# -*- coding: utf-8 -*-
"""Gemeinsame Grundlagen des Roadmap-Abgleichs.

Hier steht genau einmal, was alle Bausteine brauchen: der Projektstamm, der
Pfad der einen Roadmap, die Muster der Checkpoint-Zeilen und das Schreiben von
Markdown mit LF. Jeder Baustein importiert von hier, damit Parser, Beweislauf
und Schreiber dieselbe Wirklichkeit sehen.

Als Beweis gilt ausschliesslich eine ausfuehrbare Pruefung: eine Pytest-Datei
test_*.py oder eine Laufpruefung tools/lauf_pruefung_*.gd. Ein Datenpfad wie
world/data/gebaeude.json ist beschriebener Gegenstand, kein Beweis, und wird
deshalb nie als Beweis gelesen.
"""

import re
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent

ROADMAP_PFAD = "ROADMAP.md"

# Checkpoint-Kopfzeile, zum Beispiel
#   "- [x] **CP-0.1 (Weltuhr):** Kern_Weltuhr ..."
#   "- [ ] **CP-6.1:** Ui_AuswahlMarkierung ..."
CP_MUSTER = re.compile(
    r"^(?P<einzug>\s*)- \[(?P<status>[ xX~])\] "
    r"\*\*(?P<nummer>CP-[0-9A-Za-z.]+)"
    r"(?:\s*\((?P<klammer>[^)]*)\))?:?\*\*"
    r"(?P<rest>.*)$"
)

# Kapitel-Ueberschrift jeder Ebene; traegt den Slice-Namen eines CP.
KAPITEL_MUSTER = re.compile(r"^(?P<raute>#{2,4})\s+(?P<titel>.+?)\s*$")

# Beweis-Artefakte: nur ausfuehrbare Pruefungen zaehlen.
PY_BEWEIS_MUSTER = re.compile(r"`?(test_[A-Za-z0-9_]+\.py)`?")
GD_BEWEIS_MUSTER = re.compile(r"`?(tools/lauf_pruefung_[A-Za-z0-9_]+\.gd)`?")

# Genannte Klassen: Rueckwaerts-Anfuehrungszeichen plus Grossbuchstabe plus
# Unterstrich. Damit faellt _startbestand_einbuchen (Funktion) und ziel_tags
# (Feld) heraus; Welt_BaustellenBedarf und Ui_BauPanel bleiben stehen.
KLASSE_MUSTER = re.compile(r"`([A-Z][A-Za-z0-9]*_[A-Za-z0-9_]+)`")

# Zustaende einer CP-Zeile in ihrer Reihenfolge der Verbindlichkeit.
STATUS_OFFEN = " "
STATUS_TEILWEISE = "~"
STATUS_FERTIG = "x"


def roadmap_lesen():
    """Liest die eine Roadmap aus dem Projektstamm; ohne Datei None."""
    pfad = PROJEKT_STAMM / ROADMAP_PFAD
    if not pfad.is_file():
        return None
    return pfad.read_text(encoding="utf-8")


def markdown_schreiben(text):
    """Schreibt die Roadmap mit LF und genau einem Abschluss-Newline.

    newline="\\n" ist Pflicht: Ohne die Angabe schreibt Python unter Windows
    CRLF und der Whitespace-Waechter E042 meldet die frische Datei zu Recht.
    """
    if not text.endswith("\n"):
        text += "\n"
    pfad = PROJEKT_STAMM / ROADMAP_PFAD
    alt = pfad.read_text(encoding="utf-8") if pfad.is_file() else None
    pfad.write_text(text, encoding="utf-8", newline="\n")
    return alt != text


def zeile_abhaken(zeile):
    """Setzt das Haekchen einer offenen CP-Zeile, ohne sonst etwas zu tauschen."""
    return re.sub(r"^(\s*)- \[ \]", r"\1- [x]", zeile, count=1)


def beweis_pfade_aus(text):
    """Alle ausfuehrbaren Beweise eines CP-Textes, sortiert und ohne Dubletten."""
    treffer = set(PY_BEWEIS_MUSTER.findall(text))
    treffer.update(GD_BEWEIS_MUSTER.findall(text))
    return sorted(treffer)


def klassen_aus(text):
    """Alle genannten Klassennamen eines CP-Textes, sortiert und ohne Dubletten."""
    return sorted(set(KLASSE_MUSTER.findall(text)))


def datei_existiert(relativ):
    """Prueft einen relativen Pfad gegen den Projektstamm."""
    return (PROJEKT_STAMM / relativ).is_file()
