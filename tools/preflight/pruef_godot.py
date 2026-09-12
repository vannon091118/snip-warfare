# -*- coding: utf-8 -*-
"""Prüfkategorie godot (E016, E017, E018): Headless-Lauf, Fehler-Zeilen
und Lauf-Log, granular in eigener Verantwortung."""

import os
import shutil
import subprocess
from pathlib import Path

from .kern import (PROJEKT_STAMM, GODOT_FEHLER_MUSTER, GODOT_EXTERN_FALLBACK,
                   GODOT_LOKAL_KANDIDATEN, fehler)


def _log_zeile_fuer(zeile: str) -> int:
    """Findet die Zeilennummer einer Godot-Zeile im Log des letzten Laufs."""
    try:
        from .kern import _lade_lauf_log
        lauf_log = _lade_lauf_log()
        for index, roh in enumerate(lauf_log.lese_alle("godot_letzter_lauf"), start=1):
            if roh.strip() == zeile.strip():
                return index
    except Exception:
        pass
    return 1


def _aufloese_godot_befehl(befehl_arg: str):
    umgebung = os.environ.get("GODOT_BIN", "").strip()
    if umgebung != "":
        return umgebung
    if befehl_arg != "godot":
        return befehl_arg
    for kandidat in GODOT_LOKAL_KANDIDATEN:
        voller = PROJEKT_STAMM / kandidat
        if voller.is_file():
            return str(voller)
    if shutil.which("godot") is not None:
        return "godot"
    if GODOT_EXTERN_FALLBACK.is_file():
        return str(GODOT_EXTERN_FALLBACK)
    return None


def godot_lauf(godot_befehl: str) -> None:
    aufgeloest = _aufloese_godot_befehl(godot_befehl)
    if aufgeloest is None:
        fehler("E018", "godot", 0,
               "Godot nicht gefunden (fail-closed). Setze GODOT_BIN, --godot-befehl, lege tools/godot/godot_console.exe ab oder nutze Godot im PATH. Relativer Referenzpfad extern: %s" % GODOT_EXTERN_FALLBACK)
        return
    # Fail-closed: Wenn expliziter Pfad angegeben wurde, muss er existieren oder im PATH sein.
    if aufgeloest != "godot" and not Path(aufgeloest).is_file() and shutil.which(aufgeloest) is None:
        fehler("E018", "godot", 0,
               "Godot wurde als '%s' nicht gefunden; --godot-befehl oder GODOT_BIN pruefen (fail-closed). Relativer Fallback: %s" % (aufgeloest, GODOT_EXTERN_FALLBACK))
        return
    if shutil.which(aufgeloest) is None and not Path(aufgeloest).is_file():
        fehler("E018", "godot", 0,
               "Godot wurde als '%s' nicht gefunden; --godot-befehl verwenden (fail-closed)" % aufgeloest)
        return
    befehl = [aufgeloest, "--headless", "--path", str(PROJEKT_STAMM), "--quit-after", "120"]
    # Fail-closed Kill: Timeout 300s, danach Prozess hart beenden. Kein stilles Gruen.
    try:
        ergebnis = subprocess.run(befehl, capture_output=True, text=True,
                                  encoding="utf-8", errors="replace", timeout=300)
    except subprocess.TimeoutExpired:
        # subprocess.run killt den Kindprozess bei Timeout bereits; zusaetzlich
        # haengende Godot Prozesse suchen und beenden.
        try:
            subprocess.run(["taskkill", "/F", "/IM", "godot_console.exe"], capture_output=True, timeout=5)
        except Exception:
            pass
        fehler("E018", "godot", 0, "Godot-Lauf hat das Zeitlimit von 300 Sekunden ueberschritten (fail-closed, Prozess gekillt)")
        return
    ausgabe = (ergebnis.stdout or "") + (ergebnis.stderr or "")
    roh_zeilen = ausgabe.splitlines()
    # Lauf-Log: Der rohe Headless-Stream landet überschrieben in
    # tools/logs/godot_letzter_lauf.log — immer nur der letzte Lauf gilt.
    try:
        from .kern import _lade_lauf_log
        lauf_log = _lade_lauf_log()
        lauf_log.schreibe("godot_letzter_lauf",
                          "Godot Headless-Rohlauf (%s)" % aufgeloest,
                          roh_zeilen)
    except Exception as log_fehler:
        fehler("E018", "godot", 0,
               "Lauf-Log nicht schreibbar (fail-closed): %s" % log_fehler)
        return
    fundzeilen = []
    for zeile in roh_zeilen:
        zugehoerig = zeile.strip()
        if any(muster in zugehoerig for muster in GODOT_FEHLER_MUSTER):
            if zugehoerig not in fundzeilen:
                fundzeilen.append(zugehoerig)
    # Debugging Übersetzer: Jede Godot Zeile wird in E016/E017/E018 mit Hinweis übersetzt.
    try:
        import importlib.util as _ilu_d
        import sys as _sys_d
        _dbg_pfad = PROJEKT_STAMM / "tools" / "debug_uebersetzer.py"
        _dbg_spez = _ilu_d.spec_from_file_location("_debug_uebersetzer_lauf", str(_dbg_pfad))
        _dbg_mod = _ilu_d.module_from_spec(_dbg_spez)
        _sys_d.modules[_dbg_spez.name] = _dbg_mod
        assert _dbg_spez.loader is not None
        _dbg_spez.loader.exec_module(_dbg_mod)
        uebersetzer = _dbg_mod.DebugUebersetzer()
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
            log_ref = lauf_log.referenz("godot_letzter_lauf", _log_zeile_fuer(zeile))
            fehler(uebers.code, ziel_datei, ziel_zeile,
                   "%s | Log: %s" % (uebers.text, log_ref))
        else:
            if "Parse Error" in zeile or "SCRIPT ERROR" in zeile:
                fehler("E016", "godot", 0, zeile)
            elif any(muster in zeile for muster in ("Could not find", "not declared",
                                                    "Cannot infer", "Could not resolve",
                                                    "Could not parse", "Attempt to open script",
                                                    "unknown")):
                fehler("E017", "godot", 0, zeile)
            else:
                fehler("E018", "godot", 0, zeile)
