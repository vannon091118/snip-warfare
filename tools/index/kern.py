# -*- coding: utf-8 -*-
"""Gemeinsame Grundlagen des Index-Pakets.

Hier steht genau einmal, was alle Index-Bausteine brauchen: der Projektstamm,
die eine Domaenenliste, das Lesen der Dateien je Domaene, das Lesen der
globalen Version und das Schreiben von Markdown ohne CRLF. Jeder Index-Baustein
importiert von hier, damit Root-, Domaenen- und Datenindex dieselbe Wirklichkeit
sehen.
"""

import hashlib
import re
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent

# Die eine Domaenenliste. Schluessel, Kuerzel fuer Matrix-Spalten, Praefix und
# Ordner. Kuerzel bleiben kurz, weil die Signal- und Array-Matrix je Domaene
# eine eigene Spalte traegt und die Tabelle sonst unlesbar breit wird.
DOMAENEN = (
    ("core", "kern", "Kern_", "core/"),
    ("world/generator", "gen", "Welt_", "world/logic/kategorie_generator/"),
    ("world/welt", "welt", "Welt_", "world/logic/kategorie_welt/"),
    ("world/objekt", "obj", "Objekt_/Gebaeude_", "world/logic/kategorie_objekt/"),
    ("world/tier", "tier", "Tier_", "world/logic/kategorie_tier/"),
    ("world/orchestrator", "orch", "Orchestrator_", "world/logic/kategorie_orchestrator/"),
    ("game/einheit", "ein", "Einheit_", "game/logic/kategorie_einheit/"),
    ("game/job", "job", "Job_", "game/logic/kategorie_job/"),
    ("game/ressourcen", "res", "Resource_", "game/logic/kategorie_ressourcen/"),
    ("population", "pop", "Pop_", "population/"),
    ("economy", "lager", "Lager_", "economy/"),
    ("ui", "ui", "Ui_", "ui/"),
    ("shinon", "shinon", "Shinon_", "shinon/"),
    ("tools", "tools", "-", "tools/"),
)

# Auffangkorb: Klassen, die in keinem der Domaenen-Ordner liegen. Sie duerfen
# nicht unsichtbar werden, sonst zeigt die Matrix Striche fuer echte Arbeit.
REST_DOMAENE = ("rest", "rest", "-", "(kein Domaenen-Ordner)")
ALLE_DOMAENEN = DOMAENEN + (REST_DOMAENE,)

# Spalten der Signal- und Array-Matrix: eine je Domaene plus der Auffangkorb.
MATRIX_KUERZEL = tuple(kuerzel for _s, kuerzel, _p, _o in ALLE_DOMAENEN)

# Ordner, die nie zum Projektvertrag gehoeren.
IGNORIERTE_TEILE = {".git", ".godot", ".freebuff", ".agents", ".kilo",
                    "__pycache__", "addons", "node_modules", ".pytest_cache"}

MARKER_START = "<!-- INVENTAR:START -->"
MARKER_ENDE = "<!-- INVENTAR:ENDE -->"

VERSIONSDATEI = "VERSION"

QUELLE = "`python tools/index_generieren.py`"

