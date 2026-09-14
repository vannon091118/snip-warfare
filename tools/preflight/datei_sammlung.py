# -*- coding: utf-8 -*-
"""Datei Sammlung. Eigene Zuständigkeit: Alle GDScript Dateien sammeln."""

import re
from pathlib import Path

from .fehler_speicher import FehlerSpeicher
from .projekt_stamm import PROJEKT_STAMM


def _verzeichnis_ignoriert(pfad: Path) -> bool:
    rel = pfad.relative_to(PROJEKT_STAMM)
    teile = rel.parts
    if not teile:
        return False
    return teile[0] in {"addons", "mcp_tools", ".godot", ".freebuff", "tools/godot"} or (
        len(teile) > 1 and "/".join(teile[:2]) == "tools/godot"
    )


def lies_dateien(speicher: FehlerSpeicher | None = None) -> list[tuple[Path, str]]:
    dateien: list[tuple[Path, str]] = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.gd")):
        if _verzeichnis_ignoriert(pfad):
            continue
        try:
            code = pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            if speicher is not None:
                speicher.melde("E005", pfad.relative_to(PROJEKT_STAMM), 1, "Datei ist nicht als UTF-8 lesbar")
            continue
        dateien.append((pfad, code))
    return dateien


def klassen_name_lesen(code: str) -> str | None:
    treffer = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M)
    return treffer.group(1) if treffer else None


def zeile_von(code_index: str, suchtext: str) -> int:
    pos = code_index.find(suchtext)
    if pos < 0:
        return 1
    return code_index.count("\n", 0, pos) + 1


def zeile_bei(code_index: str, position: int) -> int:
    return code_index.count("\n", 0, position) + 1
