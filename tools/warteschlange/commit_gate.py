# -*- coding: utf-8 -*-
"""Commit Gate. Eigene Zuständigkeit: Shinon + Preflight für einen Slice."""

import sys

from .git_dateien import lauf


def preflight_fuer_slice(slice_dateien: list[str]) -> bool:
    kategorie = "klassen,trennung,determinismus,pfade,registries,whitespace"
    if any(d.startswith("shinon/") for d in slice_dateien):
        kategorie += ",shinon"
    if any(d.startswith("tools/") for d in slice_dateien):
        kategorie += ",locregel,index,version"
    code, out, err = lauf([sys.executable, "tools/preflight.py", "--kategorie", kategorie, "--ohne-godot"])
    if code != 0:
        print(out + err)
        return False
    return True


def shinon_gruen() -> bool:
    try:
        from shinon.shinon_gate import ShinonGate
        befunde = ShinonGate().pruefen()
        if befunde:
            for b in befunde:
                print(f"  {b.code} | {b.datei}:{b.zeile} | {b.text}")
            return False
        return True
    except Exception as e:
        print(f"Shinon Gate nicht ladbar: {e}")
        return False