KLASSEN_MUSTER = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
# Ein Signal darf Klammern tragen oder ohne sie dastehen; beides ist Gueltiges.
SIGNAL_MUSTER = re.compile(r"^signal\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:\(|$)", re.M)
# Gesendet und verbunden wird immer ueber `signalname.emit(...)` beziehungsweise
# `signalname.connect(...)`. Der Name vor dem Punkt ist der Signalname, auch bei
# einer Kette wie `_signal_bus.schaden_erhalten.emit(...)`.
SENDEN_MUSTER = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\.emit\s*\(")
VERBINDEN_MUSTER = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\.connect\s*\(")
ARRAY_MUSTER = re.compile(r"Array\[([A-Za-z_][A-Za-z0-9_]*)\]")


def lies_version():
    """Liest die globale Version aus VERSION; ohne Datei ein Strich."""
    pfad = PROJEKT_STAMM / VERSIONSDATEI
    if not pfad.is_file():
        return "-"
    for zeile in pfad.read_text(encoding="utf-8").splitlines():
        if zeile.strip():
            return zeile.strip()
    return "-"


def versionszeile():
    """Die verbindliche Versionszeile jedes Dokuments."""
    return "Version: %s" % lies_version()


def _ignoriert(pfad):
    return bool(IGNORIERTE_TEILE.intersection(pfad.parts))


def gd_dateien():
    """Alle GDScript-Dateien des Projekts als (relativer Pfad, Code)."""
    dateien = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.gd")):
        if _ignoriert(pfad):
            continue
        try:
            code = pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        dateien.append((relativ, code))
    return dateien


def normalisiere(dateien):
    """Nimmt Dateilisten beliebiger Herkunft und liefert (relativer Pfad, Code).

    Der Preflight reicht seine Dateien als (Path, Code) herein; das Index-Paket
    arbeitet mit relativen Pfaden, weil Domaene und Matrix daran haengen.
    """
    ergebnis = []
    for pfad, code in dateien:
        if isinstance(pfad, str):
            ergebnis.append((pfad, code))
            continue
        relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        ergebnis.append((relativ, code))
    return ergebnis


def klassen_name_holen(code):
    """Liest den class_name einer Quelldatei; ohne Treffer None."""
    treffer = KLASSEN_MUSTER.search(code)
    return treffer.group(1) if treffer is not None else None


def domaene_von(relativ):
    """Ordnet einen relativen Pfad seiner Domaene zu, sonst None."""
    for schluessel, _kuerzel, _praefix, ordner in DOMAENEN:
        if relativ.startswith(ordner):
            return schluessel
    return None


def kuerzel_von(schluessel):
    """Kuerzel einer Domaene fuer die Matrix-Spalten; None wird zum Auffangkorb."""
    for name, kuerzel, _praefix, _ordner in ALLE_DOMAENEN:
        if name == schluessel:
            return kuerzel
    return REST_DOMAENE[1]


def fingerprint(teile):
    """Kurzer, stabiler Fingerabdruck einer sortierten Namensliste."""
    rohtext = "\n".join(sorted(teile))
    return hashlib.sha1(rohtext.encode("utf-8")).hexdigest()[:12]


def schreibe_markdown(pfad, text):
    """Schreibt Markdown mit LF und genau einem Abschluss-Newline."""
    if not text.endswith("\n"):
        text += "\n"
    pfad = Path(pfad)
    alt = pfad.read_text(encoding="utf-8") if pfad.is_file() else None
    # newline="\n" ist Pflicht: ohne die Angabe schreibt Python unter Windows
    # CRLF und der Whitespace-Waechter E042 meldet die frische Datei zu Recht.
    pfad.write_text(text, encoding="utf-8", newline="\n")
    return alt != text


def erste_abweichung(erwartet, vorhanden):
    """Erste abweichende Zeile zweier Texte als (zeile, erwartet, vorhanden)."""
    erwartete_zeilen = erwartet.splitlines()
    vorhandene_zeilen = vorhanden.splitlines()
    for nummer in range(max(len(erwartete_zeilen), len(vorhandene_zeilen))):
        soll = erwartete_zeilen[nummer] if nummer < len(erwartete_zeilen) else ""
        ist = vorhandene_zeilen[nummer] if nummer < len(vorhandene_zeilen) else ""
        if soll != ist:
            return nummer + 1, soll, ist
    return None


def block_zwischen(text, start, ende):
    """Liest den Block zwischen zwei Markern; ohne Marker None."""
    if start not in text or ende not in text:
        return None
    anfang = text.index(start)
    schluss = text.index(ende) + len(ende)
    return text[anfang:schluss]
