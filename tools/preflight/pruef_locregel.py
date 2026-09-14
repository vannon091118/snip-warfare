# -*- coding: utf-8 -*-
"""Prüfkategorie locregel (E041): Die 100-LOC-Regel als Architektur-Erzwingung.

Differenzierte Zeilen-Grenzen je Datei-Suffix, nur für GD-Klassen in den
Fach-Ordnern. Ein God-File scheitert am rot fallenden Commit, nicht an der
Disziplin. Ausnahmen (nie geprüft): tools/*, lauf_pruefung_*.gd, test_*.py,
shinon/*.py, *.tscn.

Die Ausnahme-Liste ist geschlossen: Der Nachlass wurde am Ende abgearbeitet,
die Grenze gilt jetzt ohne Ausnahme. Wer eine Verantwortung auslagern will,
baut eine eigene Maschine; wer die Grenze reißt, fällt rot.
"""

import re

from .kern import PROJEKT_STAMM, fehler

GRENZEN_NACH_SUFFIX = (
    ("_basis.gd", 80),
    ("_registry.gd", 100),
    ("_mutation", 60),
    ("_maschine.gd", 120),
    ("_manager.gd", 150),
    ("_status.gd", 120),
    ("_darsteller.gd", 100),
)

GRENZEN_NAME_ERGAENZUNG = {
    "_mutation": "_mutation*.gd",
}

GEPRUEFTE_ORDNER = ("game/", "world/", "core/", "economy/", "population/", "military/")

WERKSTATT_ORDNER = ("tools/preflight/", "tools/sonden/", "tools/warteschlange/")
WERKSTATT_GRENZE_PY = 120
WERKSTATT_EINZELDATEIEN = ("tools/preflight.py",)
IGNORIERTE_WERKSTATT_DATEIEN = ("tools/preflight/selbsttest.py",)


def _grenze_fuer(datei_name: str):
    name = datei_name.lower()
    for suffix, grenze in GRENZEN_NACH_SUFFIX:
        if suffix == "_mutation":
            if "_mutation" in name and name.endswith(".gd"):
                return grenze, GRENZEN_NAME_ERGAENZUNG["_mutation"]
            continue
        if name.endswith(suffix):
            return grenze, suffix
    return None, None


def _pruefe_werkstatt_py() -> None:
    """Eigene Teilzuständigkeit: Python-Werkstatt unter 120 Zeilen halten."""
    kandidaten: list[str] = []
    for ordner in WERKSTATT_ORDNER:
        stamm = PROJEKT_STAMM / ordner
        if not stamm.is_dir():
            continue
        for pfad in stamm.rglob("*.py"):
            rel = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
            if rel in IGNORIERTE_WERKSTATT_DATEIEN:
                continue
            kandidaten.append(rel)
    for rel in WERKSTATT_EINZELDATEIEN:
        kandidaten.append(rel)
    for rel in sorted(set(kandidaten)):
        pfad = PROJEKT_STAMM / rel
        if not pfad.is_file():
            continue
        try:
            code = pfad.read_text(encoding="utf-8")
        except OSError:
            continue
        zeilen = code.count("\n") + 1 if code else 0
        if zeilen > WERKSTATT_GRENZE_PY:
            fehler("E041", rel, 1,
                   "Werkstatt-Grenze verletzt: %d Zeilen in %s, erlaubt sind %d; "
                   "verantworte in eigene Module teilen" %
                   (zeilen, rel, WERKSTATT_GRENZE_PY))


def pruefe_locregel(dateien) -> None:
    """E041: Zeilen-Grenze je Suffix, ohne Ausnahme und ohne Nachlass."""
    _pruefe_werkstatt_py()
    for pfad, code in dateien:
        rel = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        normalisiert = rel.lower()
        # Ausnahmen: Werkzeuge, Lauf-Prüfungen, Tests, Shinon, Szenen.
        # Fach-Ordner prüft Suffix-Grenzen; Werkstatt prüft oben py-Grenze.
        if rel.startswith("tools/"):
            continue
        if normalisiert.startswith("lauf_pruefung_"):
            continue
        if pfad.name.lower().startswith("lauf_pruefung_"):
            continue
        if not rel.endswith(".gd"):
            continue
        if not any(normalisiert.startswith(ordner) for ordner in GEPRUEFTE_ORDNER):
            continue
        # Nur Klassen-Dateien prüfen; Szenen-Skripte ohne class_name ruhen auf
        # ihrer Szene und fallen nicht unter die Grenze.
        if re.search(r"^class_name\s+[A-Za-z_][A-Za-z0-9_]*", code, re.M) is None:
            continue
        grenze, suffix_label = _grenze_fuer(pfad.name)
        if grenze is None:
            continue
        zeilen_zahl = code.count("\n") + 1
        if zeilen_zahl <= grenze:
            continue
        fehler("E041", rel, 1,
               "Zeilen-Grenze verletzt: %d Zeilen in einer %s-Datei, erlaubt sind %d; "
               "die Verantwortung gehoert in eigene Maschinen" %
               (zeilen_zahl, suffix_label, grenze))
