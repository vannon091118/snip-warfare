# -*- coding: utf-8 -*-
"""Godot Uebersetzer. Eigene Zuständigkeit: Godot-Zeilen in E016-E018 übersetzen."""

from .kern import PROJEKT_STAMM, fehler
from .lauf_log_bruecke import lade_lauf_log


def log_zeile_fuer(zeile: str) -> int:
    try:
        lauf_log = lade_lauf_log()
        for index, roh in enumerate(lauf_log.lese_alle("godot_letzter_lauf"), start=1):
            if roh.strip() == zeile.strip():
                return index
    except Exception:
        pass
    return 1


def uebersetze_fundzeilen(fundzeilen: list[str], lauf_log) -> None:
    if not fundzeilen:
        return
    try:
        import importlib.util as _ilu
        import sys as _sys
        dbg_pfad = PROJEKT_STAMM / "tools" / "debug_uebersetzer.py"
        dbg_spez = _ilu.spec_from_file_location("_debug_uebersetzer_lauf", str(dbg_pfad))
        dbg_mod = _ilu.module_from_spec(dbg_spez)
        _sys.modules[dbg_spez.name] = dbg_mod
        assert dbg_spez.loader is not None
        dbg_spez.loader.exec_module(dbg_mod)
        uebersetzer = dbg_mod.DebugUebersetzer()
        hat_uebersetzer = True
    except Exception:
        hat_uebersetzer = False
        uebersetzer = None
    for zeile in fundzeilen:
        if hat_uebersetzer:
            uebers = uebersetzer.uebersetze(zeile)
            datei, zeilen_nr = uebersetzer.datei_und_zeile(zeile)
            ziel_datei = datei if datei != "godot" else "godot"
            ziel_zeile = zeilen_nr if zeilen_nr != 0 else 0
            log_ref = lauf_log.referenz("godot_letzter_lauf", log_zeile_fuer(zeile))
            fehler(uebers.code, ziel_datei, ziel_zeile, "%s | Log: %s" % (uebers.text, log_ref))
        else:
            if "Parse Error" in zeile or "SCRIPT ERROR" in zeile:
                fehler("E016", "godot", 0, zeile)
            elif any(m in zeile for m in ("Could not find", "not declared", "Cannot infer", "Could not resolve", "Could not parse", "Attempt to open script", "unknown")):
                fehler("E017", "godot", 0, zeile)
            else:
                fehler("E018", "godot", 0, zeile)
