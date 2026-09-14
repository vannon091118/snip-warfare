# -*- coding: utf-8 -*-
"""Status Zaehlung. Eigene Zuständigkeit: Klassen, Szenen, Tests, Kategorien zaehlen."""

import re

from .kern import PROJEKT_STAMM, klassen_name_lesen, lies_dateien

IGNORIERTE_PRAEFIXE = (
    ".git/",
    ".godot/",
    ".agents/",
    ".kilo/",
    ".pytest_cache/",
    "__pycache__/",
    "node_modules/",
    "addons/",
)

STATUSDOKUMENTE = ("README.md", "ROADMAP.md", "Architektur.md", "INDEX.md")


def statuszahlen_lesen(dateien=None):
    if dateien is None:
        dateien = lies_dateien()
    klassen = {klassen_name_lesen(code) for _, code in dateien}
    klassen.discard(None)
    szenen = [p for p in PROJEKT_STAMM.rglob("*.tscn") if not _pfad_ignoriert(p)]
    return {"klassen": len(klassen), "dateien": len(dateien), "szenen": len(szenen),
            "tests": _testanzahl_lesen(), "kategorien": _kategorieanzahl_lesen()}


def _pfad_ignoriert(pfad):
    relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
    return relativ.startswith(IGNORIERTE_PRAEFIXE)


def _testanzahl_lesen():
    anzahl = 0
    for pfad in sorted(PROJEKT_STAMM.glob("test_*.py")):
        try:
            text = pfad.read_text(encoding="utf-8")
        except OSError:
            continue
        anzahl += len(re.findall(r"^\s*def test_", text, re.M))
    return anzahl


def _kategorieanzahl_lesen() -> int:
    try:
        from .kategorie_register import PRUEFKATEGORIEN
    except ImportError:
        return 0
    return len(PRUEFKATEGORIEN)
