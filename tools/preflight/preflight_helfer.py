# -*- coding: utf-8 -*-
"""Preflight Helfer. Eigene Zuständigkeit: Kleine Helfer ohne eigene Domäne."""

import importlib.util
import sys

from .kern import PROJEKT_STAMM


def aktive_codes_gewaehlt(gewaehlt, kategorien: dict) -> set[str]:
    return {c for k in gewaehlt for c in kategorien[k]}


def hilfe_debug_uebersetzer() -> int:
    try:
        h_pfad = PROJEKT_STAMM / "tools" / "debug_uebersetzer.py"
        h_spez = importlib.util.spec_from_file_location("_debug_hilfe", str(h_pfad))
        h_mod = importlib.util.module_from_spec(h_spez)
        sys.modules[h_spez.name] = h_mod
        assert h_spez.loader is not None
        h_spez.loader.exec_module(h_mod)
        print("Godot Debugging Uebersetzer (E016 Parse, E017 unbekannte Definition, E018 Warning/Hidden):")
        for muster, code, hinweis in h_mod.DebugUebersetzer.MUSTER:
            print(f"  {code} | {muster.pattern[:70]:70} | {hinweis}")
    except Exception as hf:
        print(f"Hilfe nicht ladbar: {hf}")
    return 0
